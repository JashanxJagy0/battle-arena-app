import crypto from 'crypto';
import { Prisma, LudoGameMode, LudoColor, LudoMoveType } from '@prisma/client';
import { prisma } from '../../config/database';
import { redis } from '../../config/redis';
import { AppError } from '../../middleware/error_handler.middleware';
import { getIo } from '../../websockets/socket_manager';
import {
  rollDice,
  initPieces,
  getValidMoves,
  getNextTurnPlayer,
  classifyMoveType,
  toAbsolutePosition,
  PieceState,
  ValidMove,
  HOME_POSITION,
  HOME_COLUMN_START,
  COLOR_ORDER,
} from './ludo_engine';
import type { CreateMatchInput, GetLobbyInput, MyMatchesInput, DisputeInput } from './ludo.validation';

// ─── Constants ────────────────────────────────────────────────────────────────

const PLATFORM_FEE_RATE = 0.1; // 10 % of prize pool
const TURN_TIMEOUT_MS = 30_000;   // 30 s
const READY_TTL_S = 60;           // Redis TTL for "player ready" keys

const MAX_PLAYERS_MAP: Record<LudoGameMode, number> = {
  ONE_V_ONE: 2,
  TWO_V_TWO: 4,
  FOUR_PLAYER: 4,
};

const COLOR_SEQUENCE: LudoColor[] = ['RED', 'GREEN', 'YELLOW', 'BLUE'];

// ─── Turn Timer ───────────────────────────────────────────────────────────────

const turnTimers = new Map<string, NodeJS.Timeout>();

export const clearTurnTimer = (matchId: string): void => {
  const t = turnTimers.get(matchId);
  if (t) {
    clearTimeout(t);
    turnTimers.delete(matchId);
  }
};

export const startTurnTimer = (matchId: string, userId: string): void => {
  clearTurnTimer(matchId);
  const timer = setTimeout(() => {
    handleTimeout(matchId, userId).catch((err) =>
      console.error(`Turn timer error [match=${matchId}]:`, err),
    );
    turnTimers.delete(matchId);
  }, TURN_TIMEOUT_MS);
  turnTimers.set(matchId, timer);
};

// ─── Helpers ──────────────────────────────────────────────────────────────────

const generateMatchCode = (): string =>
  crypto.randomBytes(3).toString('hex').toUpperCase();

const emitToMatch = (matchId: string, event: string, data: unknown): void => {
  try {
    getIo().of('/ludo').to(`match:${matchId}`).emit(event, data);
  } catch {
    // io may not be initialised in unit-test environments — swallow silently
  }
};

// ─── Service Functions ────────────────────────────────────────────────────────

export const getLobby = async (filters: GetLobbyInput) => {
  const { gameMode, entryFeeMin, entryFeeMax } = filters;

  const where: Prisma.LudoMatchWhereInput = { status: 'WAITING' };
  if (gameMode) where.gameMode = gameMode;
  if (entryFeeMin !== undefined || entryFeeMax !== undefined) {
    where.entryFee = {};
    if (entryFeeMin !== undefined)
      (where.entryFee as Prisma.DecimalFilter).gte = new Prisma.Decimal(entryFeeMin);
    if (entryFeeMax !== undefined)
      (where.entryFee as Prisma.DecimalFilter).lte = new Prisma.Decimal(entryFeeMax);
  }

  return prisma.ludoMatch.findMany({
    where,
    include: {
      players: {
        select: { userId: true, color: true, user: { select: { username: true, avatarUrl: true } } },
      },
    },
    orderBy: { createdAt: 'desc' },
  });
};

