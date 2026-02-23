import {
  Prisma,
  TransactionType,
  TransactionStatus,
  TournamentStatus,
  BonusType,
  DisputeStatus,
  LudoMatchStatus,
} from '@prisma/client';
import { prisma } from '../../config/database';
import { AppError } from '../../middleware/error_handler.middleware';
import type {
  ListUsersQuery,
  UpdateUserInput,
  BanUserInput,
  CreditDebitInput,
  CreateTournamentAdminInput,
  UpdateTournamentAdminInput,
  SetRoomInput,
  PublishResultsInput,
  UpdateTournamentStatusInput,
  ListLudoMatchesQuery,
  ResolveLudoMatchInput,
  ListTransactionsQuery,
  RejectWithdrawalInput,
  CreateBonusScheduleInput,
  UpdateBonusScheduleInput,
  SendBulkBonusInput,
  CreatePromoCodeInput,
  ListDisputesQuery,
  ResolveDisputeInput,
  ListAuditLogsQuery,
  PeriodQuery,
} from './admin.validation';

// ─── Helpers ─────────────────────────────────────────────────────────────────

function getPeriodStart(period: string): Date {
  const now = new Date();
  switch (period) {
    case '30d':
      return new Date(now.getTime() - 30 * 86400000);
    case '90d':
      return new Date(now.getTime() - 90 * 86400000);
    case '1y':
      return new Date(now.getTime() - 365 * 86400000);
    default: // '7d'
      return new Date(now.getTime() - 7 * 86400000);
  }
}

async function createAuditLog(
  adminId: string,
  action: string,
  entityType: string,
  entityId: string,
  oldValue?: unknown,
  newValue?: unknown,
  ipAddress?: string
) {
  await prisma.auditLog.create({
    data: {
      adminId,
      action,
      entityType,
      entityId,
      oldValue: oldValue !== undefined ? (oldValue as Prisma.InputJsonValue) : undefined,
      newValue: newValue !== undefined ? (newValue as Prisma.InputJsonValue) : undefined,
      ipAddress,
    },
  });
}

// ─── Dashboard ───────────────────────────────────────────────────────────────

export const getDashboardStats = async () => {
  const oneDayAgo = new Date(Date.now() - 86400000);

  const [
    totalUsers,
    activeUsers,
    depositAgg,
    withdrawalAgg,
    platformFeeAgg,
    activeLudoMatches,
    activeTournaments,
    pendingWithdrawals,
    pendingDisputes,
  ] = await Promise.all([
    prisma.user.count(),
    prisma.user.count({ where: { lastLoginAt: { gte: oneDayAgo } } }),
    prisma.transaction.aggregate({
      where: { type: TransactionType.DEPOSIT, status: TransactionStatus.COMPLETED },
      _sum: { amount: true },
    }),
    prisma.transaction.aggregate({
      where: {
        type: TransactionType.WITHDRAWAL,
        status: { in: [TransactionStatus.COMPLETED, TransactionStatus.PROCESSING] },
      },
      _sum: { amount: true },
    }),
    Promise.all([
      prisma.ludoMatch.aggregate({ _sum: { platformFee: true } }),
      prisma.tournament.aggregate({ _sum: { platformFee: true } }),
    ]),
    prisma.ludoMatch.count({
      where: { status: { in: [LudoMatchStatus.IN_PROGRESS, LudoMatchStatus.WAITING] } },
    }),
    prisma.tournament.count({
      where: { status: { in: [TournamentStatus.LIVE, TournamentStatus.REGISTRATION_OPEN] } },
    }),
    prisma.transaction.count({
      where: { type: TransactionType.WITHDRAWAL, status: TransactionStatus.PENDING },
    }),
    prisma.dispute.count({ where: { status: DisputeStatus.OPEN } }),
  ]);

  const ludoPlatformFee = Number(platformFeeAgg[0]._sum.platformFee ?? 0);
  const tournamentPlatformFee = Number(platformFeeAgg[1]._sum.platformFee ?? 0);

  return {
    totalUsers,
    activeUsers,
    totalDeposits: Number(depositAgg._sum.amount ?? 0),
    totalWithdrawals: Number(withdrawalAgg._sum.amount ?? 0),
    totalRevenue: ludoPlatformFee + tournamentPlatformFee,
    activeLudoMatches,
    activeTournaments,
    pendingWithdrawals,
    pendingDisputes,
  };
};

