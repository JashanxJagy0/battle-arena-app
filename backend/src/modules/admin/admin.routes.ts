import { Router } from 'express';
import * as adminController from './admin.controller';
import { validate } from '../../middleware/validation.middleware';
import { authenticate } from '../../middleware/auth.middleware';
import { requireAdmin } from '../../middleware/admin.middleware';
import {
  periodSchema,
  listUsersQuerySchema,
  updateUserSchema,
  banUserSchema,
  creditDebitSchema,
  createTournamentAdminSchema,
  updateTournamentAdminSchema,
  setRoomSchema,
  publishResultsSchema,
  updateTournamentStatusSchema,
  listLudoMatchesQuerySchema,
  resolveLudoMatchSchema,
  listTransactionsQuerySchema,
  rejectWithdrawalSchema,
  createBonusScheduleSchema,
  updateBonusScheduleSchema,
  sendBulkBonusSchema,
  createPromoCodeSchema,
  listDisputesQuerySchema,
  resolveDisputeSchema,
  updateSettingSchema,
  listAuditLogsQuerySchema,
} from './admin.validation';

const router = Router();

router.use(authenticate, requireAdmin);

// ─── Dashboard ───────────────────────────────────────────────────────────────
router.get('/dashboard/stats', adminController.getDashboardStats);
router.get('/dashboard/revenue', validate(periodSchema, 'query'), adminController.getDashboardRevenue);
router.get('/dashboard/charts', validate(periodSchema, 'query'), adminController.getDashboardCharts);

// ─── User Management ─────────────────────────────────────────────────────────
router.get('/users', validate(listUsersQuerySchema, 'query'), adminController.listUsers);
router.get('/users/:id', adminController.getUserDetails);
router.put('/users/:id', validate(updateUserSchema), adminController.updateUser);
router.put('/users/:id/ban', validate(banUserSchema), adminController.banUser);
router.put('/users/:id/unban', adminController.unbanUser);
router.post('/users/:id/credit', validate(creditDebitSchema), adminController.creditUser);
router.post('/users/:id/debit', validate(creditDebitSchema), adminController.debitUser);

// ─── Tournament Management ────────────────────────────────────────────────────
router.post('/tournaments', validate(createTournamentAdminSchema), adminController.createTournament);
router.put('/tournaments/:id', validate(updateTournamentAdminSchema), adminController.updateTournament);
router.delete('/tournaments/:id', adminController.cancelTournament);
router.put('/tournaments/:id/room', validate(setRoomSchema), adminController.setTournamentRoom);
router.put('/tournaments/:id/results', validate(publishResultsSchema), adminController.publishTournamentResults);
router.put('/tournaments/:id/status', validate(updateTournamentStatusSchema), adminController.updateTournamentStatus);

// ─── Ludo Management ─────────────────────────────────────────────────────────
router.get('/ludo/matches', validate(listLudoMatchesQuerySchema, 'query'), adminController.listLudoMatches);
router.get('/ludo/matches/:id', adminController.getLudoMatchDetails);
router.put('/ludo/matches/:id/resolve', validate(resolveLudoMatchSchema), adminController.resolveLudoMatch);

// ─── Financial ───────────────────────────────────────────────────────────────
router.get('/transactions', validate(listTransactionsQuerySchema, 'query'), adminController.listTransactions);
router.get('/withdrawals/pending', adminController.listPendingWithdrawals);
router.put('/withdrawals/:id/approve', adminController.approveWithdrawal);
router.put('/withdrawals/:id/reject', validate(rejectWithdrawalSchema), adminController.rejectWithdrawal);

// ─── Bonus Management ────────────────────────────────────────────────────────
router.get('/bonus-schedules', adminController.listBonusSchedules);
router.post('/bonus-schedules', validate(createBonusScheduleSchema), adminController.createBonusSchedule);
router.put('/bonus-schedules/:id', validate(updateBonusScheduleSchema), adminController.updateBonusSchedule);
router.post('/bonus/send-bulk', validate(sendBulkBonusSchema), adminController.sendBulkBonus);
router.post('/promo-codes', validate(createPromoCodeSchema), adminController.createPromoCode);
router.get('/promo-codes', adminController.listPromoCodes);

// ─── Disputes ────────────────────────────────────────────────────────────────
router.get('/disputes', validate(listDisputesQuerySchema, 'query'), adminController.listDisputes);
router.put('/disputes/:id/resolve', validate(resolveDisputeSchema), adminController.resolveDispute);

// ─── Settings ────────────────────────────────────────────────────────────────
router.get('/settings', adminController.getSettings);
router.put('/settings/:key', validate(updateSettingSchema), adminController.updateSetting);

// ─── Audit Logs ──────────────────────────────────────────────────────────────
router.get('/audit-logs', validate(listAuditLogsQuerySchema, 'query'), adminController.listAuditLogs);

export default router;
