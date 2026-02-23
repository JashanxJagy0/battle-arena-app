import crypto from 'crypto';
import axios from 'axios';
import { prisma } from '../../config/database';
import { redis } from '../../config/redis';
import { env } from '../../config/env';
import { AppError } from '../../middleware/error_handler.middleware';
import type { GetNotificationsQuery } from './notification.validation';

const FCM_TOKEN_KEY = (userId: string) => `fcm_tokens:${userId}`;

// ─── FCM helpers (no additional npm packages required) ───────────────────────

async function getGoogleAccessToken(): Promise<string | null> {
  if (!env.FIREBASE_CLIENT_EMAIL || !env.FIREBASE_PRIVATE_KEY || !env.FIREBASE_PROJECT_ID) {
    return null;
  }

  const now = Math.floor(Date.now() / 1000);
  const header = Buffer.from(JSON.stringify({ alg: 'RS256', typ: 'JWT' })).toString('base64url');
  const payload = Buffer.from(
    JSON.stringify({
      iss: env.FIREBASE_CLIENT_EMAIL,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
      iat: now,
      exp: now + 3600,
    }),
  ).toString('base64url');

  const signingInput = `${header}.${payload}`;
  const privateKey = env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n');

  let signature: string;
  try {
    const sign = crypto.createSign('RSA-SHA256');
    sign.update(signingInput);
    signature = sign.sign(privateKey).toString('base64url');
  } catch {
    return null;
  }

  const jwt = `${signingInput}.${signature}`;

  try {
    const response = await axios.post<{ access_token: string }>(
      'https://oauth2.googleapis.com/token',
      `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${jwt}`,
      { headers: { 'Content-Type': 'application/x-www-form-urlencoded' } },
    );
    return response.data.access_token;
  } catch {
    return null;
  }
}

// ─── Notification CRUD ───────────────────────────────────────────────────────

export const getNotifications = async (userId: string, filters: GetNotificationsQuery) => {
  const { page, limit } = filters;
  const skip = (page - 1) * limit;

  const [total, unreadCount, items] = await Promise.all([
    prisma.notification.count({ where: { userId } }),
    prisma.notification.count({ where: { userId, isRead: false } }),
    prisma.notification.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      skip,
      take: limit,
    }),
  ]);

  return {
    total,
    unreadCount,
    page,
    limit,
    totalPages: Math.ceil(total / limit),
    items,
  };
};

export const createNotification = async (
  userId: string,
  data: { title: string; body: string; type: string; referenceType?: string; referenceId?: string },
) => {
  return prisma.notification.create({
    data: {
      userId,
      title: data.title,
      body: data.body,
      type: data.type,
      referenceType: data.referenceType,
      referenceId: data.referenceId,
    },
  });
};

export const markAsRead = async (userId: string, notificationId: string) => {
  const notification = await prisma.notification.findFirst({
    where: { id: notificationId, userId },
  });

  if (!notification) {
    throw new AppError('Notification not found', 404);
  }

  return prisma.notification.update({
    where: { id: notificationId },
    data: { isRead: true },
  });
};

export const markAllAsRead = async (userId: string) => {
  const result = await prisma.notification.updateMany({
    where: { userId, isRead: false },
    data: { isRead: true },
  });
  return { updatedCount: result.count };
};

export const deleteNotification = async (userId: string, notificationId: string) => {
  const notification = await prisma.notification.findFirst({
    where: { id: notificationId, userId },
  });

  if (!notification) {
    throw new AppError('Notification not found', 404);
  }

  await prisma.notification.delete({ where: { id: notificationId } });
};

// ─── FCM Token ───────────────────────────────────────────────────────────────

export const registerFcmToken = async (userId: string, token: string) => {
  await redis.sadd(FCM_TOKEN_KEY(userId), token);
  return { registered: true };
};

// ─── Push Notifications ──────────────────────────────────────────────────────

export const sendPushNotification = async (
  userId: string,
  payload: { title: string; body: string; data?: Record<string, string> },
) => {
  if (!env.FIREBASE_PROJECT_ID) {
    return { sent: false, reason: 'FCM not configured' };
  }

  const tokens = await redis.smembers(FCM_TOKEN_KEY(userId));
  if (tokens.length === 0) {
    return { sent: false, reason: 'No FCM tokens registered for user' };
  }

  const accessToken = await getGoogleAccessToken();
  if (!accessToken) {
    return { sent: false, reason: 'Could not obtain Google access token' };
  }

  const fcmUrl = `https://fcm.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/messages:send`;

  const results = await Promise.allSettled(
    tokens.map((token) =>
      axios.post(
        fcmUrl,
        {
          message: {
            token,
            notification: { title: payload.title, body: payload.body },
            data: payload.data ?? {},
          },
        },
        { headers: { Authorization: `Bearer ${accessToken}`, 'Content-Type': 'application/json' } },
      ),
    ),
  );

  const sent = results.filter((r) => r.status === 'fulfilled').length;
  const failed = results.length - sent;

  return { sent: sent > 0, tokenCount: tokens.length, successCount: sent, failedCount: failed };
};
