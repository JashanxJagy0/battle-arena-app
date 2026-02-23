import { Request, Response, NextFunction } from 'express';
import * as referralService from './referral.service';

export const getReferralInfo = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await referralService.getReferralInfo(req.user!.id);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const getReferralStats = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await referralService.getReferralStats(req.user!.id);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const getReferralList = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const page = Math.max(1, parseInt(String(req.query.page ?? '1'), 10));
    const limit = Math.min(100, Math.max(1, parseInt(String(req.query.limit ?? '20'), 10)));
    const data = await referralService.getReferralList(req.user!.id, page, limit);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};
