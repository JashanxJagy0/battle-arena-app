import { Request, Response, NextFunction } from 'express';
import * as wagerService from './wager.service';

export const getWagers = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await wagerService.getWagers(req.user!.id, req.query as never);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const getWagerById = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await wagerService.getWagerById(req.user!.id, req.params.id);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const getWagerStats = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await wagerService.getWagerStats(req.user!.id);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const getDailyStats = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await wagerService.getDailyStats(req.user!.id);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const getWeeklyStats = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await wagerService.getWeeklyStats(req.user!.id);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const getMonthlyStats = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await wagerService.getMonthlyStats(req.user!.id);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};
