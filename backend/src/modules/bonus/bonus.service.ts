import { BonusType, TransactionType, TransactionStatus, Prisma } from '@prisma/client';
import { prisma } from '../../config/database';
import { redis } from '../../config/redis';
import { AppError } from '../../middleware/error_handler.middleware';
import type { GetBonusHistoryQuery } from './bonus.validation';

// Daily streak amounts indexed by streak day (1-7)
const DAILY_AMOUNTS: Record<number, number> = {
  1: 0.10,
  2: 0.15,
  3: 0.20,
  4: 0.30,
  5: 0.50,
  6: 0.75,
  7: 1.50,
};

// Weekly play tiers (sorted descending so highest tier is matched first)
const WEEKLY_TIERS = [
  { games: 50, amount: 7.0 },
  { games: 25, amount: 3.0 },
  { games: 10, amount: 1.0 },
];

// Monthly loyalty tiers (sorted descending)
const MONTHLY_TIERS = [
  { wagered: 1000, bonus: 75 },
  { wagered: 500, bonus: 30 },
  { wagered: 200, bonus: 10 },
  { wagered: 50, bonus: 2 },
];

const streakKey = (userId: string) => `daily_streak:${userId}`;
const promoUsedKey = (code: string) => `promo_used:${code}`;
const MS_PER_DAY = 86400000;

interface StreakData {
  currentDay: number;
  lastClaimDate: string;
}

function toDateString(date: Date): string {
  return date.toISOString().split('T')[0];
}

function getStartOfWeek(): Date {
  const now = new Date();
  const day = now.getUTCDay(); // 0 = Sunday
  const diff = (day + 6) % 7; // days since Monday
  return new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() - diff));
}

function getStartOfMonth(): Date {
  const now = new Date();
  return new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1));
}

function getEndOfMonth(): Date {
  const now = new Date();
  return new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + 1, 1));
}

// ─── Daily Bonus ────────────────────────────────────────────────────────────

export const getDailyBonus = async (userId: string) => {
  const raw = await redis.get(streakKey(userId));
  const today = toDateString(new Date());

  let currentDay = 1;
  let lastClaimDate = '';
  let alreadyClaimed = false;

  if (raw) {
    const data = JSON.parse(raw) as StreakData;
    currentDay = data.currentDay;
    lastClaimDate = data.lastClaimDate;
    alreadyClaimed = lastClaimDate === today;

    // If not claimed today, check if streak would reset
    if (!alreadyClaimed && lastClaimDate) {
      const last = new Date(lastClaimDate);
      const yesterday = toDateString(new Date(Date.now() - MS_PER_DAY));
      if (lastClaimDate !== yesterday) {
        // Streak broken — show day 1 as the claimable day
        currentDay = 1;
      }
    }
  }

  return {
    currentDay,
    amount: DAILY_AMOUNTS[currentDay],
    alreadyClaimed,
    streakDays: currentDay,
    nextDay: currentDay < 7 ? currentDay + 1 : 1,
    nextAmount: DAILY_AMOUNTS[currentDay < 7 ? currentDay + 1 : 1],
    allAmounts: DAILY_AMOUNTS,
  };
};

export const claimDailyBonus = async (userId: string) => {
  const today = toDateString(new Date());
  const raw = await redis.get(streakKey(userId));

  let currentDay = 1;
  let lastClaimDate = '';

  if (raw) {
    const data = JSON.parse(raw) as StreakData;
    lastClaimDate = data.lastClaimDate;
    currentDay = data.currentDay;

    if (lastClaimDate === today) {
      throw new AppError('Daily bonus already claimed today', 400);
    }

    if (lastClaimDate) {
      const yesterday = toDateString(new Date(Date.now() - MS_PER_DAY));
      if (lastClaimDate === yesterday) {
        // Consecutive day — increment streak (max 7, then wrap to 1)
        currentDay = currentDay < 7 ? currentDay + 1 : 1;
      } else {
        // Missed a day — reset streak
        currentDay = 1;
      }
    }
  }

  const amount = DAILY_AMOUNTS[currentDay];
  const wageringRequirement = amount * 3;

  await prisma.$transaction(async (tx) => {
    await tx.wallet.update({
      where: { userId },
      data: { bonusBalance: { increment: new Prisma.Decimal(amount) } },
    });

    await tx.bonus.create({
      data: {
        userId,
        bonusType: BonusType.DAILY_LOGIN,
        amount: new Prisma.Decimal(amount),
        wageringRequirement: new Prisma.Decimal(wageringRequirement),
        isClaimed: true,
        claimedAt: new Date(),
      },
    });

    await tx.transaction.create({
      data: {
        userId,
        type: TransactionType.BONUS_CREDIT,
        amount: new Prisma.Decimal(amount),
        status: TransactionStatus.COMPLETED,
        balanceType: 'bonus',
        referenceType: 'daily_bonus',
      },
    });
  });

  // Persist updated streak in Redis
  await redis.set(streakKey(userId), JSON.stringify({ currentDay, lastClaimDate: today }));

  return { day: currentDay, amount, wageringRequirement };
};