export const getDashboardRevenue = async ({ period }: PeriodQuery) => {
  const periodStart = getPeriodStart(period);

  const [ludoFees, tournamentFees, transactions] = await Promise.all([
    prisma.ludoMatch.findMany({
      where: { gameEndedAt: { gte: periodStart }, status: LudoMatchStatus.COMPLETED },
      select: { gameEndedAt: true, platformFee: true },
    }),
    prisma.tournament.findMany({
      where: { updatedAt: { gte: periodStart }, status: TournamentStatus.COMPLETED },
      select: { updatedAt: true, platformFee: true },
    }),
    prisma.transaction.findMany({
      where: {
        type: TransactionType.DEPOSIT,
        status: TransactionStatus.COMPLETED,
        createdAt: { gte: periodStart },
      },
      select: { createdAt: true, amount: true },
    }),
  ]);

  // Build daily breakdown
  const dailyMap: Record<string, { date: string; ludoFees: number; tournamentFees: number; deposits: number }> = {};

  const getDay = (d: Date) => d.toISOString().split('T')[0];

  for (const m of ludoFees) {
    if (!m.gameEndedAt) continue;
    const day = getDay(m.gameEndedAt);
    if (!dailyMap[day]) dailyMap[day] = { date: day, ludoFees: 0, tournamentFees: 0, deposits: 0 };
    dailyMap[day].ludoFees += Number(m.platformFee);
  }
  for (const t of tournamentFees) {
    const day = getDay(t.updatedAt);
    if (!dailyMap[day]) dailyMap[day] = { date: day, ludoFees: 0, tournamentFees: 0, deposits: 0 };
    dailyMap[day].tournamentFees += Number(t.platformFee);
  }
  for (const tx of transactions) {
    const day = getDay(tx.createdAt);
    if (!dailyMap[day]) dailyMap[day] = { date: day, ludoFees: 0, tournamentFees: 0, deposits: 0 };
    dailyMap[day].deposits += Number(tx.amount);
  }

  const dailyRevenue = Object.values(dailyMap).sort((a, b) => a.date.localeCompare(b.date));
  const totalLudoFees = dailyRevenue.reduce((s, d) => s + d.ludoFees, 0);
  const totalTournamentFees = dailyRevenue.reduce((s, d) => s + d.tournamentFees, 0);

  return {
    period,
    dailyRevenue,
    totalPlatformFees: totalLudoFees + totalTournamentFees,
    totalLudoFees,
    totalTournamentFees,
  };
};

export const getDashboardCharts = async ({ period }: PeriodQuery) => {
  const periodStart = getPeriodStart(period);

  const [newUsers, deposits, ludoGames, tournamentGames] = await Promise.all([
    prisma.user.findMany({
      where: { createdAt: { gte: periodStart } },
      select: { createdAt: true },
    }),
    prisma.transaction.findMany({
      where: {
        type: TransactionType.DEPOSIT,
        status: TransactionStatus.COMPLETED,
        createdAt: { gte: periodStart },
      },
      select: { createdAt: true, amount: true },
    }),
    prisma.ludoMatch.findMany({
      where: { createdAt: { gte: periodStart } },
      select: { createdAt: true, platformFee: true },
    }),
    prisma.tournament.findMany({
      where: { createdAt: { gte: periodStart } },
      select: { createdAt: true, platformFee: true },
    }),
  ]);

  const getDay = (d: Date) => d.toISOString().split('T')[0];

  type DayData = { date: string; newUsers: number; deposits: number; games: number; revenue: number };
  const dailyMap: Record<string, DayData> = {};

  const ensure = (day: string) => {
    if (!dailyMap[day]) dailyMap[day] = { date: day, newUsers: 0, deposits: 0, games: 0, revenue: 0 };
  };

  for (const u of newUsers) {
    const day = getDay(u.createdAt);
    ensure(day);
    dailyMap[day].newUsers++;
  }
  for (const tx of deposits) {
    const day = getDay(tx.createdAt);
    ensure(day);
    dailyMap[day].deposits += Number(tx.amount);
  }
  for (const m of ludoGames) {
    const day = getDay(m.createdAt);
    ensure(day);
    dailyMap[day].games++;
    dailyMap[day].revenue += Number(m.platformFee);
  }
  for (const t of tournamentGames) {
    const day = getDay(t.createdAt);
    ensure(day);
    dailyMap[day].games++;
    dailyMap[day].revenue += Number(t.platformFee);
  }

  return {
    period,
    charts: Object.values(dailyMap).sort((a, b) => a.date.localeCompare(b.date)),
  };
};

// ─── User Management ─────────────────────────────────────────────────────────

export const listUsers = async (query: ListUsersQuery) => {
  const { page, limit, search, role, isBanned } = query;
  const skip = (page - 1) * limit;

  const where: Prisma.UserWhereInput = {};
  if (role) where.role = role;
  if (isBanned !== undefined) where.isBanned = isBanned;
  if (search) {
    where.OR = [
      { username: { contains: search, mode: 'insensitive' } },
      { email: { contains: search, mode: 'insensitive' } },
      { phone: { contains: search, mode: 'insensitive' } },
    ];
  }

  const [total, items] = await Promise.all([
    prisma.user.count({ where }),
    prisma.user.findMany({
      where,
      select: {
        id: true,
        username: true,
        email: true,
        phone: true,
        role: true,
        isBanned: true,
        isVerified: true,
        level: true,
        totalGamesPlayed: true,
        totalWins: true,
        lastLoginAt: true,
        createdAt: true,
      },
      orderBy: { createdAt: 'desc' },
      skip,
      take: limit,
    }),
  ]);

  return { total, page, limit, totalPages: Math.ceil(total / limit), items };
};