export const createMatch = async (userId: string, data: CreateMatchInput) => {
  const { gameMode, entryFee } = data;
  const maxPlayers = MAX_PLAYERS_MAP[gameMode];
  const entryFeeDecimal = new Prisma.Decimal(entryFee);
  const prizePool = entryFeeDecimal.mul(maxPlayers);
  const platformFee = prizePool.mul(PLATFORM_FEE_RATE);

  return prisma.$transaction(async (tx) => {
    // Validate balance
    const wallet = await tx.wallet.findUnique({ where: { userId } });
    if (!wallet) throw new AppError('Wallet not found', 404);

    const available = wallet.mainBalance.add(wallet.bonusBalance);
    if (available.lt(entryFeeDecimal))
      throw new AppError('Insufficient balance', 400);

    // Generate unique match code
    let matchCode: string | undefined;
    let attempts = 0;
    do {
      matchCode = generateMatchCode();
      const existing = await tx.ludoMatch.findUnique({ where: { matchCode } });
      if (!existing) break;
      attempts++;
    } while (attempts < 5);

    if (!matchCode) throw new AppError('Could not generate a unique match code, please retry', 500);

    // Create match
    const match = await tx.ludoMatch.create({
      data: {
        matchCode,
        gameMode,
        entryFee: entryFeeDecimal,
        prizePool,
        platformFee,
        maxPlayers,
        currentPlayers: 1,
        status: 'WAITING',
      },
    });

    // Assign first available color (always RED for first player)
    const color: LudoColor = COLOR_SEQUENCE[0];

    // Create player record
    await tx.ludoMatchPlayer.create({
      data: {
        matchId: match.id,
        userId,
        color,
        piecesState: initPieces() as unknown as Prisma.InputJsonValue,
      },
    });

    // Deduct entry fee → lock in lockedBalance
    const deductFrom = wallet.mainBalance.gte(entryFeeDecimal) ? 'main' : 'bonus';
    await tx.wallet.update({
      where: { userId },
      data:
        deductFrom === 'main'
          ? {
              mainBalance: { decrement: entryFeeDecimal },
              lockedBalance: { increment: entryFeeDecimal },
              totalWagered: { increment: entryFeeDecimal },
            }
          : {
              bonusBalance: { decrement: entryFeeDecimal },
              lockedBalance: { increment: entryFeeDecimal },
              totalWagered: { increment: entryFeeDecimal },
            },
    });

    // Create wager record
    await tx.wager.create({
      data: {
        userId,
        gameType: 'LUDO',
        referenceId: match.id,
        entryAmount: entryFeeDecimal,
        potentialWin: prizePool.sub(platformFee),
        status: 'ACTIVE',
      },
    });

    return match;
  });
};

export const joinMatch = async (userId: string, matchId: string) => {
  return prisma.$transaction(async (tx) => {
    const match = await tx.ludoMatch.findUnique({
      where: { id: matchId },
      include: { players: true },
    });

    if (!match) throw new AppError('Match not found', 404);
    if (match.status !== 'WAITING') throw new AppError('Match is not open for joining', 400);
    if (match.currentPlayers >= match.maxPlayers) throw new AppError('Match is full', 400);

    const alreadyIn = match.players.some((p) => p.userId === userId);
    if (alreadyIn) throw new AppError('Already in this match', 400);

    // Validate balance
    const wallet = await tx.wallet.findUnique({ where: { userId } });
    if (!wallet) throw new AppError('Wallet not found', 404);

    const available = wallet.mainBalance.add(wallet.bonusBalance);
    if (available.lt(match.entryFee)) throw new AppError('Insufficient balance', 400);

    // Assign next available color
    const usedColors = match.players.map((p) => p.color);
    const color = COLOR_SEQUENCE.find((c) => !usedColors.includes(c));
    if (!color) throw new AppError('No color available', 400);

    // Create player record
    await tx.ludoMatchPlayer.create({
      data: {
        matchId,
        userId,
        color,
        piecesState: initPieces() as unknown as Prisma.InputJsonValue,
      },
    });

    // Deduct entry fee
    const deductFrom = wallet.mainBalance.gte(match.entryFee) ? 'main' : 'bonus';
    await tx.wallet.update({
      where: { userId },
      data:
        deductFrom === 'main'
          ? {
              mainBalance: { decrement: match.entryFee },
              lockedBalance: { increment: match.entryFee },
              totalWagered: { increment: match.entryFee },
            }
          : {
              bonusBalance: { decrement: match.entryFee },
              lockedBalance: { increment: match.entryFee },
              totalWagered: { increment: match.entryFee },
            },
    });

    // Create wager
    const prizePool = match.prizePool;
    const platformFee = match.platformFee;
    await tx.wager.create({
      data: {
        userId,
        gameType: 'LUDO',
        referenceId: matchId,
        entryAmount: match.entryFee,
        potentialWin: prizePool.sub(platformFee),
        status: 'ACTIVE',
      },
    });

    // Increment player count; if full → move to READY
    const newCount = match.currentPlayers + 1;
    const newStatus = newCount >= match.maxPlayers ? 'READY' : 'WAITING';

    const updatedMatch = await tx.ludoMatch.update({
      where: { id: matchId },
      data: { currentPlayers: newCount, status: newStatus },
      include: { players: true },
    });

    if (newStatus === 'READY') {
      emitToMatch(matchId, 'match_ready', { matchId, players: updatedMatch.players });
    }

    return updatedMatch;
  });
};