// ─── Weekly Bonus ────────────────────────────────────────────────────────────

export const getWeeklyBonus = async (userId: string) => {
  const weekStart = getStartOfWeek();

  const gamesPlayed = await prisma.wager.count({
    where: { userId, createdAt: { gte: weekStart } },
  });

  // Check if already claimed this week
  const claimed = await prisma.bonus.findFirst({
    where: {
      userId,
      bonusType: BonusType.WEEKLY_PLAY,
      createdAt: { gte: weekStart },
    },
  });

  const eligibleTier = WEEKLY_TIERS.find((t) => gamesPlayed >= t.games);

  return {
    gamesPlayed,
    thresholds: [...WEEKLY_TIERS].reverse(), // ascending for display
    eligible: Boolean(eligibleTier) && !claimed,
    claimed: Boolean(claimed),
    eligibleAmount: eligibleTier?.amount ?? 0,
    weekStart: weekStart.toISOString(),
  };
};

export const claimWeeklyBonus = async (userId: string) => {
  const weekStart = getStartOfWeek();

  const gamesPlayed = await prisma.wager.count({
    where: { userId, createdAt: { gte: weekStart } },
  });

  const claimed = await prisma.bonus.findFirst({
    where: { userId, bonusType: BonusType.WEEKLY_PLAY, createdAt: { gte: weekStart } },
  });

  if (claimed) {
    throw new AppError('Weekly bonus already claimed this week', 400);
  }

  const eligibleTier = WEEKLY_TIERS.find((t) => gamesPlayed >= t.games);
  if (!eligibleTier) {
    throw new AppError(
      `Not eligible for weekly bonus. Need at least ${WEEKLY_TIERS[WEEKLY_TIERS.length - 1].games} games, played ${gamesPlayed}`,
      400,
    );
  }

  const amount = eligibleTier.amount;
  const wageringRequirement = amount * 3;

  await prisma.$transaction(async (tx) => {
    await tx.wallet.update({
      where: { userId },
      data: { bonusBalance: { increment: new Prisma.Decimal(amount) } },
    });

    await tx.bonus.create({
      data: {
        userId,
        bonusType: BonusType.WEEKLY_PLAY,
        amount: new Prisma.Decimal(amount),
        wageringRequirement: new Prisma.Decimal(wageringRequirement),
        isClaimed: true,
        claimedAt: new Date(),
      },
    });

    await tx.transaction.create({
      data: {
        userId,
        type: TransactionType.BONUS_CREDIT,
        amount: new Prisma.Decimal(amount),
        status: TransactionStatus.COMPLETED,
        balanceType: 'bonus',
        referenceType: 'weekly_bonus',
      },
    });
  });

  return { gamesPlayed, tier: eligibleTier, amount, wageringRequirement };
};

// ─── Monthly Bonus ───────────────────────────────────────────────────────────

export const getMonthlyBonus = async (userId: string) => {
  const monthStart = getStartOfMonth();
  const monthEnd = getEndOfMonth();

  const result = await prisma.wager.aggregate({
    where: { userId, createdAt: { gte: monthStart, lt: monthEnd } },
    _sum: { entryAmount: true },
  });

  const totalWagered = Number(result._sum.entryAmount ?? 0);

  const claimed = await prisma.bonus.findFirst({
    where: { userId, bonusType: BonusType.MONTHLY_LOYALTY, createdAt: { gte: monthStart } },
  });

  const eligibleTier = MONTHLY_TIERS.find((t) => totalWagered >= t.wagered);

  return {
    totalWageredThisMonth: totalWagered,
    tiers: [...MONTHLY_TIERS].reverse(),
    eligible: Boolean(eligibleTier) && !claimed,
    claimed: Boolean(claimed),
    eligibleAmount: eligibleTier?.bonus ?? 0,
    monthStart: monthStart.toISOString(),
  };
};