export const getUserDetails = async (userId: string) => {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    include: {
      wallet: true,
      transactions: { orderBy: { createdAt: 'desc' }, take: 20 },
      wagers: { orderBy: { createdAt: 'desc' }, take: 10 },
      bonuses: { orderBy: { createdAt: 'desc' }, take: 10 },
    },
  });

  if (!user) throw new AppError('User not found', 404);
  return user;
};

export const updateUser = async (adminId: string, userId: string, data: UpdateUserInput, ip?: string) => {
  const existing = await prisma.user.findUnique({ where: { id: userId } });
  if (!existing) throw new AppError('User not found', 404);

  const updated = await prisma.user.update({
    where: { id: userId },
    data,
    select: { id: true, username: true, email: true, role: true, level: true, xp: true, isVerified: true },
  });

  await createAuditLog(adminId, 'UPDATE_USER', 'user', userId, existing, data, ip);
  return updated;
};

export const banUser = async (adminId: string, userId: string, data: BanUserInput, ip?: string) => {
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user) throw new AppError('User not found', 404);
  if (user.isBanned) throw new AppError('User is already banned', 400);

  await prisma.user.update({
    where: { id: userId },
    data: { isBanned: true, banReason: data.reason },
  });

  await createAuditLog(adminId, 'BAN_USER', 'user', userId, { isBanned: false }, { isBanned: true, reason: data.reason }, ip);
  return { success: true };
};

export const unbanUser = async (adminId: string, userId: string, ip?: string) => {
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user) throw new AppError('User not found', 404);
  if (!user.isBanned) throw new AppError('User is not banned', 400);

  await prisma.user.update({
    where: { id: userId },
    data: { isBanned: false, banReason: null },
  });

  await createAuditLog(adminId, 'UNBAN_USER', 'user', userId, { isBanned: true }, { isBanned: false }, ip);
  return { success: true };
};

export const creditUser = async (adminId: string, userId: string, data: CreditDebitInput, ip?: string) => {
  const wallet = await prisma.wallet.findUnique({ where: { userId } });
  if (!wallet) throw new AppError('Wallet not found', 404);

  const balanceField = data.balanceType === 'main'
    ? 'mainBalance'
    : data.balanceType === 'winning'
    ? 'winningBalance'
    : 'bonusBalance';

  await prisma.$transaction(async (tx) => {
    await tx.wallet.update({
      where: { userId },
      data: { [balanceField]: { increment: new Prisma.Decimal(data.amount) } },
    });

    await tx.transaction.create({
      data: {
        userId,
        type: TransactionType.ADMIN_CREDIT,
        amount: new Prisma.Decimal(data.amount),
        status: TransactionStatus.COMPLETED,
        balanceType: data.balanceType,
        adminNote: data.note,
      },
    });

    await tx.notification.create({
      data: {
        userId,
        title: 'Balance Credited',
        body: `Admin has credited ${data.amount} to your ${data.balanceType} balance${data.note ? `. Note: ${data.note}` : ''}.`,
        type: 'ADMIN_CREDIT',
      },
    });
  });

  await createAuditLog(adminId, 'CREDIT_USER', 'wallet', userId, null, data, ip);
  return { success: true };
};

export const debitUser = async (adminId: string, userId: string, data: CreditDebitInput, ip?: string) => {
  const wallet = await prisma.wallet.findUnique({ where: { userId } });
  if (!wallet) throw new AppError('Wallet not found', 404);

  const balanceField = data.balanceType === 'main'
    ? 'mainBalance'
    : data.balanceType === 'winning'
    ? 'winningBalance'
    : 'bonusBalance';

  const currentBalance = Number(wallet[balanceField]);
  if (currentBalance < data.amount) {
    throw new AppError(`Insufficient ${data.balanceType} balance`, 400);
  }

  await prisma.$transaction(async (tx) => {
    await tx.wallet.update({
      where: { userId },
      data: { [balanceField]: { decrement: new Prisma.Decimal(data.amount) } },
    });

    await tx.transaction.create({
      data: {
        userId,
        type: TransactionType.ADMIN_DEBIT,
        amount: new Prisma.Decimal(data.amount),
        status: TransactionStatus.COMPLETED,
        balanceType: data.balanceType,
        adminNote: data.note,
      },
    });

    await tx.notification.create({
      data: {
        userId,
        title: 'Balance Debited',
        body: `Admin has debited ${data.amount} from your ${data.balanceType} balance${data.note ? `. Note: ${data.note}` : ''}.`,
        type: 'ADMIN_DEBIT',
      },
    });
  });

  await createAuditLog(adminId, 'DEBIT_USER', 'wallet', userId, null, data, ip);
  return { success: true };
};

