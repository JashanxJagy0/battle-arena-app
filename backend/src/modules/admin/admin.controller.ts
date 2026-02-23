import { Request, Response, NextFunction } from 'express';
import * as adminService from './admin.service';

// ─── Dashboard ───────────────────────────────────────────────────────────────

export const getDashboardStats = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await adminService.getDashboardStats();
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const getDashboardRevenue = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await adminService.getDashboardRevenue(req.query as never);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const getDashboardCharts = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await adminService.getDashboardCharts(req.query as never);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

// ─── User Management ─────────────────────────────────────────────────────────

export const listUsers = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await adminService.listUsers(req.query as never);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const getUserDetails = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await adminService.getUserDetails(req.params.id);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const updateUser = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await adminService.updateUser(req.user!.id, req.params.id, req.body, req.ip);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const banUser = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await adminService.banUser(req.user!.id, req.params.id, req.body, req.ip);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const unbanUser = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await adminService.unbanUser(req.user!.id, req.params.id, req.ip);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const creditUser = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await adminService.creditUser(req.user!.id, req.params.id, req.body, req.ip);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const debitUser = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await adminService.debitUser(req.user!.id, req.params.id, req.body, req.ip);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

// ─── Tournament Management ───────────────────────────────────────────────────

export const createTournament = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await adminService.createTournament(req.user!.id, req.body, req.ip);
    res.status(201).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const updateTournament = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await adminService.updateTournament(req.user!.id, req.params.id, req.body, req.ip);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const cancelTournament = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await adminService.cancelTournament(req.user!.id, req.params.id, req.ip);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const setTournamentRoom = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await adminService.setTournamentRoom(req.user!.id, req.params.id, req.body, req.ip);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const publishTournamentResults = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await adminService.publishTournamentResults(req.user!.id, req.params.id, req.body, req.ip);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const updateTournamentStatus = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await adminService.updateTournamentStatus(req.user!.id, req.params.id, req.body, req.ip);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

// ─── Ludo Management ─────────────────────────────────────────────────────────

export const listLudoMatches = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await adminService.listLudoMatches(req.query as never);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const getLudoMatchDetails = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await adminService.getLudoMatchDetails(req.params.id);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const resolveLudoMatch = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await adminService.resolveLudoMatch(req.user!.id, req.params.id, req.body, req.ip);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

// ─── Financial ───────────────────────────────────────────────────────────────

export const listTransactions = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await adminService.listTransactions(req.query as never);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const listPendingWithdrawals = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await adminService.listPendingWithdrawals();
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const approveWithdrawal = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await adminService.approveWithdrawal(req.user!.id, req.params.id, req.ip);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const rejectWithdrawal = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await adminService.rejectWithdrawal(req.user!.id, req.params.id, req.body, req.ip);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

// ─── Bonus Management ────────────────────────────────────────────────────────

export const listBonusSchedules = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await adminService.listBonusSchedules();
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const createBonusSchedule = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await adminService.createBonusSchedule(req.user!.id, req.body, req.ip);
    res.status(201).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const updateBonusSchedule = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await adminService.updateBonusSchedule(req.user!.id, req.params.id, req.body, req.ip);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const sendBulkBonus = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await adminService.sendBulkBonus(req.user!.id, req.body, req.ip);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const createPromoCode = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await adminService.createPromoCode(req.user!.id, req.body, req.ip);
    res.status(201).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const listPromoCodes = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await adminService.listPromoCodes();
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

// ─── Disputes ────────────────────────────────────────────────────────────────

export const listDisputes = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await adminService.listDisputes(req.query as never);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const resolveDispute = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await adminService.resolveDispute(req.user!.id, req.params.id, req.body, req.ip);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

// ─── Settings ────────────────────────────────────────────────────────────────

export const getSettings = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await adminService.getSettings();
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const updateSetting = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await adminService.updateSetting(req.user!.id, req.params.key, req.body.value, req.ip);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

// ─── Audit Logs ──────────────────────────────────────────────────────────────

export const listAuditLogs = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await adminService.listAuditLogs(req.query as never);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};
