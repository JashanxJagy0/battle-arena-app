import { BonusType, TransactionType, TransactionStatus, Prisma, ReferralStatus } from '@prisma/client';
import { prisma } from '../../config/database';
import { env } from '../../config/env';
import { AppError } from '../../middleware/error_handler.middleware';

const REFERRER_BONUS = 1.0; // $1.00
const REFERRED_BONUS = 0.5; // $0.50

export const getReferralInfo = async (userId: string) => {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { referralCode: true },
  });

  if (!user) {
    throw new AppError('User not found', 404);
  }

  const deepLink = `${env.APP_BASE_URL}/join?ref=${user.referralCode}`;

  return {
    referralCode: user.referralCode,
    deepLink,
    shareText: `Join BattleArena and get a $0.50 bonus! Use my referral code: ${user.referralCode} or click ${deepLink}`,
  };
};

export const getReferralStats = async (userId: string) => {
  const [totalReferrals, totalEarnedResult] = await Promise.all([
    prisma.referral.count({ where: { referrerId: userId } }),
    prisma.referral.aggregate({
      where: { referrerId: userId },
      _sum: { referrerBonus: true },
    }),
  ]);

  return {
    totalReferrals,
    totalEarned: Number(totalEarnedResult._sum.referrerBonus ?? 0),
    referrerBonus: REFERRER_BONUS,
    referredBonus: REFERRED_BONUS,
  };
};

export const getReferralList = async (userId: string, page: number, limit: number) => {
  const skip = (page - 1) * limit;

  const [total, referrals] = await Promise.all([
    prisma.referral.count({ where: { referrerId: userId } }),
    prisma.referral.findMany({
      where: { referrerId: userId },
      orderBy: { createdAt: 'desc' },
      skip,
      take: limit,
      include: {
        referred: {
          select: { id: true, username: true, createdAt: true, isBanned: true },
        },
      },
    }),
  ]);

  const items = referrals.map((r) => ({
    id: r.id,
    userId: r.referredId,
    username: r.referred.username,
    joinedAt: r.referred.createdAt,
    status: r.status,
    bonusEarned: Number(r.referrerBonus ?? 0),
    isActive: !r.referred.isBanned,
  }));

  return {
    total,
    page,
    limit,
    totalPages: Math.ceil(total / limit),
    items,
  };
};

export const processReferral = async (referrerId: string, newUserId: string) => {
  // Verify both users exist
  const [referrer, referred] = await Promise.all([
    prisma.user.findUnique({ where: { id: referrerId }, select: { id: true } }),
    prisma.user.findUnique({ where: { id: newUserId }, select: { id: true } }),
  ]);

  if (!referrer || !referred) {
    throw new AppError('Invalid referral: user not found', 404);
  }

  // Check if referral already exists for the referred user
  const existing = await prisma.referral.findUnique({ where: { referredId: newUserId } });
  if (existing) {
    throw new AppError('Referral already processed for this user', 400);
  }

  await prisma.$transaction(async (tx) => {
    // Create referral record
    await tx.referral.create({
      data: {
        referrerId,
        referredId: newUserId,
        referrerBonus: new Prisma.Decimal(REFERRER_BONUS),
        referredBonus: new Prisma.Decimal(REFERRED_BONUS),
        status: ReferralStatus.COMPLETED,
      },
    });

    // Credit referrer
    await tx.wallet.update({
      where: { userId: referrerId },
      data: { bonusBalance: { increment: new Prisma.Decimal(REFERRER_BONUS) } },
    });

    await tx.bonus.create({
      data: {
        userId: referrerId,
        bonusType: BonusType.REFERRAL,
        amount: new Prisma.Decimal(REFERRER_BONUS),
        wageringRequirement: new Prisma.Decimal(REFERRER_BONUS * 3),
        isClaimed: true,
        claimedAt: new Date(),
      },
    });

    await tx.transaction.create({
      data: {
        userId: referrerId,
        type: TransactionType.REFERRAL_BONUS,
        amount: new Prisma.Decimal(REFERRER_BONUS),
        status: TransactionStatus.COMPLETED,
        balanceType: 'bonus',
        referenceType: 'referral',
        referenceId: newUserId,
      },
    });

    // Credit referred user
    await tx.wallet.update({
      where: { userId: newUserId },
      data: { bonusBalance: { increment: new Prisma.Decimal(REFERRED_BONUS) } },
    });

    await tx.bonus.create({
      data: {
        userId: newUserId,
        bonusType: BonusType.REFERRAL,
        amount: new Prisma.Decimal(REFERRED_BONUS),
        wageringRequirement: new Prisma.Decimal(REFERRED_BONUS * 3),
        isClaimed: true,
        claimedAt: new Date(),
      },
    });

    await tx.transaction.create({
      data: {
        userId: newUserId,
        type: TransactionType.REFERRAL_BONUS,
        amount: new Prisma.Decimal(REFERRED_BONUS),
        status: TransactionStatus.COMPLETED,
        balanceType: 'bonus',
        referenceType: 'referral',
        referenceId: referrerId,
      },
    });
  });
};