// ─── Tournament Management ───────────────────────────────────────────────────

export const createTournament = async (adminId: string, data: CreateTournamentAdminInput, ip?: string) => {
  const tournament = await prisma.tournament.create({
    data: {
      ...data,
      entryFee: new Prisma.Decimal(data.entryFee),
      prizePool: new Prisma.Decimal(data.prizePool),
      perKillPrize: data.perKillPrize != null ? new Prisma.Decimal(data.perKillPrize) : undefined,
      registrationStart: data.registrationStart ? new Date(data.registrationStart) : undefined,
      registrationEnd: data.registrationEnd ? new Date(data.registrationEnd) : undefined,
      matchStart: data.matchStart ? new Date(data.matchStart) : undefined,
      matchEnd: data.matchEnd ? new Date(data.matchEnd) : undefined,
      prizeDistribution: data.prizeDistribution as Prisma.InputJsonValue ?? undefined,
      createdById: adminId,
    },
  });

  await createAuditLog(adminId, 'CREATE_TOURNAMENT', 'tournament', tournament.id, null, data, ip);
  return tournament;
};

export const updateTournament = async (
  adminId: string,
  tournamentId: string,
  data: UpdateTournamentAdminInput,
  ip?: string
) => {
  const existing = await prisma.tournament.findUnique({ where: { id: tournamentId } });
  if (!existing) throw new AppError('Tournament not found', 404);

  const updated = await prisma.tournament.update({
    where: { id: tournamentId },
    data: {
      ...data,
      entryFee: data.entryFee != null ? new Prisma.Decimal(data.entryFee) : undefined,
      prizePool: data.prizePool != null ? new Prisma.Decimal(data.prizePool) : undefined,
      perKillPrize: data.perKillPrize != null ? new Prisma.Decimal(data.perKillPrize) : undefined,
      registrationStart: data.registrationStart ? new Date(data.registrationStart) : undefined,
      registrationEnd: data.registrationEnd ? new Date(data.registrationEnd) : undefined,
      matchStart: data.matchStart ? new Date(data.matchStart) : undefined,
      matchEnd: data.matchEnd ? new Date(data.matchEnd) : undefined,
      prizeDistribution: data.prizeDistribution as Prisma.InputJsonValue ?? undefined,
    },
  });

  await createAuditLog(adminId, 'UPDATE_TOURNAMENT', 'tournament', tournamentId, existing, data, ip);
  return updated;
};

export const cancelTournament = async (adminId: string, tournamentId: string, ip?: string) => {
  const tournament = await prisma.tournament.findUnique({
    where: { id: tournamentId },
    include: { participants: true },
  });

  if (!tournament) throw new AppError('Tournament not found', 404);

  if (tournament.status === TournamentStatus.CANCELLED) {
    throw new AppError('Tournament is already cancelled', 400);
  }

  await prisma.$transaction(async (tx) => {
    await tx.tournament.update({
      where: { id: tournamentId },
      data: { status: TournamentStatus.CANCELLED },
    });

    // Refund all participants
    if (Number(tournament.entryFee) > 0) {
      for (const participant of tournament.participants) {
        await tx.wallet.update({
          where: { userId: participant.userId },
          data: { mainBalance: { increment: tournament.entryFee } },
        });

        await tx.transaction.create({
          data: {
            userId: participant.userId,
            type: TransactionType.REFUND,
            amount: tournament.entryFee,
            status: TransactionStatus.COMPLETED,
            referenceType: 'tournament',
            referenceId: tournamentId,
            adminNote: 'Tournament cancelled by admin',
          },
        });

        await tx.notification.create({
          data: {
            userId: participant.userId,
            title: 'Tournament Cancelled',
            body: `The tournament "${tournament.title}" has been cancelled. Your entry fee has been refunded.`,
            type: 'TOURNAMENT_CANCELLED',
            referenceType: 'tournament',
            referenceId: tournamentId,
          },
        });
      }
    }
  });

  await createAuditLog(adminId, 'CANCEL_TOURNAMENT', 'tournament', tournamentId, { status: tournament.status }, { status: TournamentStatus.CANCELLED }, ip);
  return { success: true };
};

export const setTournamentRoom = async (
  adminId: string,
  tournamentId: string,
  data: SetRoomInput,
  ip?: string
) => {
  const tournament = await prisma.tournament.findUnique({ where: { id: tournamentId } });
  if (!tournament) throw new AppError('Tournament not found', 404);

  const updated = await prisma.tournament.update({
    where: { id: tournamentId },
    data: { roomId: data.roomId, roomPassword: data.roomPassword, roomVisibleAt: new Date() },
  });

  await createAuditLog(adminId, 'SET_TOURNAMENT_ROOM', 'tournament', tournamentId, null, data, ip);
  return updated;
};

