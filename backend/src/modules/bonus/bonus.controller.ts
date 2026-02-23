import { Request, Response, NextFunction } from 'express';
import * as bonusService from './bonus.service';

export const getAllBonuses = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await bonusService.getAllBonuses(req.user!.id);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const getDailyBonus = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await bonusService.getDailyBonus(req.user!.id);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const claimDailyBonus = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await bonusService.claimDailyBonus(req.user!.id);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const getWeeklyBonus = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await bonusService.getWeeklyBonus(req.user!.id);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const claimWeeklyBonus = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await bonusService.claimWeeklyBonus(req.user!.id);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const getMonthlyBonus = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await bonusService.getMonthlyBonus(req.user!.id);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const claimMonthlyBonus = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await bonusService.claimMonthlyBonus(req.user!.id);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const redeemPromoCode = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { code } = req.body as { code: string };
    const data = await bonusService.redeemPromoCode(req.user!.id, code);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const getBonusHistory = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await bonusService.getBonusHistory(req.user!.id, req.query as never);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};
