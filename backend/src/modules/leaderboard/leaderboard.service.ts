import { prisma } from '../../config/database';
import { redis } from '../../config/redis';

type Period = 'daily' | 'weekly' | 'monthly' | 'alltime';

const LEADERBOARD_TTL = 300; // 5 minutes

function getPeriodStart(period: Period): Date | null {
  const now = new Date();
  if (period === 'daily') {
    return new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
  }
  if (period === 'weekly') {
    const day = now.getUTCDay();
    const diff = (day + 6) % 7;
    return new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() - diff));
  }
  if (period === 'monthly') {
    return new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1));
  }
  return null; // alltime
}

function cacheKey(type: string, period: string): string {
  return `leaderboard:${type}:${period}`;
}

interface LeaderboardEntry {
  rank: number;
  userId: string;
  username: string;
  avatarUrl: string | null;
  wins: number;
  totalWagered: number;
  netProfit: number;
}

async function computeGameLeaderboard(
  gameType: 'LUDO' | 'FREE_FIRE',
  period: Period,
  userId: string,
): Promise<{ leaderboard: LeaderboardEntry[]; userRank: number | null }> {
  const periodStart = getPeriodStart(period);
  const dateFilter = periodStart ? { createdAt: { gte: periodStart } } : {};

  const wagers = await prisma.wager.groupBy({
    by: ['userId'],
    where: { gameType, ...dateFilter },
    _count: { id: true },
    _sum: { entryAmount: true, actualWin: true },
    orderBy: { _count: { id: 'desc' } },
    take: 200, // fetch extra to find user rank beyond top 100
  });

  // Fetch usernames in batch
  const userIds = wagers.map((w) => w.userId);
  const users = await prisma.user.findMany({
    where: { id: { in: userIds } },
    select: { id: true, username: true, avatarUrl: true },
  });
  const userMap = new Map(users.map((u) => [u.id, u]));

  const entries: LeaderboardEntry[] = wagers.map((w, idx) => {
    const user = userMap.get(w.userId);
    const wagered = Number(w._sum.entryAmount ?? 0);
    const won = Number(w._sum.actualWin ?? 0);
    return {
      rank: idx + 1,
      userId: w.userId,
      username: user?.username ?? 'Unknown',
      avatarUrl: user?.avatarUrl ?? null,
      wins: w._count.id,
      totalWagered: wagered,
      netProfit: parseFloat((won - wagered).toFixed(2)),
    };
  });

  const userRankEntry = entries.find((e) => e.userId === userId);
  const userRank = userRankEntry?.rank ?? null;

  return { leaderboard: entries.slice(0, 100), userRank };
}

async function computeEarningsLeaderboard(
  period: Period,
  userId: string,
): Promise<{ leaderboard: LeaderboardEntry[]; userRank: number | null }> {
  const periodStart = getPeriodStart(period);
  const dateFilter = periodStart ? { createdAt: { gte: periodStart } } : {};

  const wagers = await prisma.wager.groupBy({
    by: ['userId'],
    where: { status: 'WON', ...dateFilter },
    _sum: { actualWin: true, entryAmount: true },
    orderBy: { _sum: { actualWin: 'desc' } },
    take: 200,
  });

  const userIds = wagers.map((w) => w.userId);
  const users = await prisma.user.findMany({
    where: { id: { in: userIds } },
    select: { id: true, username: true, avatarUrl: true },
  });
  const userMap = new Map(users.map((u) => [u.id, u]));

  const entries: LeaderboardEntry[] = wagers.map((w, idx) => {
    const user = userMap.get(w.userId);
    const wagered = Number(w._sum.entryAmount ?? 0);
    const won = Number(w._sum.actualWin ?? 0);
    return {
      rank: idx + 1,
      userId: w.userId,
      username: user?.username ?? 'Unknown',
      avatarUrl: user?.avatarUrl ?? null,
      wins: 0,
      totalWagered: wagered,
      netProfit: parseFloat((won - wagered).toFixed(2)),
    };
  });

  const userRankEntry = entries.find((e) => e.userId === userId);
  const userRank = userRankEntry?.rank ?? null;

  return { leaderboard: entries.slice(0, 100), userRank };
}

