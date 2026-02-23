import { Server as SocketIOServer, Socket } from 'socket.io';
import jwt from 'jsonwebtoken';
import { env } from '../../config/env';
import { redis } from '../../config/redis';
import { prisma } from '../../config/database';
import * as ludoService from './ludo.service';

// ─── Types ────────────────────────────────────────────────────────────────────

interface AuthenticatedSocket extends Socket {
  userId?: string;
  username?: string;
}

// ─── Reconnect Timers ─────────────────────────────────────────────────────────

const RECONNECT_TIMEOUT_MS = 60_000; // 60 s
const reconnectTimers = new Map<string, NodeJS.Timeout>(); // key: `${matchId}:${userId}`

const clearReconnectTimer = (matchId: string, userId: string): void => {
  const key = `${matchId}:${userId}`;
  const t = reconnectTimers.get(key);
  if (t) {
    clearTimeout(t);
    reconnectTimers.delete(key);
  }
};

const startReconnectTimer = (matchId: string, userId: string): void => {
  clearReconnectTimer(matchId, userId);
  const key = `${matchId}:${userId}`;
  const timer = setTimeout(async () => {
    reconnectTimers.delete(key);
    // Player did not reconnect in time — treat as forfeit/timeout
    await ludoService.handleTimeout(matchId, userId).catch((err) =>
      console.error(`Reconnect timeout error [match=${matchId}, user=${userId}]:`, err),
    );
    await redis.del(`ludo:${matchId}:disconnect:${userId}`);
  }, RECONNECT_TIMEOUT_MS);
  reconnectTimers.set(key, timer);
};

// ─── Gateway Setup ────────────────────────────────────────────────────────────

