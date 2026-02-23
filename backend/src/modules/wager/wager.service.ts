import { Prisma } from '@prisma/client';
import { prisma } from '../../config/database';
import { AppError } from '../../middleware/error_handler.middleware';
import type { GetWagersQuery } from './wager.validation';

export const getWagers = async (userId: string, filters: GetWagersQuery) => {
  const { page, limit, gameType, status, dateFrom, dateTo } = filters;
  const skip = (page - 1) * limit;

  const where: Prisma.WagerWhereInput = { userId };
  if (gameType) where.gameType = gameType;
  if (status) where.status = status;
  if (dateFrom || dateTo) {
    where.createdAt = {};
    if (dateFrom) where.createdAt.gte = new Date(dateFrom);
    if (dateTo) where.createdAt.lte = new Date(dateTo);
  }

  const [total, items] = await Promise.all([
    prisma.wager.count({ where }),
    prisma.wager.findMany({
      where,
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
    items,
  };
};

export const getWagerById = async (userId: string, id: string) => {
  const wager = await prisma.wager.findFirst({ where: { id, userId } });
  if (!wager) {
    throw new AppError('Wager not found', 404);
  }
  return wager;
};

export const getWagerStats = async (userId: string) => {
  const result = await prisma.wager.aggregate({
    where: { userId },
    _sum: {
      entryAmount: true,
      actualWin: true,
    },
    _count: { id: true },
  });

  const [wonCount, lostCount] = await Promise.all([
    prisma.wager.count({ where: { userId, status: 'WON' } }),
    prisma.wager.count({ where: { userId, status: 'LOST' } }),
  ]);

  const totalWagered = Number(result._sum.entryAmount ?? 0);
  const totalWon = Number(result._sum.actualWin ?? 0);
  const totalLost = totalWagered - totalWon;
  const netProfit = totalWon - totalWagered;
  const roi = totalWagered > 0 ? (netProfit / totalWagered) * 100 : 0;

  return {
    totalBets: result._count.id,
    totalWins: wonCount,
    totalLosses: lostCount,
    totalWagered,
    totalWon,
    totalLost,
    netProfit,
    roiPercentage: parseFloat(roi.toFixed(2)),
  };
};

export const getDailyStats = async (userId: string) => {
  const since = new Date();
  since.setUTCDate(since.getUTCDate() - 29);
  since.setUTCHours(0, 0, 0, 0);

  const wagers = await prisma.wager.findMany({
    where: { userId, createdAt: { gte: since } },
    select: { createdAt: true, entryAmount: true, actualWin: true, status: true },
  });

  // Group by date
  const grouped: Record<string, { date: string; wagered: number; won: number; count: number }> = {};
  for (const w of wagers) {
    const date = w.createdAt.toISOString().split('T')[0];
    if (!grouped[date]) {
      grouped[date] = { date, wagered: 0, won: 0, count: 0 };
    }
    grouped[date].wagered += Number(w.entryAmount);
    grouped[date].won += Number(w.actualWin ?? 0);
    grouped[date].count++;
  }

  return Object.values(grouped).sort((a, b) => a.date.localeCompare(b.date));
};

export const getWeeklyStats = async (userId: string) => {
  const since = new Date();
  since.setUTCDate(since.getUTCDate() - 83); // ~12 weeks
  since.setUTCHours(0, 0, 0, 0);

  const wagers = await prisma.wager.findMany({
    where: { userId, createdAt: { gte: since } },
    select: { createdAt: true, entryAmount: true, actualWin: true, status: true },
  });

  const getWeekKey = (date: Date): string => {
    const d = new Date(date);
    const day = d.getUTCDay();
    const diff = (day + 6) % 7;
    d.setUTCDate(d.getUTCDate() - diff);
    return d.toISOString().split('T')[0];
  };

  const grouped: Record<string, { weekStart: string; wagered: number; won: number; count: number }> = {};
  for (const w of wagers) {
    const key = getWeekKey(w.createdAt);
    if (!grouped[key]) {
      grouped[key] = { weekStart: key, wagered: 0, won: 0, count: 0 };
    }
    grouped[key].wagered += Number(w.entryAmount);
    grouped[key].won += Number(w.actualWin ?? 0);
    grouped[key].count++;
  }

  return Object.values(grouped).sort((a, b) => a.weekStart.localeCompare(b.weekStart));
};

export const getMonthlyStats = async (userId: string) => {
  const since = new Date();
  since.setUTCFullYear(since.getUTCFullYear() - 1);
  since.setUTCDate(1);
  since.setUTCHours(0, 0, 0, 0);

  const wagers = await prisma.wager.findMany({
    where: { userId, createdAt: { gte: since } },
    select: { createdAt: true, entryAmount: true, actualWin: true, status: true },
  });

  const getMonthKey = (date: Date): string => {
    return `${date.getUTCFullYear()}-${String(date.getUTCMonth() + 1).padStart(2, '0')}`;
  };

  const grouped: Record<string, { month: string; wagered: number; won: number; count: number }> = {};
  for (const w of wagers) {
    const key = getMonthKey(w.createdAt);
    if (!grouped[key]) {
      grouped[key] = { month: key, wagered: 0, won: 0, count: 0 };
    }
    grouped[key].wagered += Number(w.entryAmount);
    grouped[key].won += Number(w.actualWin ?? 0);
    grouped[key].count++;
  }

  return Object.values(grouped).sort((a, b) => a.month.localeCompare(b.month));
};
