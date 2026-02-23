import { z } from 'zod';
import {
  Role,
  TransactionType,
  TransactionStatus,
  TournamentGameMode,
  TournamentType,
  TournamentStatus,
  BonusType,
  BonusFrequency,
  DisputeStatus,
  GameType,
} from '@prisma/client';

// ─── Pagination ──────────────────────────────────────────────────────────────

export const paginationSchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

// ─── Dashboard ───────────────────────────────────────────────────────────────

export const periodSchema = z.object({
  period: z.enum(['7d', '30d', '90d', '1y']).default('7d'),
});

// ─── User Management ─────────────────────────────────────────────────────────

export const listUsersQuerySchema = paginationSchema.extend({
  search: z.string().optional(),
  role: z.nativeEnum(Role).optional(),
  isBanned: z.coerce.boolean().optional(),
});

export const updateUserSchema = z.object({
  username: z.string().min(3).max(30).optional(),
  email: z.string().email().optional().nullable(),
  role: z.nativeEnum(Role).optional(),
  level: z.number().int().min(1).optional(),
  xp: z.number().int().min(0).optional(),
  isVerified: z.boolean().optional(),
});

export const banUserSchema = z.object({
  reason: z.string().min(1, 'Ban reason is required'),
});

export const creditDebitSchema = z.object({
  amount: z.number().positive('Amount must be positive'),
  balanceType: z.enum(['main', 'winning', 'bonus']),
  note: z.string().optional(),
});

// ─── Tournament Management ───────────────────────────────────────────────────

export const createTournamentAdminSchema = z.object({
  title: z.string().min(3).max(100),
  description: z.string().optional(),
  game: z.string().min(1),
  gameMode: z.nativeEnum(TournamentGameMode),
  tournamentType: z.nativeEnum(TournamentType),
  mapName: z.string().optional(),
  entryFee: z.number().min(0),
  prizePool: z.number().min(0),
  maxParticipants: z.number().int().min(2),
  minParticipants: z.number().int().min(2).optional(),
  perKillPrize: z.number().min(0).optional(),
  prizeDistribution: z.record(z.number()).optional(),
  registrationStart: z.string().datetime().optional(),
  registrationEnd: z.string().datetime().optional(),
  matchStart: z.string().datetime().optional(),
  matchEnd: z.string().datetime().optional(),
  rules: z.string().optional(),
  bannerImageUrl: z.string().url().optional(),
});

export const updateTournamentAdminSchema = createTournamentAdminSchema.partial();

export const setRoomSchema = z.object({
  roomId: z.string().min(1, 'Room ID is required'),
  roomPassword: z.string().optional(),
});

export const publishResultsSchema = z.object({
  results: z.array(
    z.object({
      userId: z.string().uuid(),
      kills: z.number().int().min(0),
      placement: z.number().int().min(1),
    })
  ),
});

export const updateTournamentStatusSchema = z.object({
  status: z.nativeEnum(TournamentStatus),
});

// ─── Ludo Management ─────────────────────────────────────────────────────────

export const listLudoMatchesQuerySchema = paginationSchema.extend({
  status: z.string().optional(),
});

export const resolveLudoMatchSchema = z.object({
  winnerId: z.string().uuid(),
  reason: z.string().min(1, 'Reason is required'),
});

// ─── Financial ───────────────────────────────────────────────────────────────

export const listTransactionsQuerySchema = paginationSchema.extend({
  type: z.nativeEnum(TransactionType).optional(),
  status: z.nativeEnum(TransactionStatus).optional(),
  userId: z.string().optional(),
  dateFrom: z.string().optional(),
  dateTo: z.string().optional(),
});

export const rejectWithdrawalSchema = z.object({
  reason: z.string().min(1, 'Rejection reason is required'),
});

// ─── Bonus Management ────────────────────────────────────────────────────────

