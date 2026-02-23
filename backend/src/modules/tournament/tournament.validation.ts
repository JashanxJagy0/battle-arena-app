import { z } from 'zod';
import { TournamentGameMode, TournamentType, TournamentStatus } from '@prisma/client';

export const createTournamentSchema = z.object({
  title: z.string().min(3, 'Title must be at least 3 characters'),
  description: z.string().optional(),
  game: z.string().min(1, 'Game is required'),
  gameMode: z.nativeEnum(TournamentGameMode),
  tournamentType: z.nativeEnum(TournamentType),
  mapName: z.string().optional(),
  entryFee: z.number().min(0, 'Entry fee must be non-negative'),
  prizePool: z.number().min(0, 'Prize pool must be non-negative'),
  platformFee: z.number().min(0).default(0),
  maxParticipants: z.number().int().min(2, 'Must have at least 2 participants'),
  minParticipants: z.number().int().min(2).default(2),
  perKillPrize: z.number().min(0).optional(),
  prizeDistribution: z.record(z.string(), z.number()).optional(),
  roomVisibleAt: z.string().datetime().optional(),
  registrationStart: z.string().datetime().optional(),
  registrationEnd: z.string().datetime().optional(),
  matchStart: z.string().datetime().optional(),
  matchEnd: z.string().datetime().optional(),
  rules: z.string().optional(),
  bannerImageUrl: z.string().url().optional(),
});

export const updateTournamentSchema = createTournamentSchema.partial();

export const listTournamentsQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  status: z.nativeEnum(TournamentStatus).optional(),
  gameMode: z.nativeEnum(TournamentGameMode).optional(),
  entryFeeMin: z.coerce.number().min(0).optional(),
  entryFeeMax: z.coerce.number().min(0).optional(),
  dateFrom: z.string().optional(),
  dateTo: z.string().optional(),
});

export const submitResultSchema = z.object({
  kills: z.number().int().min(0, 'Kills must be non-negative'),
  placement: z.number().int().min(1, 'Placement must be at least 1'),
  screenshotUrl: z.string().url('Must be a valid URL'),
});

export const disputeSchema = z.object({
  reason: z.string().min(10, 'Reason must be at least 10 characters'),
  evidenceUrls: z.array(z.string().url()).optional().default([]),
});

export const publishResultsSchema = z.object({
  results: z
    .array(
      z.object({
        userId: z.string().uuid(),
        kills: z.number().int().min(0),
        placement: z.number().int().min(1),
      }),
    )
    .min(1, 'Results must have at least one entry'),
});

export const setRoomSchema = z.object({
  roomId: z.string().min(1, 'Room ID is required'),
  roomPassword: z.string().min(1, 'Room password is required'),
});

export const updateStatusSchema = z.object({
  status: z.nativeEnum(TournamentStatus),
});

export type CreateTournamentInput = z.infer<typeof createTournamentSchema>;
export type UpdateTournamentInput = z.infer<typeof updateTournamentSchema>;
export type ListTournamentsQuery = z.infer<typeof listTournamentsQuerySchema>;
export type SubmitResultInput = z.infer<typeof submitResultSchema>;
export type DisputeInput = z.infer<typeof disputeSchema>;
export type PublishResultsInput = z.infer<typeof publishResultsSchema>;
export type SetRoomInput = z.infer<typeof setRoomSchema>;
export type UpdateStatusInput = z.infer<typeof updateStatusSchema>;
