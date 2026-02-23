import { prisma } from '../../config/database';
import { AppError } from '../../middleware/error_handler.middleware';

export const getProfile = async (userId: string) => {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: {
      id: true,
      username: true,
      email: true,
      phone: true,
      avatarUrl: true,
      freeFireUid: true,
      freeFireIgn: true,
      referralCode: true,
      isVerified: true,
      role: true,
      level: true,
      xp: true,
      totalGamesPlayed: true,
      totalWins: true,
      totalLosses: true,
      winRate: true,
      createdAt: true,
    },
  });

  if (!user) throw new AppError('User not found', 404);
  return user;
};

export const updateProfile = async (
  userId: string,
  data: { username?: string; email?: string; avatarUrl?: string }
) => {
  if (data.username) {
    const existing = await prisma.user.findFirst({
      where: { username: data.username, NOT: { id: userId } },
    });
    if (existing) throw new AppError('Username already taken', 409);
  }

  const user = await prisma.user.update({
    where: { id: userId },
    data,
    select: {
      id: true,
      username: true,
      email: true,
      avatarUrl: true,
      updatedAt: true,
    },
  });

  return user;
};

export const linkFreeFireAccount = async (
  userId: string,
  data: { freeFireUid: string; freeFireIgn: string }
) => {
  const existing = await prisma.user.findFirst({
    where: { freeFireUid: data.freeFireUid, NOT: { id: userId } },
  });

  if (existing) throw new AppError('This Free Fire account is already linked to another user', 409);

  const user = await prisma.user.update({
    where: { id: userId },
    data: { freeFireUid: data.freeFireUid, freeFireIgn: data.freeFireIgn },
    select: {
      id: true,
      freeFireUid: true,
      freeFireIgn: true,
      updatedAt: true,
    },
  });

  return user;
};

export const getStats = async (userId: string) => {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: {
      totalGamesPlayed: true,
      totalWins: true,
      totalLosses: true,
      winRate: true,
      level: true,
      xp: true,
    },
  });

  if (!user) throw new AppError('User not found', 404);

  const wagerStats = await prisma.wager.groupBy({
    by: ['status'],
    where: { userId },
    _count: { _all: true },
    _sum: { entryAmount: true, actualWin: true },
  });

  return { ...user, wagerStats };
};