export const publishTournamentResults = async (
  adminId: string,
  tournamentId: string,
  data: PublishResultsInput,
  ip?: string
) => {
  const tournament = await prisma.tournament.findUnique({
    where: { id: tournamentId },
    include: { participants: true },
  });

  if (!tournament) throw new AppError('Tournament not found', 404);

  const prizeDistribution = tournament.prizeDistribution as Record<string, number> | null;
  const perKillPrize = Number(tournament.perKillPrize ?? 0);

  await prisma.$transaction(async (tx) => {
    for (const result of data.results) {
      const prize = (prizeDistribution?.[String(result.placement)] ?? 0) + result.kills * perKillPrize;

      await tx.tournamentParticipant.updateMany({
        where: { tournamentId, userId: result.userId },
        data: {
          kills: result.kills,
          placement: result.placement,
          points: result.kills + (100 - result.placement),
          prizeWon: prize > 0 ? new Prisma.Decimal(prize) : undefined,
          status: 'COMPLETED',
        },
      });

      if (prize > 0) {
        await tx.wallet.update({
          where: { userId: result.userId },
          data: { winningBalance: { increment: new Prisma.Decimal(prize) } },
        });

        await tx.transaction.create({
          data: {
            userId: result.userId,
            type: TransactionType.WINNING_CREDIT,
            amount: new Prisma.Decimal(prize),
            status: TransactionStatus.COMPLETED,
            referenceType: 'tournament',
            referenceId: tournamentId,
          },
        });

        await tx.notification.create({
          data: {
            userId: result.userId,
            title: 'Tournament Results',
            body: `You placed #${result.placement} in "${tournament.title}" and won $${prize}.`,
            type: 'TOURNAMENT_RESULTS',
            referenceType: 'tournament',
            referenceId: tournamentId,
          },
        });
      }
    }

    await tx.tournament.update({
      where: { id: tournamentId },
      data: { status: TournamentStatus.COMPLETED },
    });
  });

  await createAuditLog(adminId, 'PUBLISH_TOURNAMENT_RESULTS', 'tournament', tournamentId, null, data, ip);
  return { success: true };
};

export const updateTournamentStatus = async (
  adminId: string,
  tournamentId: string,
  data: UpdateTournamentStatusInput,
  ip?: string
) => {
  const tournament = await prisma.tournament.findUnique({ where: { id: tournamentId } });
  if (!tournament) throw new AppError('Tournament not found', 404);

  const updated = await prisma.tournament.update({
    where: { id: tournamentId },
    data: { status: data.status },
  });

  await createAuditLog(adminId, 'UPDATE_TOURNAMENT_STATUS', 'tournament', tournamentId, { status: tournament.status }, data, ip);
  return updated;
};

// ─── Ludo Management ─────────────────────────────────────────────────────────

export const listLudoMatches = async (query: ListLudoMatchesQuery) => {
  const { page, limit, status } = query;
  const skip = (page - 1) * limit;

  const where: Prisma.LudoMatchWhereInput = {};
  if (status) where.status = status as LudoMatchStatus;

  const [total, items] = await Promise.all([
    prisma.ludoMatch.count({ where }),
    prisma.ludoMatch.findMany({
      where,
      include: {
        players: { include: { user: { select: { id: true, username: true } } } },
        winner: { select: { id: true, username: true } },
      },
      orderBy: { createdAt: 'desc' },
      skip,
      take: limit,
    }),
  ]);

  return { total, page, limit, totalPages: Math.ceil(total / limit), items };
};

export const getLudoMatchDetails = async (matchId: string) => {
  const match = await prisma.ludoMatch.findUnique({
    where: { id: matchId },
    include: {
      players: { include: { user: { select: { id: true, username: true } } } },
      winner: { select: { id: true, username: true } },
      moves: { orderBy: { timestamp: 'asc' } },
    },
  });

  if (!match) throw new AppError('Ludo match not found', 404);
  return match;
};

