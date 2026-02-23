import { z } from 'zod';

export const redeemPromoCodeSchema = z.object({
  code: z.string().min(1, 'Promo code is required').toUpperCase(),
});

export const getBonusHistoryQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

export type RedeemPromoCodeInput = z.infer<typeof redeemPromoCodeSchema>;
export type GetBonusHistoryQuery = z.infer<typeof getBonusHistoryQuerySchema>;
