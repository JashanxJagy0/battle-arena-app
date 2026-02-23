import { z } from 'zod';

export const createMatchSchema = z.object({
  gameMode: z.enum(['ONE_V_ONE', 'TWO_V_TWO', 'FOUR_PLAYER']),
  entryFee: z.number().min(0, 'Entry fee must be non-negative'),
});

export const getLobbySchema = z.object({
  gameMode: z.enum(['ONE_V_ONE', 'TWO_V_TWO', 'FOUR_PLAYER']).optional(),
  entryFeeMin: z.coerce.number().min(0).optional(),
  entryFeeMax: z.coerce.number().min(0).optional(),
});

export const myMatchesSchema = z.object({
  page: z.coerce.number().min(1).default(1),
  limit: z.coerce.number().min(1).max(50).default(10),
});

export const disputeSchema = z.object({
  reason: z.string().min(10, 'Reason must be at least 10 characters'),
  evidenceUrls: z.array(z.string().url()).optional().default([]),
});

export type CreateMatchInput = z.infer<typeof createMatchSchema>;
export type GetLobbyInput = z.infer<typeof getLobbySchema>;
export type MyMatchesInput = z.infer<typeof myMatchesSchema>;
export type DisputeInput = z.infer<typeof disputeSchema>;