export const resolveLudoMatch = async (
  adminId: string,
  matchId: string,
  data: ResolveLudoMatchInput,
  ip?: string
) => {
  const match = await prisma.ludoMatch.findUnique({
    where: { id: matchId },
    include: { players: true },
  });

  if (!match) throw new AppError('Ludo match not found', 404);

  if (match.status === LudoMatchStatus.COMPLETED || match.status === LudoMatchStatus.CANCELLED) {
    throw new AppError(`Cannot resolve match with status: ${match.status}`, 400);
  }

  const winnerPlayer = match.players.find((p) => p.userId === data.winnerId);
  if (!winnerPlayer) throw new AppError('Winner must be a player in this match', 400);

  await prisma.$transaction(async (tx) => {
    await tx.ludoMatch.update({
      where: { id: matchId },
      data: {
        status: LudoMatchStatus.COMPLETED,
        winnerId: data.winnerId,
        gameEndedAt: new Date(),
      },
    });

    // Credit winner
    await tx.wallet.update({
      where: { userId: data.winnerId },
      data: { winningBalance: { increment: match.prizePool } },
    });

    await tx.transaction.create({
      data: {
        userId: data.winnerId,
        type: TransactionType.WINNING_CREDIT,
        amount: match.prizePool,
        status: TransactionStatus.COMPLETED,
        referenceType: 'ludo_match',
        referenceId: matchId,
        adminNote: data.reason,
      },
    });

    await tx.notification.create({
      data: {
        userId: data.winnerId,
        title: 'Match Resolved',
        body: `Admin resolved match. You won $${match.prizePool}. Reason: ${data.reason}`,
        type: 'MATCH_RESOLVED',
        referenceType: 'ludo_match',
        referenceId: matchId,
      },
    });
  });

  await createAuditLog(adminId, 'RESOLVE_LUDO_MATCH', 'ludo_match', matchId, { status: match.status }, data, ip);
  return { success: true };
};

// ─── Financial ───────────────────────────────────────────────────────────────

export const listTransactions = async (query: ListTransactionsQuery) => {
  const { page, limit, type, status, userId, dateFrom, dateTo } = query;
  const skip = (page - 1) * limit;

  const where: Prisma.TransactionWhereInput = {};
  if (type) where.type = type;
  if (status) where.status = status;
  if (userId) where.userId = userId;
  if (dateFrom || dateTo) {
    where.createdAt = {};
    if (dateFrom) where.createdAt.gte = new Date(dateFrom);
    if (dateTo) where.createdAt.lte = new Date(dateTo);
  }

  const [total, items] = await Promise.all([
    prisma.transaction.count({ where }),
    prisma.transaction.findMany({
      where,
      include: { user: { select: { id: true, username: true, email: true } } },
      orderBy: { createdAt: 'desc' },
      skip,
      take: limit,
    }),
  ]);

  return { total, page, limit, totalPages: Math.ceil(total / limit), items };
};

export const listPendingWithdrawals = async () => {
  const items = await prisma.transaction.findMany({
    where: { type: TransactionType.WITHDRAWAL, status: TransactionStatus.PENDING },
    include: { user: { select: { id: true, username: true, email: true } } },
    orderBy: { createdAt: 'asc' },
  });

  return items;
};

export const approveWithdrawal = async (adminId: string, withdrawalId: string, ip?: string) => {
  const transaction = await prisma.transaction.findUnique({ where: { id: withdrawalId } });

  if (!transaction || transaction.type !== TransactionType.WITHDRAWAL) {
    throw new AppError('Withdrawal not found', 404);
  }

  if (transaction.status !== TransactionStatus.PENDING) {
    throw new AppError(`Cannot approve withdrawal with status: ${transaction.status}`, 400);
  }

  await prisma.$transaction(async (tx) => {
    await tx.transaction.update({
      where: { id: withdrawalId },
      data: { status: TransactionStatus.PROCESSING, adminNote: `Approved by admin ${adminId}` },
    });

    await tx.wallet.update({
      where: { userId: transaction.userId },
      data: {
        lockedBalance: { decrement: transaction.amount },
        totalWithdrawn: { increment: transaction.amount },
      },
    });

    await tx.auditLog.create({
      data: {
        adminId,
        action: 'APPROVE_WITHDRAWAL',
        entityType: 'transaction',
        entityId: withdrawalId,
        newValue: { status: TransactionStatus.PROCESSING },
        ipAddress: ip,
      },
    });

    await tx.notification.create({
      data: {
        userId: transaction.userId,
        title: 'Withdrawal Approved',
        body: `Your withdrawal of $${transaction.amount} has been approved and is being processed.`,
        type: 'WITHDRAWAL_APPROVED',
        referenceType: 'transaction',
        referenceId: withdrawalId,
      },
    });
  });

  return { status: TransactionStatus.PROCESSING };
};

