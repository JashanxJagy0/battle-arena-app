import { z } from 'zod';

export const getNotificationsQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

export const registerFcmTokenSchema = z.object({
  token: z.string().min(1, 'FCM token is required'),
});

export type GetNotificationsQuery = z.infer<typeof getNotificationsQuerySchema>;
export type RegisterFcmTokenInput = z.infer<typeof registerFcmTokenSchema>;
