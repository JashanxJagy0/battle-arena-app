import { z } from 'zod';
import { GameType, WagerStatus } from '@prisma/client';

export const getWagersQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  gameType: z.nativeEnum(GameType).optional(),
  status: z.nativeEnum(WagerStatus).optional(),
  dateFrom: z.string().optional(),
  dateTo: z.string().optional(),
});

export type GetWagersQuery = z.infer<typeof getWagersQuerySchema>;