export const setupLudoGateway = (io: SocketIOServer): void => {
  const ludo = io.of('/ludo');

  // ── JWT Authentication Middleware ─────────────────────────────────────────

  ludo.use(async (socket: AuthenticatedSocket, next) => {
    try {
      const token =
        (socket.handshake.auth?.token as string | undefined) ||
        (socket.handshake.headers?.authorization as string | undefined)?.replace('Bearer ', '');

      if (!token) return next(new Error('Authentication required'));

      const decoded = jwt.verify(token, env.JWT_SECRET) as { userId: string; role: string };

      const user = await prisma.user.findUnique({
        where: { id: decoded.userId },
        select: { id: true, username: true, isBanned: true },
      });

      if (!user) return next(new Error('User not found'));
      if (user.isBanned) return next(new Error('Account banned'));

      socket.userId = user.id;
      socket.username = user.username;
      next();
    } catch {
      next(new Error('Invalid token'));
    }
  });

  // ── Connection Handler ────────────────────────────────────────────────────

  ludo.on('connection', (socket: AuthenticatedSocket) => {
    const userId = socket.userId!;
    console.log(`[Ludo] Socket connected: ${socket.id} (user: ${userId})`);

    // ── join_match ────────────────────────────────────────────────────────

    socket.on('join_match', async (data: { matchId: string }, callback?: (r: unknown) => void) => {
      try {
        const { matchId } = data;

        // Verify the user is a participant
        const player = await prisma.ludoMatchPlayer.findUnique({
          where: { matchId_userId: { matchId, userId } },
        });
        if (!player) {
          const err = { success: false, message: 'Not in this match' };
          if (callback) callback(err);
          return;
        }

        socket.join(`match:${matchId}`);

        // Cancel any pending reconnect timer
        clearReconnectTimer(matchId, userId);
        await redis.del(`ludo:${matchId}:disconnect:${userId}`);

        // Send current game state to the joining socket
        const state = await ludoService.getMatchState(matchId);
        socket.emit('match_state', state);

        if (callback) callback({ success: true });
      } catch (err) {
        console.error('[Ludo] join_match error:', err);
        if (callback) callback({ success: false, message: 'Internal error' });
      }
    });

    // ── roll_dice ─────────────────────────────────────────────────────────

    socket.on('roll_dice', async (data: { matchId: string }, callback?: (r: unknown) => void) => {
      try {
        const { matchId } = data;

        const result = await ludoService.rollDiceForMatch(matchId, userId);

        // Emit dice result to the rolling player
        socket.emit('dice_result', {
          diceValue: result.diceValue,
          forfeit: result.forfeit,
        });

        if (!result.forfeit) {
          // Emit valid moves to the rolling player only (anti-cheat)
          socket.emit('valid_moves', { moves: result.validMoves });
        }

        if (callback) callback({ success: true, diceValue: result.diceValue });
      } catch (err) {
        const msg = err instanceof Error ? err.message : 'Internal error';
        console.error('[Ludo] roll_dice error:', msg);
        socket.emit('error', { message: msg });
        if (callback) callback({ success: false, message: msg });
      }
    });

    // ── move_piece ────────────────────────────────────────────────────────

    socket.on(
      'move_piece',
      async (data: { matchId: string; pieceId: string }, callback?: (r: unknown) => void) => {
        try {
          const { matchId, pieceId } = data;

          // Retrieve the stored dice value (set by roll_dice)
          const storedDice = await redis.get(`ludo:${matchId}:dice:${userId}`);
          if (!storedDice) {
            const err = { success: false, message: 'No pending dice roll — roll first' };
            if (callback) callback(err);
            return;
          }

          const diceValue = parseInt(storedDice, 10);
          await redis.del(`ludo:${matchId}:dice:${userId}`);

          const result = await ludoService.executeMove(matchId, userId, pieceId, diceValue);

          if (callback) callback({ success: true, result });
        } catch (err) {
          const msg = err instanceof Error ? err.message : 'Internal error';
          console.error('[Ludo] move_piece error:', msg);
          socket.emit('error', { message: msg });
          if (callback) callback({ success: false, message: msg });
        }
      },
    );

    // ── emoji_reaction ────────────────────────────────────────────────────

    socket.on(
      'emoji_reaction',
      async (data: { matchId: string; emoji: string }, callback?: (r: unknown) => void) => {
        try {
          const { matchId, emoji } = data;

          // Verify the user is in this match
          const player = await prisma.ludoMatchPlayer.findUnique({
            where: { matchId_userId: { matchId, userId } },
          });
          if (!player) return;

          // Broadcast to everyone in the room
          ludo.to(`match:${matchId}`).emit('emoji_reaction', {
            userId,
            username: socket.username,
            emoji,
          });

          if (callback) callback({ success: true });
        } catch (err) {
          console.error('[Ludo] emoji_reaction error:', err);
        }
      },
    );

    // ── disconnect ────────────────────────────────────────────────────────

    socket.on('disconnect', async () => {
      console.log(`[Ludo] Socket disconnected: ${socket.id} (user: ${userId})`);

      // Find active matches for this user
      try {
        const activePlayers = await prisma.ludoMatchPlayer.findMany({
          where: {
            userId,
            match: { status: 'IN_PROGRESS' },
          },
          select: { matchId: true },
        });

        for (const { matchId } of activePlayers) {
          // Mark disconnect in Redis; TTL = reconnect window + 10 s buffer
          const disconnectTtlS = Math.ceil(RECONNECT_TIMEOUT_MS / 1000) + 10;
          await redis.setex(`ludo:${matchId}:disconnect:${userId}`, disconnectTtlS, Date.now().toString());

          // Notify other players
          ludo.to(`match:${matchId}`).emit('player_disconnected', {
            userId,
            reconnectWindowSeconds: RECONNECT_TIMEOUT_MS / 1000,
          });

          // Start reconnect timer
          startReconnectTimer(matchId, userId);
        }
      } catch (err) {
        console.error('[Ludo] disconnect cleanup error:', err);
      }
    });
  });
};
