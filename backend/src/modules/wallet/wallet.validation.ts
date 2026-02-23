import { z } from 'zod';
import { TransactionType, TransactionStatus } from '@prisma/client';

export const createDepositSchema = z.object({
  currency: z.string().min(1, 'Currency is required'),
  network: z.string().min(1, 'Network is required'),
  amountUsd: z.number().min(1, 'Minimum deposit is $1'),
});

export const requestWithdrawalSchema = z.object({
  amountUsd: z.number().min(5, 'Minimum withdrawal is $5'),
  currency: z.string().min(1, 'Currency is required'),
  network: z.string().min(1, 'Network is required'),
  walletAddress: z.string().min(1, 'Wallet address is required'),
});

export const getTransactionsQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  type: z.nativeEnum(TransactionType).optional(),
  status: z.nativeEnum(TransactionStatus).optional(),
  dateFrom: z.string().optional(),
  dateTo: z.string().optional(),
});

export type CreateDepositInput = z.infer<typeof createDepositSchema>;
export type RequestWithdrawalInput = z.infer<typeof requestWithdrawalSchema>;
export type GetTransactionsQuery = z.infer<typeof getTransactionsQuerySchema>;