export const playerReady = async (userId: string, matchId: string) => {
  const match = await prisma.ludoMatch.findUnique({
    where: { id: matchId },
    include: { players: true },
  });

  if (!match) throw new AppError('Match not found', 404);
  if (match.status !== 'READY')
    throw new AppError('Match is not in the ready phase', 400);

  const player = match.players.find((p) => p.userId === userId);
  if (!player) throw new AppError('Not in this match', 404);

  // Mark player ready in Redis
  const readyKey = `ludo:${matchId}:ready:${userId}`;
  await redis.setex(readyKey, READY_TTL_S, '1');

  // Check if all players are ready
  const readyChecks = await Promise.all(
    match.players.map((p) => redis.get(`ludo:${matchId}:ready:${p.userId}`)),
  );
  const allReady = readyChecks.every((v) => v === '1');

  if (!allReady) {
    return { allReady: false };
  }

  // All ready → start game
  const firstPlayer = match.players.find((p) => p.color === COLOR_ORDER[0]) ?? match.players[0];
  const turnDeadline = new Date(Date.now() + TURN_TIMEOUT_MS);

  await prisma.ludoMatch.update({
    where: { id: matchId },
    data: {
      status: 'IN_PROGRESS',
      turnUserId: firstPlayer.userId,
      turnDeadline,
      gameStartedAt: new Date(),
    },
  });

  emitToMatch(matchId, 'game_started', {
    matchId,
    turnUserId: firstPlayer.userId,
    turnDeadline: turnDeadline.toISOString(),
  });

  startTurnTimer(matchId, firstPlayer.userId);

  return { allReady: true, turnUserId: firstPlayer.userId };
};

export const leaveMatch = async (userId: string, matchId: string) => {
  return prisma.$transaction(async (tx) => {
    const match = await tx.ludoMatch.findUnique({
      where: { id: matchId },
      include: { players: true },
    });

    if (!match) throw new AppError('Match not found', 404);
    if (match.status === 'IN_PROGRESS' || match.status === 'COMPLETED')
      throw new AppError('Cannot leave a match that is already in progress or completed', 400);

    const player = match.players.find((p) => p.userId === userId);
    if (!player) throw new AppError('Not in this match', 404);

    // Remove player
    await tx.ludoMatchPlayer.delete({
      where: { matchId_userId: { matchId, userId } },
    });

    // Refund entry fee
    await tx.wallet.update({
      where: { userId },
      data: {
        lockedBalance: { decrement: match.entryFee },
        mainBalance: { increment: match.entryFee },
      },
    });

    // Cancel wager
    await tx.wager.updateMany({
      where: { userId, gameType: 'LUDO', referenceId: matchId, status: 'ACTIVE' },
      data: { status: 'CANCELLED', settledAt: new Date() },
    });

    const remaining = match.players.length - 1;
    if (remaining === 0) {
      // No players left — cancel match
      await tx.ludoMatch.update({
        where: { id: matchId },
        data: { status: 'CANCELLED' },
      });
    } else {
      await tx.ludoMatch.update({
        where: { id: matchId },
        data: { currentPlayers: remaining, status: 'WAITING' },
      });
    }

    // Clean up Redis
    await redis.del(`ludo:${matchId}:ready:${userId}`);

    return { left: true };
  });
};