export const rejectWithdrawal = async (
  adminId: string,
  withdrawalId: string,
  data: RejectWithdrawalInput,
  ip?: string
) => {
  const transaction = await prisma.transaction.findUnique({ where: { id: withdrawalId } });

  if (!transaction || transaction.type !== TransactionType.WITHDRAWAL) {
    throw new AppError('Withdrawal not found', 404);
  }

  if (transaction.status !== TransactionStatus.PENDING) {
    throw new AppError(`Cannot reject withdrawal with status: ${transaction.status}`, 400);
  }

  await prisma.$transaction(async (tx) => {
    await tx.transaction.update({
      where: { id: withdrawalId },
      data: { status: TransactionStatus.FAILED, adminNote: data.reason },
    });

    await tx.wallet.update({
      where: { userId: transaction.userId },
      data: {
        lockedBalance: { decrement: transaction.amount },
        winningBalance: { increment: transaction.amount },
      },
    });

    await tx.auditLog.create({
      data: {
        adminId,
        action: 'REJECT_WITHDRAWAL',
        entityType: 'transaction',
        entityId: withdrawalId,
        newValue: { status: TransactionStatus.FAILED, reason: data.reason },
        ipAddress: ip,
      },
    });

    await tx.notification.create({
      data: {
        userId: transaction.userId,
        title: 'Withdrawal Rejected',
        body: `Your withdrawal of $${transaction.amount} was rejected. Reason: ${data.reason}. Funds returned to your balance.`,
        type: 'WITHDRAWAL_REJECTED',
        referenceType: 'transaction',
        referenceId: withdrawalId,
      },
    });
  });

  return { status: TransactionStatus.FAILED };
};

// ─── Bonus Management ────────────────────────────────────────────────────────

export const listBonusSchedules = async () => {
  return prisma.bonusSchedule.findMany({ orderBy: { createdAt: 'desc' } });
};

export const createBonusSchedule = async (
  adminId: string,
  data: CreateBonusScheduleInput,
  ip?: string
) => {
  const schedule = await prisma.bonusSchedule.create({
    data: {
      bonusType: data.bonusType,
      frequency: data.frequency,
      baseAmount: new Prisma.Decimal(data.baseAmount),
      multiplierRules: data.multiplierRules as Prisma.InputJsonValue ?? undefined,
      minGamesRequired: data.minGamesRequired ?? 0,
      minDepositRequired: data.minDepositRequired != null ? new Prisma.Decimal(data.minDepositRequired) : undefined,
      isActive: data.isActive ?? true,
    },
  });

  await createAuditLog(adminId, 'CREATE_BONUS_SCHEDULE', 'bonus_schedule', schedule.id, null, data, ip);
  return schedule;
};

export const updateBonusSchedule = async (
  adminId: string,
  scheduleId: string,
  data: UpdateBonusScheduleInput,
  ip?: string
) => {
  const existing = await prisma.bonusSchedule.findUnique({ where: { id: scheduleId } });
  if (!existing) throw new AppError('Bonus schedule not found', 404);

  const updated = await prisma.bonusSchedule.update({
    where: { id: scheduleId },
    data: {
      ...data,
      baseAmount: data.baseAmount != null ? new Prisma.Decimal(data.baseAmount) : undefined,
      multiplierRules: data.multiplierRules as Prisma.InputJsonValue ?? undefined,
      minDepositRequired: data.minDepositRequired != null ? new Prisma.Decimal(data.minDepositRequired) : undefined,
    },
  });

  await createAuditLog(adminId, 'UPDATE_BONUS_SCHEDULE', 'bonus_schedule', scheduleId, existing, data, ip);
  return updated;
};

export const sendBulkBonus = async (adminId: string, data: SendBulkBonusInput, ip?: string) => {
  const results = { success: 0, failed: 0, errors: [] as string[] };

  for (const userId of data.userIds) {
    try {
      await prisma.$transaction(async (tx) => {
        await tx.wallet.update({
          where: { userId },
          data: { bonusBalance: { increment: new Prisma.Decimal(data.amount) } },
        });

        await tx.bonus.create({
          data: {
            userId,
            bonusType: data.bonusType,
            amount: new Prisma.Decimal(data.amount),
            isClaimed: true,
            claimedAt: new Date(),
          },
        });

        await tx.transaction.create({
          data: {
            userId,
            type: TransactionType.BONUS_CREDIT,
            amount: new Prisma.Decimal(data.amount),
            status: TransactionStatus.COMPLETED,
            balanceType: 'bonus',
            adminNote: data.note,
          },
        });

        await tx.notification.create({
          data: {
            userId,
            title: 'Bonus Received',
            body: `You have received a bonus of $${data.amount}${data.note ? `. Note: ${data.note}` : ''}.`,
            type: 'ADMIN_BONUS',
          },
        });
      });
      results.success++;
    } catch (err) {
      results.failed++;
      const message = err instanceof Error ? err.message : 'Unknown error';
      results.errors.push(`Failed for userId: ${userId} – ${message}`);
    }
  }

  await createAuditLog(adminId, 'SEND_BULK_BONUS', 'bonus', 'bulk', null, data, ip);
  return results;
};

export const createPromoCode = async (adminId: string, data: CreatePromoCodeInput, ip?: string) => {
  const promoCode = await prisma.promoCode.create({
    data: {
      code: data.code,
      bonusType: data.bonusType,
      bonusAmount: new Prisma.Decimal(data.bonusAmount),
      maxUses: data.maxUses,
      minDeposit: data.minDeposit != null ? new Prisma.Decimal(data.minDeposit) : undefined,
      expiresAt: data.expiresAt ? new Date(data.expiresAt) : undefined,
    },
  });

  await createAuditLog(adminId, 'CREATE_PROMO_CODE', 'promo_code', promoCode.id, null, data, ip);
  return promoCode;
};

