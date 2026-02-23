import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { prisma } from '../../config/database';
import { redis } from '../../config/redis';
import { env } from '../../config/env';
import { AppError } from '../../middleware/error_handler.middleware';
import type { RegisterInput, LoginInput } from './auth.validation';

const generateReferralCode = (): string => {
  return Math.random().toString(36).substring(2, 8).toUpperCase();
};

const generateTokens = (userId: string, role: string) => {
  const accessToken = jwt.sign({ userId, role }, env.JWT_SECRET, {
    expiresIn: env.JWT_ACCESS_EXPIRES_IN as string,
  } as jwt.SignOptions);

  const refreshToken = jwt.sign({ userId, role }, env.JWT_REFRESH_SECRET, {
    expiresIn: env.JWT_REFRESH_EXPIRES_IN as string,
  } as jwt.SignOptions);

  return { accessToken, refreshToken };
};

export const register = async (data: RegisterInput) => {
  const { username, phone, password, email, referralCode } = data;

  const existingUser = await prisma.user.findFirst({
    where: {
      OR: [{ username }, { phone }],
    },
  });

  if (existingUser) {
    if (existingUser.username === username) {
      throw new AppError('Username already taken', 409);
    }
    throw new AppError('Phone number already registered', 409);
  }

  let referredById: string | undefined;
  if (referralCode) {
    const referrer = await prisma.user.findUnique({ where: { referralCode } });
    if (referrer) {
      referredById = referrer.id;
    }
  }

  const passwordHash = await bcrypt.hash(password, 12);
  const newReferralCode = generateReferralCode();

  const user = await prisma.$transaction(async (tx) => {
    const newUser = await tx.user.create({
      data: {
        username,
        phone,
        email,
        passwordHash,
        referralCode: newReferralCode,
        referredById,
      },
    });

    await tx.wallet.create({
      data: {
        userId: newUser.id,
      },
    });

    if (referredById) {
      await tx.referral.create({
        data: {
          referrerId: referredById,
          referredId: newUser.id,
          status: 'PENDING',
        },
      });
    }

    return newUser;
  });

  const { accessToken, refreshToken } = generateTokens(user.id, user.role);

  // Store refresh token in Redis
  await redis.setex(`refresh:${user.id}`, 7 * 24 * 60 * 60, refreshToken);

  return {
    user: {
      id: user.id,
      username: user.username,
      phone: user.phone,
      email: user.email,
      role: user.role,
      referralCode: user.referralCode,
    },
    accessToken,
    refreshToken,
  };
};

export const login = async (data: LoginInput) => {
  const { identifier, password } = data;

  const user = await prisma.user.findFirst({
    where: {
      OR: [{ username: identifier }, { phone: identifier }],
    },
  });

  if (!user) {
    throw new AppError('Invalid credentials', 401);
  }

  if (user.isBanned) {
    throw new AppError(`Account banned: ${user.banReason || 'Contact support'}`, 403);
  }

  const isPasswordValid = await bcrypt.compare(password, user.passwordHash);
  if (!isPasswordValid) {
    throw new AppError('Invalid credentials', 401);
  }

  const { accessToken, refreshToken } = generateTokens(user.id, user.role);

  await redis.setex(`refresh:${user.id}`, 7 * 24 * 60 * 60, refreshToken);

  await prisma.user.update({
    where: { id: user.id },
    data: { lastLoginAt: new Date() },
  });

  return {
    user: {
      id: user.id,
      username: user.username,
      phone: user.phone,
      email: user.email,
      role: user.role,
      isVerified: user.isVerified,
    },
    accessToken,
    refreshToken,
  };
};

export const sendOtp = async (phone: string): Promise<{ message: string }> => {
  const otp = Math.floor(100000 + Math.random() * 900000).toString();

  // Store OTP in Redis with 5 minute expiry
  await redis.setex(`otp:${phone}`, 300, otp);

  // TODO: Integrate with SMS provider (Twilio, etc.)
  console.log(`OTP for ${phone}: ${otp}`); // placeholder

  return { message: 'OTP sent successfully' };
};

export const verifyOtp = async (phone: string, otp: string): Promise<{ verified: boolean }> => {
  const storedOtp = await redis.get(`otp:${phone}`);

  if (!storedOtp || storedOtp !== otp) {
    throw new AppError('Invalid or expired OTP', 400);
  }

  await redis.del(`otp:${phone}`);

  // Mark phone as verified if user exists
  await prisma.user.updateMany({
    where: { phone },
    data: { isVerified: true },
  });

  return { verified: true };
};

export const refreshTokens = async (refreshToken: string) => {
  let decoded: { userId: string; role: string };
  try {
    decoded = jwt.verify(refreshToken, env.JWT_REFRESH_SECRET) as { userId: string; role: string };
  } catch {
    throw new AppError('Invalid or expired refresh token', 401);
  }

  const storedToken = await redis.get(`refresh:${decoded.userId}`);
  if (!storedToken || storedToken !== refreshToken) {
    throw new AppError('Refresh token not found or already used', 401);
  }

  const user = await prisma.user.findUnique({ where: { id: decoded.userId } });
  if (!user) {
    throw new AppError('User not found', 404);
  }

  const tokens = generateTokens(user.id, user.role);
  await redis.setex(`refresh:${user.id}`, 7 * 24 * 60 * 60, tokens.refreshToken);

  return tokens;
};

export const logout = async (accessToken: string, userId: string): Promise<void> => {
  // Blacklist the access token
  const decoded = jwt.decode(accessToken) as { exp?: number } | null;
  const ttl = decoded?.exp ? decoded.exp - Math.floor(Date.now() / 1000) : 900;
  if (ttl > 0) {
    await redis.setex(`blacklist:${accessToken}`, ttl, '1');
  }

  // Remove refresh token
  await redis.del(`refresh:${userId}`);
};

export const getMe = async (userId: string) => {
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
      lastLoginAt: true,
      createdAt: true,
      wallet: {
        select: {
          mainBalance: true,
          winningBalance: true,
          bonusBalance: true,
          currency: true,
        },
      },
    },
  });

  if (!user) {
    throw new AppError('User not found', 404);
  }

  return user;
};