export const getMatch = async (matchId: string) => {
  const match = await prisma.ludoMatch.findUnique({
    where: { id: matchId },
    include: {
      players: {
        include: { user: { select: { username: true, avatarUrl: true } } },
      },
    },
  });
  if (!match) throw new AppError('Match not found', 404);
  return match;
};

export const getMatchState = async (matchId: string) => {
  const match = await prisma.ludoMatch.findUnique({
    where: { id: matchId },
    include: {
      players: {
        include: { user: { select: { username: true, avatarUrl: true } } },
      },
    },
  });
  if (!match) throw new AppError('Match not found', 404);

  return {
    matchId: match.id,
    status: match.status,
    turnUserId: match.turnUserId,
    turnDeadline: match.turnDeadline,
    turnNumber: match.turnNumber,
    players: match.players.map((p) => ({
      userId: p.userId,
      username: p.user.username,
      avatarUrl: p.user.avatarUrl,
      color: p.color,
      pieces: (p.piecesState as unknown as PieceState[]) ?? initPieces(),
      piecesHome: p.piecesHome,
      isEliminated: p.isEliminated,
      finalRank: p.finalRank,
    })),
  };
};

export const getMyMatches = async (userId: string, query: MyMatchesInput) => {
  const { page, limit } = query;
  const skip = (page - 1) * limit;

  const [total, matches] = await Promise.all([
    prisma.ludoMatch.count({
      where: { players: { some: { userId } } },
    }),
    prisma.ludoMatch.findMany({
      where: { players: { some: { userId } } },
      include: {
        players: {
          select: { userId: true, color: true, piecesHome: true, finalRank: true },
        },
      },
      orderBy: { createdAt: 'desc' },
      skip,
      take: limit,
    }),
  ]);

  return {
    total,
    page,
    limit,
    totalPages: Math.ceil(total / limit),
    matches,
  };
};

export const createDispute = async (userId: string, matchId: string, data: DisputeInput) => {
  const match = await prisma.ludoMatch.findUnique({ where: { id: matchId } });
  if (!match) throw new AppError('Match not found', 404);

  const player = await prisma.ludoMatchPlayer.findUnique({
    where: { matchId_userId: { matchId, userId } },
  });
  if (!player) throw new AppError('Not in this match', 404);

  const dispute = await prisma.dispute.create({
    data: {
      userId,
      gameType: 'LUDO',
      referenceId: matchId,
      reason: data.reason,
      evidenceUrls: data.evidenceUrls ?? [],
      status: 'OPEN',
    },
  });

  // Optionally flag the match as DISPUTED
  await prisma.ludoMatch.update({
    where: { id: matchId },
    data: { status: 'DISPUTED' },
  });

  return dispute;
};

// ─── Execute Move ─────────────────────────────────────────────────────────────