export const listPromoCodes = async () => {
  return prisma.promoCode.findMany({ orderBy: { createdAt: 'desc' } });
};

// ─── Disputes ────────────────────────────────────────────────────────────────

export const listDisputes = async (query: ListDisputesQuery) => {
  const { page, limit, status, gameType } = query;
  const skip = (page - 1) * limit;

  const where: Prisma.DisputeWhereInput = {};
  if (status) where.status = status;
  if (gameType) where.gameType = gameType;

  const [total, items] = await Promise.all([
    prisma.dispute.count({ where }),
    prisma.dispute.findMany({
      where,
      include: {
        user: { select: { id: true, username: true, email: true } },
        resolvedBy: { select: { id: true, username: true } },
      },
      orderBy: { createdAt: 'desc' },
      skip,
      take: limit,
    }),
  ]);

  return { total, page, limit, totalPages: Math.ceil(total / limit), items };
};

export const resolveDispute = async (
  adminId: string,
  disputeId: string,
  data: ResolveDisputeInput,
  ip?: string
) => {
  const dispute = await prisma.dispute.findUnique({ where: { id: disputeId } });
  if (!dispute) throw new AppError('Dispute not found', 404);

  if (dispute.status === DisputeStatus.RESOLVED || dispute.status === DisputeStatus.REJECTED) {
    throw new AppError('Dispute is already closed', 400);
  }

  await prisma.$transaction(async (tx) => {
    await tx.dispute.update({
      where: { id: disputeId },
      data: {
        status: data.status,
        adminResponse: data.adminResponse,
        resolvedById: adminId,
        resolvedAt: new Date(),
      },
    });

    if (data.status === DisputeStatus.RESOLVED && data.refundAmount && data.refundAmount > 0) {
      await tx.wallet.update({
        where: { userId: dispute.userId },
        data: { mainBalance: { increment: new Prisma.Decimal(data.refundAmount) } },
      });

      await tx.transaction.create({
        data: {
          userId: dispute.userId,
          type: TransactionType.REFUND,
          amount: new Prisma.Decimal(data.refundAmount),
          status: TransactionStatus.COMPLETED,
          referenceType: 'dispute',
          referenceId: disputeId,
          adminNote: data.adminResponse,
        },
      });
    }

    await tx.notification.create({
      data: {
        userId: dispute.userId,
        title: 'Dispute Resolved',
        body: `Your dispute has been ${data.status.toLowerCase()}. Admin response: ${data.adminResponse}`,
        type: 'DISPUTE_RESOLVED',
        referenceType: 'dispute',
        referenceId: disputeId,
      },
    });
  });

  await createAuditLog(adminId, 'RESOLVE_DISPUTE', 'dispute', disputeId, { status: dispute.status }, data, ip);
  return { success: true };
};

// ─── Settings ────────────────────────────────────────────────────────────────

export const getSettings = async () => {
  return prisma.appSetting.findMany({ orderBy: { key: 'asc' } });
};

export const updateSetting = async (adminId: string, key: string, value: unknown, ip?: string) => {
  const existing = await prisma.appSetting.findUnique({ where: { key } });

  const setting = await prisma.appSetting.upsert({
    where: { key },
    update: { value: value as Prisma.InputJsonValue, updatedById: adminId },
    create: { key, value: value as Prisma.InputJsonValue, updatedById: adminId },
  });

  await createAuditLog(
    adminId,
    'UPDATE_SETTING',
    'app_setting',
    key,
    existing ? { value: existing.value } : null,
    { value },
    ip
  );

  return setting;
};

// ─── Audit Logs ──────────────────────────────────────────────────────────────

export const listAuditLogs = async (query: ListAuditLogsQuery) => {
  const { page, limit, adminId, action, entityType, dateFrom, dateTo } = query;
  const skip = (page - 1) * limit;

  const where: Prisma.AuditLogWhereInput = {};
  if (adminId) where.adminId = adminId;
  if (action) where.action = { contains: action, mode: 'insensitive' };
  if (entityType) where.entityType = entityType;
  if (dateFrom || dateTo) {
    where.createdAt = {};
    if (dateFrom) where.createdAt.gte = new Date(dateFrom);
    if (dateTo) where.createdAt.lte = new Date(dateTo);
  }

  const [total, items] = await Promise.all([
    prisma.auditLog.count({ where }),
    prisma.auditLog.findMany({
      where,
      include: { admin: { select: { id: true, username: true } } },
      orderBy: { createdAt: 'desc' },
      skip,
      take: limit,
    }),
  ]);

  return { total, page, limit, totalPages: Math.ceil(total / limit), items };
};