async function computeReferralLeaderboard(
  userId: string,
): Promise<{ leaderboard: Array<{ rank: number; userId: string; username: string; avatarUrl: string | null; referralCount: number }>; userRank: number | null }> {
  const referrals = await prisma.referral.groupBy({
    by: ['referrerId'],
    _count: { id: true },
    orderBy: { _count: { id: 'desc' } },
    take: 200,
  });

  const userIds = referrals.map((r) => r.referrerId);
  const users = await prisma.user.findMany({
    where: { id: { in: userIds } },
    select: { id: true, username: true, avatarUrl: true },
  });
  const userMap = new Map(users.map((u) => [u.id, u]));

  const entries = referrals.map((r, idx) => {
    const user = userMap.get(r.referrerId);
    return {
      rank: idx + 1,
      userId: r.referrerId,
      username: user?.username ?? 'Unknown',
      avatarUrl: user?.avatarUrl ?? null,
      referralCount: r._count.id,
    };
  });

  const userRankEntry = entries.find((e) => e.userId === userId);
  const userRank = userRankEntry?.rank ?? null;

  return { leaderboard: entries.slice(0, 100), userRank };
}

// ─── Public API ──────────────────────────────────────────────────────────────

export const getLudoLeaderboard = async (period: Period, userId: string) => {
  const key = cacheKey('ludo', period);
  const cached = await redis.get(key);
  if (cached) {
    const data = JSON.parse(cached) as { leaderboard: LeaderboardEntry[] };
    const userRankEntry = data.leaderboard.find((e) => e.userId === userId);
    return { ...data, userRank: userRankEntry?.rank ?? null };
  }

  const result = await computeGameLeaderboard('LUDO', period, userId);
  await redis.setex(key, LEADERBOARD_TTL, JSON.stringify({ leaderboard: result.leaderboard }));
  return result;
};

export const getFreeFireLeaderboard = async (period: Period, userId: string) => {
  const key = cacheKey('freefire', period);
  const cached = await redis.get(key);
  if (cached) {
    const data = JSON.parse(cached) as { leaderboard: LeaderboardEntry[] };
    const userRankEntry = data.leaderboard.find((e) => e.userId === userId);
    return { ...data, userRank: userRankEntry?.rank ?? null };
  }

  const result = await computeGameLeaderboard('FREE_FIRE', period, userId);
  await redis.setex(key, LEADERBOARD_TTL, JSON.stringify({ leaderboard: result.leaderboard }));
  return result;
};

export const getEarningsLeaderboard = async (period: Period, userId: string) => {
  const key = cacheKey('earnings', period);
  const cached = await redis.get(key);
  if (cached) {
    const data = JSON.parse(cached) as { leaderboard: LeaderboardEntry[] };
    const userRankEntry = data.leaderboard.find((e) => e.userId === userId);
    return { ...data, userRank: userRankEntry?.rank ?? null };
  }

  const result = await computeEarningsLeaderboard(period, userId);
  await redis.setex(key, LEADERBOARD_TTL, JSON.stringify({ leaderboard: result.leaderboard }));
  return result;
};

export const getReferralLeaderboard = async (userId: string) => {
  const key = cacheKey('referrals', 'alltime');
  const cached = await redis.get(key);
  if (cached) {
    const data = JSON.parse(cached) as { leaderboard: Array<{ rank: number; userId: string; username: string; avatarUrl: string | null; referralCount: number }> };
    const userRankEntry = data.leaderboard.find((e) => e.userId === userId);
    return { ...data, userRank: userRankEntry?.rank ?? null };
  }

  const result = await computeReferralLeaderboard(userId);
  await redis.setex(key, LEADERBOARD_TTL, JSON.stringify({ leaderboard: result.leaderboard }));
  return result;
};

// ─── Cron helper: recompute and cache all leaderboards ───────────────────────

export const recomputeAllLeaderboards = async () => {
  const periods: Period[] = ['daily', 'weekly', 'monthly', 'alltime'];
  const SYSTEM_USER_ID = ''; // placeholder; user rank will be null from cache anyway

  await Promise.all([
    ...periods.map(async (p) => {
      const ludoResult = await computeGameLeaderboard('LUDO', p, SYSTEM_USER_ID);
      await redis.setex(cacheKey('ludo', p), LEADERBOARD_TTL, JSON.stringify({ leaderboard: ludoResult.leaderboard }));

      const ffResult = await computeGameLeaderboard('FREE_FIRE', p, SYSTEM_USER_ID);
      await redis.setex(cacheKey('freefire', p), LEADERBOARD_TTL, JSON.stringify({ leaderboard: ffResult.leaderboard }));
    }),
    ...['weekly', 'monthly', 'alltime'].map(async (p) => {
      const earningsResult = await computeEarningsLeaderboard(p as Period, SYSTEM_USER_ID);
      await redis.setex(cacheKey('earnings', p), LEADERBOARD_TTL, JSON.stringify({ leaderboard: earningsResult.leaderboard }));
    }),
    (async () => {
      const refResult = await computeReferralLeaderboard(SYSTEM_USER_ID);
      await redis.setex(cacheKey('referrals', 'alltime'), LEADERBOARD_TTL, JSON.stringify({ leaderboard: refResult.leaderboard }));
    })(),
  ]);
};