export const executeMove = async (
  matchId: string,
  userId: string,
  pieceId: string,
  diceValue: number,
): Promise<{
  isKill: boolean;
  killedUserId?: string;
  killedPieceId?: string;
  isHome: boolean;
  isWin: boolean;
  nextUserId: string | null;
}> => {
  const match = await prisma.ludoMatch.findUnique({
    where: { id: matchId },
    include: { players: true },
  });

  if (!match) throw new AppError('Match not found', 404);
  if (match.status !== 'IN_PROGRESS') throw new AppError('Match is not in progress', 400);
  if (match.turnUserId !== userId) throw new AppError('Not your turn', 400);

  const player = match.players.find((p) => p.userId === userId);
  if (!player) throw new AppError('Player not found in match', 404);

  const myPieces: PieceState[] = (player.piecesState as unknown as PieceState[]) ?? initPieces();

  // Build allPlayers structure for engine
  const allPlayers = match.players.map((p) => ({
    userId: p.userId,
    color: p.color,
    pieces: (p.piecesState as unknown as PieceState[]) ?? initPieces(),
  }));

  const validMoves = getValidMoves(diceValue, player.color, userId, myPieces, allPlayers);
  const move: ValidMove | undefined = validMoves.find((m) => m.pieceId === pieceId);
  if (!move) throw new AppError('Invalid move', 400);

  // Apply move to piece
  const piece = myPieces.find((p) => p.id === pieceId);
  if (!piece) throw new AppError('Piece not found', 404);
  piece.position = move.toPosition;

  const isKill = move.isKill;
  const killedUserId = move.killedUserId;
  const killedPieceId = move.killedPieceId;
  const isHome = move.toPosition === HOME_POSITION;

  // Handle kill — send killed piece back to yard
  let killedPlayerUpdatedPieces: PieceState[] | null = null;
  let killedPlayerRecord: (typeof match.players)[0] | null = null;

  if (isKill && killedUserId && killedPieceId) {
    killedPlayerRecord = match.players.find((p) => p.userId === killedUserId) ?? null;
    if (killedPlayerRecord) {
      killedPlayerUpdatedPieces =
        (killedPlayerRecord.piecesState as unknown as PieceState[]) ?? initPieces();
      const kPiece = killedPlayerUpdatedPieces.find((p) => p.id === killedPieceId);
      if (kPiece) kPiece.position = -1; // return to yard
    }
  }

  const newPiecesHome = myPieces.filter((p) => p.position === HOME_POSITION).length;
  const isWin = newPiecesHome === 4;

  // Determine next turn
  let nextUserId: string | null = null;
  if (!isWin) {
    if (diceValue === 6) {
      nextUserId = userId; // another roll for rolling a 6
    } else {
      const next = getNextTurnPlayer(
        player.color,
        match.players.map((p) => ({
          userId: p.userId,
          color: p.color,
          isEliminated: p.isEliminated,
        })),
      );
      nextUserId = next?.userId ?? null;
    }
  }

  const turnDeadline = nextUserId ? new Date(Date.now() + TURN_TIMEOUT_MS) : null;

  const moveTypeName = classifyMoveType(
    move.toPosition,
    isKill,
    false,
    player.color,
  ) as LudoMoveType;

  // Persist atomically
  await prisma.$transaction(async (tx) => {
    // Update moving player's pieces
    await tx.ludoMatchPlayer.update({
      where: { matchId_userId: { matchId, userId } },
      data: {
        piecesState: myPieces as unknown as Prisma.InputJsonValue,
        piecesHome: newPiecesHome,
      },
    });

    // Update killed player's pieces
    if (killedPlayerRecord && killedPlayerUpdatedPieces) {
      await tx.ludoMatchPlayer.update({
        where: { matchId_userId: { matchId, userId: killedPlayerRecord.userId } },
        data: { piecesState: killedPlayerUpdatedPieces as unknown as Prisma.InputJsonValue },
      });
    }

    // Record move
    await tx.ludoMove.create({
      data: {
        matchId,
        userId,
        turnNumber: match.turnNumber + 1,
        diceValue,
        pieceId,
        fromPosition: move.fromPosition,
        toPosition: move.toPosition,
        isKill,
        killedUserId: killedUserId ?? null,
        killedPieceId: killedPieceId ?? null,
        isHomeEntry: move.isHomeEntry,
        moveType: moveTypeName,
      },
    });

    // Update match state
    await tx.ludoMatch.update({
      where: { id: matchId },
      data: {
        turnUserId: isWin ? null : nextUserId,
        turnNumber: { increment: 1 },
        turnDeadline,
        status: isWin ? 'COMPLETED' : 'IN_PROGRESS',
        winnerId: isWin ? userId : undefined,
        gameEndedAt: isWin ? new Date() : undefined,
      },
    });
  });

  // Emit events
  if (isKill) {
    emitToMatch(matchId, 'piece_killed', { byUserId: userId, killedUserId, killedPieceId });
  }
  if (isHome) {
    emitToMatch(matchId, 'piece_home', { userId, pieceId });
  }

  const updatedState = await getMatchState(matchId);
  emitToMatch(matchId, 'match_update', {
    state: updatedState,
    lastMove: { userId, pieceId, diceValue, from: move.fromPosition, to: move.toPosition },
  });

  if (isWin) {
    await endGame(matchId, userId);
  } else if (nextUserId) {
    startTurnTimer(matchId, nextUserId);
    await redis.setex(
      `ludo:${matchId}:turn_deadline`,
      35,
      JSON.stringify({ userId: nextUserId, deadline: turnDeadline?.toISOString() }),
    );
  }

  return { isKill, killedUserId, killedPieceId, isHome, isWin, nextUserId };
};