export const createBonusScheduleSchema = z.object({
  bonusType: z.nativeEnum(BonusType),
  frequency: z.nativeEnum(BonusFrequency),
  baseAmount: z.number().positive(),
  multiplierRules: z.record(z.unknown()).optional(),
  minGamesRequired: z.number().int().min(0).optional(),
  minDepositRequired: z.number().min(0).optional(),
  isActive: z.boolean().optional(),
});

export const updateBonusScheduleSchema = createBonusScheduleSchema.partial();

export const sendBulkBonusSchema = z.object({
  userIds: z.array(z.string().uuid()).min(1),
  amount: z.number().positive(),
  bonusType: z.nativeEnum(BonusType),
  note: z.string().optional(),
});

export const createPromoCodeSchema = z.object({
  code: z.string().min(3).max(20).toUpperCase(),
  bonusType: z.nativeEnum(BonusType),
  bonusAmount: z.number().positive(),
  maxUses: z.number().int().positive().optional(),
  minDeposit: z.number().min(0).optional(),
  expiresAt: z.string().datetime().optional(),
});

// ─── Disputes ────────────────────────────────────────────────────────────────

export const listDisputesQuerySchema = paginationSchema.extend({
  status: z.nativeEnum(DisputeStatus).optional(),
  gameType: z.nativeEnum(GameType).optional(),
});

export const resolveDisputeSchema = z.object({
  status: z.enum([DisputeStatus.RESOLVED, DisputeStatus.REJECTED]),
  adminResponse: z.string().min(1, 'Admin response is required'),
  refundAmount: z.number().min(0).optional(),
});

// ─── Settings ────────────────────────────────────────────────────────────────

export const updateSettingSchema = z.object({
  value: z.unknown(),
});

// ─── Audit Logs ──────────────────────────────────────────────────────────────

export const listAuditLogsQuerySchema = paginationSchema.extend({
  adminId: z.string().optional(),
  action: z.string().optional(),
  entityType: z.string().optional(),
  dateFrom: z.string().optional(),
  dateTo: z.string().optional(),
});

// ─── Exported types ──────────────────────────────────────────────────────────

export type ListUsersQuery = z.infer<typeof listUsersQuerySchema>;
export type UpdateUserInput = z.infer<typeof updateUserSchema>;
export type BanUserInput = z.infer<typeof banUserSchema>;
export type CreditDebitInput = z.infer<typeof creditDebitSchema>;
export type CreateTournamentAdminInput = z.infer<typeof createTournamentAdminSchema>;
export type UpdateTournamentAdminInput = z.infer<typeof updateTournamentAdminSchema>;
export type SetRoomInput = z.infer<typeof setRoomSchema>;
export type PublishResultsInput = z.infer<typeof publishResultsSchema>;
export type UpdateTournamentStatusInput = z.infer<typeof updateTournamentStatusSchema>;
export type ListLudoMatchesQuery = z.infer<typeof listLudoMatchesQuerySchema>;
export type ResolveLudoMatchInput = z.infer<typeof resolveLudoMatchSchema>;
export type ListTransactionsQuery = z.infer<typeof listTransactionsQuerySchema>;
export type RejectWithdrawalInput = z.infer<typeof rejectWithdrawalSchema>;
export type CreateBonusScheduleInput = z.infer<typeof createBonusScheduleSchema>;
export type UpdateBonusScheduleInput = z.infer<typeof updateBonusScheduleSchema>;
export type SendBulkBonusInput = z.infer<typeof sendBulkBonusSchema>;
export type CreatePromoCodeInput = z.infer<typeof createPromoCodeSchema>;
export type ListDisputesQuery = z.infer<typeof listDisputesQuerySchema>;
export type ResolveDisputeInput = z.infer<typeof resolveDisputeSchema>;
export type UpdateSettingInput = z.infer<typeof updateSettingSchema>;
export type ListAuditLogsQuery = z.infer<typeof listAuditLogsQuerySchema>;
export type PeriodQuery = z.infer<typeof periodSchema>;