export const claimMonthlyBonus = async (userId: string) => {
  const monthStart = getStartOfMonth();
  const monthEnd = getEndOfMonth();

  const claimed = await prisma.bonus.findFirst({
    where: { userId, bonusType: BonusType.MONTHLY_LOYALTY, createdAt: { gte: monthStart } },
  });

  if (claimed) {
    throw new AppError('Monthly bonus already claimed this month', 400);
  }

  const result = await prisma.wager.aggregate({
    where: { userId, createdAt: { gte: monthStart, lt: monthEnd } },
    _sum: { entryAmount: true },
  });

  const totalWagered = Number(result._sum.entryAmount ?? 0);
  const eligibleTier = MONTHLY_TIERS.find((t) => totalWagered >= t.wagered);

  if (!eligibleTier) {
    throw new AppError(
      `Not eligible for monthly bonus. Need at least $${MONTHLY_TIERS[MONTHLY_TIERS.length - 1].wagered} wagered, current: $${totalWagered.toFixed(2)}`,
      400,
    );
  }

  const amount = eligibleTier.bonus;
  const wageringRequirement = amount * 3;

  await prisma.$transaction(async (tx) => {
    await tx.wallet.update({
      where: { userId },
      data: { bonusBalance: { increment: new Prisma.Decimal(amount) } },
    });

    await tx.bonus.create({
      data: {
        userId,
        bonusType: BonusType.MONTHLY_LOYALTY,
        amount: new Prisma.Decimal(amount),
        wageringRequirement: new Prisma.Decimal(wageringRequirement),
        isClaimed: true,
        claimedAt: new Date(),
      },
    });

    await tx.transaction.create({
      data: {
        userId,
        type: TransactionType.BONUS_CREDIT,
        amount: new Prisma.Decimal(amount),
        status: TransactionStatus.COMPLETED,
        balanceType: 'bonus',
        referenceType: 'monthly_bonus',
      },
    });
  });

  return { totalWagered, tier: eligibleTier, amount, wageringRequirement };
};

// ─── Promo Code ──────────────────────────────────────────────────────────────

export const redeemPromoCode = async (userId: string, code: string) => {
  const promoCode = await prisma.promoCode.findUnique({ where: { code } });

  if (!promoCode || !promoCode.isActive) {
    throw new AppError('Invalid or inactive promo code', 400);
  }

  if (promoCode.expiresAt && promoCode.expiresAt < new Date()) {
    throw new AppError('Promo code has expired', 400);
  }

  if (promoCode.maxUses !== null && promoCode.currentUses >= promoCode.maxUses) {
    throw new AppError('Promo code has reached maximum uses', 400);
  }

  // Check if user already used this code (tracked in Redis set)
  const alreadyUsed = await redis.sismember(promoUsedKey(code), userId);
  if (alreadyUsed) {
    throw new AppError('You have already redeemed this promo code', 400);
  }

  const amount = Number(promoCode.bonusAmount);
  const wageringRequirement = amount * 3;

  await prisma.$transaction(async (tx) => {
    await tx.wallet.update({
      where: { userId },
      data: { bonusBalance: { increment: new Prisma.Decimal(amount) } },
    });

    await tx.bonus.create({
      data: {
        userId,
        bonusType: BonusType.PROMO_CODE,
        amount: new Prisma.Decimal(amount),
        wageringRequirement: new Prisma.Decimal(wageringRequirement),
        isClaimed: true,
        claimedAt: new Date(),
      },
    });

    await tx.transaction.create({
      data: {
        userId,
        type: TransactionType.BONUS_CREDIT,
        amount: new Prisma.Decimal(amount),
        status: TransactionStatus.COMPLETED,
        balanceType: 'bonus',
        referenceType: 'promo_code',
        referenceId: promoCode.id,
      },
    });

    await tx.promoCode.update({
      where: { id: promoCode.id },
      data: { currentUses: { increment: 1 } },
    });
  });

  // Mark code as used by this user in Redis
  await redis.sadd(promoUsedKey(code), userId);

  return { code, amount, wageringRequirement, bonusType: promoCode.bonusType };
};

// ─── All Bonuses + History ───────────────────────────────────────────────────

export const getAllBonuses = async (userId: string) => {
  const [daily, weekly, monthly] = await Promise.all([
    getDailyBonus(userId),
    getWeeklyBonus(userId),
    getMonthlyBonus(userId),
  ]);

  return { daily, weekly, monthly };
};

export const getBonusHistory = async (userId: string, filters: GetBonusHistoryQuery) => {
  const { page, limit } = filters;
  const skip = (page - 1) * limit;

  const [total, items] = await Promise.all([
    prisma.bonus.count({ where: { userId } }),
    prisma.bonus.findMany({
      where: { userId },
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