// ─── Handle Timeout ───────────────────────────────────────────────────────────

export const handleTimeout = async (matchId: string, userId: string): Promise<void> => {
  const match = await prisma.ludoMatch.findUnique({
    where: { id: matchId },
    include: { players: true },
  });

  if (!match || match.status !== 'IN_PROGRESS') return;
  if (match.turnUserId !== userId) return; // turn already advanced

  const player = match.players.find((p) => p.userId === userId);
  if (!player) return;

  // Increment timeout counter in Redis
  const timeoutKey = `ludo:${matchId}:timeouts:${userId}`;
  const count = await redis.incr(timeoutKey);
  await redis.expire(timeoutKey, 3_600);

  if (count >= 3) {
    // Auto-forfeit: eliminate the player
    await prisma.ludoMatchPlayer.update({
      where: { matchId_userId: { matchId, userId } },
      data: { isEliminated: true },
    });

    emitToMatch(matchId, 'player_eliminated', { userId, reason: 'timeout' });

    const remainingActive = match.players.filter(
      (p) => p.userId !== userId && !p.isEliminated,
    );

    if (remainingActive.length === 1) {
      await endGame(matchId, remainingActive[0].userId);
      return;
    }

    await redis.del(timeoutKey);
  }

  // Advance to next player's turn (mark eliminated player so they are skipped)
  const nextPlayer = getNextTurnPlayer(
    player.color,
    match.players.map((p) => ({
      userId: p.userId,
      color: p.color,
      isEliminated: p.userId === userId && count >= 3 ? true : p.isEliminated,
    })),
  );

  if (!nextPlayer) return;

  const turnDeadline = new Date(Date.now() + TURN_TIMEOUT_MS);
  await prisma.ludoMatch.update({
    where: { id: matchId },
    data: { turnUserId: nextPlayer.userId, turnDeadline, turnNumber: { increment: 1 } },
  });

  emitToMatch(matchId, 'turn_change', {
    userId: nextPlayer.userId,
    deadline: turnDeadline.toISOString(),
    reason: 'timeout',
  });

  startTurnTimer(matchId, nextPlayer.userId);
};

// ─── End Game ─────────────────────────────────────────────────────────────────

export const endGame = async (matchId: string, winnerId: string): Promise<void> => {
  clearTurnTimer(matchId);

  const match = await prisma.ludoMatch.findUnique({
    where: { id: matchId },
    include: { players: true },
  });
  if (!match) return;

  const prizePool = Number(match.prizePool);
  const platformFee = Number(match.platformFee);
  const winnerPrize = prizePool - platformFee;

  await prisma.$transaction(async (tx) => {
    // Ensure match is marked completed
    await tx.ludoMatch.update({
      where: { id: matchId },
      data: { status: 'COMPLETED', winnerId, gameEndedAt: new Date() },
    });

    // Credit winner's winning balance and unlock their locked amount
    await tx.wallet.update({
      where: { userId: winnerId },
      data: {
        winningBalance: { increment: new Prisma.Decimal(winnerPrize) },
        lockedBalance: { decrement: match.entryFee },
        totalWon: { increment: new Prisma.Decimal(winnerPrize) },
      },
    });

    // Unlock losers' locked balance
    for (const p of match.players) {
      if (p.userId !== winnerId) {
        await tx.wallet.update({
          where: { userId: p.userId },
          data: { lockedBalance: { decrement: match.entryFee } },
        });
      }
    }

    // Update wagers — mark all LOST first, then override winner to WON
    await tx.wager.updateMany({
      where: { referenceId: matchId, gameType: 'LUDO' },
      data: { status: 'LOST', settledAt: new Date() },
    });
    await tx.wager.updateMany({
      where: { referenceId: matchId, gameType: 'LUDO', userId: winnerId },
      data: {
        status: 'WON',
        actualWin: new Prisma.Decimal(winnerPrize),
        netProfit: new Prisma.Decimal(winnerPrize - Number(match.entryFee)),
        settledAt: new Date(),
      },
    });

    // Update player stats
    await tx.user.update({
      where: { id: winnerId },
      data: { totalGamesPlayed: { increment: 1 }, totalWins: { increment: 1 } },
    });
    for (const p of match.players) {
      if (p.userId !== winnerId) {
        await tx.user.update({
          where: { id: p.userId },
          data: { totalGamesPlayed: { increment: 1 }, totalLosses: { increment: 1 } },
        });
      }
    }

    // Recalculate win rates
    for (const p of match.players) {
      const stats = await tx.user.findUnique({
        where: { id: p.userId },
        select: { totalWins: true, totalGamesPlayed: true },
      });
      if (stats && stats.totalGamesPlayed > 0) {
        await tx.user.update({
          where: { id: p.userId },
          data: { winRate: stats.totalWins / stats.totalGamesPlayed },
        });
      }
    }

    // Notifications
    await tx.notification.create({
      data: {
        userId: winnerId,
        title: 'You Won! 🏆',
        body: `Congratulations! You won the Ludo match and earned ₹${winnerPrize.toFixed(2)}!`,
        type: 'GAME_WON',
        referenceType: 'ludo_match',
        referenceId: matchId,
      },
    });
    for (const p of match.players) {
      if (p.userId !== winnerId) {
        await tx.notification.create({
          data: {
            userId: p.userId,
            title: 'Match Ended',
            body: 'The Ludo match has ended. Better luck next time!',
            type: 'GAME_LOST',
            referenceType: 'ludo_match',
            referenceId: matchId,
          },
        });
      }
    }
  });

  emitToMatch(matchId, 'game_ended', {
    winnerId,
    prizePool,
    winnerPrize,
    platformFee,
  });

  // Clean up Redis keys
  await Promise.all([
    redis.del(`ludo:${matchId}:consecutive_sixes`),
    redis.del(`ludo:${matchId}:turn_deadline`),
    ...match.players.flatMap((p) => [
      redis.del(`ludo:${matchId}:ready:${p.userId}`),
      redis.del(`ludo:${matchId}:timeouts:${p.userId}`),
      redis.del(`ludo:${matchId}:disconnect:${p.userId}`),
    ]),
  ]);
};

// ─── Roll Dice (with consecutive-6 forfeit logic) ─────────────────────────────

export const rollDiceForMatch = async (
  matchId: string,
  userId: string,
): Promise<{
  diceValue: number;
  validMoves: ValidMove[];
  forfeit: boolean;
}> => {
  const match = await prisma.ludoMatch.findUnique({
    where: { id: matchId },
    include: { players: true },
  });

  if (!match) throw new AppError('Match not found', 404);
  if (match.status !== 'IN_PROGRESS') throw new AppError('Match is not in progress', 400);
  if (match.turnUserId !== userId) throw new AppError('Not your turn', 400);

  const diceValue = rollDice();

  const sixesKey = `ludo:${matchId}:consecutive_sixes`;
  let forfeit = false;

  if (diceValue === 6) {
    const stored = await redis.get(sixesKey);
    const count = stored ? parseInt(stored, 10) + 1 : 1;

    if (count >= 3) {
      // Third consecutive 6 — forfeit turn
      forfeit = true;
      await redis.del(sixesKey);

      const player = match.players.find((p) => p.userId === userId)!;
      const next = getNextTurnPlayer(
        player.color,
        match.players.map((p) => ({
          userId: p.userId,
          color: p.color,
          isEliminated: p.isEliminated,
        })),
      );

      const turnDeadline = next ? new Date(Date.now() + TURN_TIMEOUT_MS) : null;

      await prisma.ludoMatch.update({
        where: { id: matchId },
        data: {
          turnUserId: next?.userId ?? null,
          turnDeadline,
          turnNumber: { increment: 1 },
        },
      });

      if (next) {
        emitToMatch(matchId, 'turn_change', {
          userId: next.userId,
          deadline: turnDeadline?.toISOString(),
          reason: 'three_sixes',
        });
        startTurnTimer(matchId, next.userId);
      }

      return { diceValue, validMoves: [], forfeit };
    }

    await redis.setex(sixesKey, 300, count.toString());
  } else {
    await redis.del(sixesKey);
  }

  // Store dice value in Redis so move_piece can validate it
  await redis.setex(`ludo:${matchId}:dice:${userId}`, 60, diceValue.toString());

  const player = match.players.find((p) => p.userId === userId)!;
  const myPieces: PieceState[] = (player.piecesState as unknown as PieceState[]) ?? initPieces();
  const allPlayers = match.players.map((p) => ({
    userId: p.userId,
    color: p.color,
    pieces: (p.piecesState as unknown as PieceState[]) ?? initPieces(),
  }));

  const validMoves = getValidMoves(diceValue, player.color, userId, myPieces, allPlayers);

  // If no valid moves and dice != 6, automatically pass the turn
  if (validMoves.length === 0 && diceValue !== 6) {
    const next = getNextTurnPlayer(
      player.color,
      match.players.map((p) => ({
        userId: p.userId,
        color: p.color,
        isEliminated: p.isEliminated,
      })),
    );

    const turnDeadline = next ? new Date(Date.now() + TURN_TIMEOUT_MS) : null;
    await prisma.$transaction(async (tx) => {
      await tx.ludoMatch.update({
        where: { id: matchId },
        data: { turnUserId: next?.userId ?? null, turnDeadline, turnNumber: { increment: 1 } },
      });
      await tx.ludoMove.create({
        data: {
          matchId,
          userId,
          turnNumber: match.turnNumber + 1,
          diceValue,
          pieceId: 'none',
          fromPosition: -1,
          toPosition: -1,
          isKill: false,
          isHomeEntry: false,
          moveType: LudoMoveType.PASS,
        },
      });
    });

    if (next) {
      emitToMatch(matchId, 'turn_change', {
        userId: next.userId,
        deadline: turnDeadline?.toISOString(),
        reason: 'no_valid_moves',
      });
      startTurnTimer(matchId, next.userId);
    }
  }

  return { diceValue, validMoves, forfeit };
};



