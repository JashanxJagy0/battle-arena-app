import { Request, Response, NextFunction } from 'express';
import * as leaderboardService from './leaderboard.service';

type Period = 'daily' | 'weekly' | 'monthly' | 'alltime';

const VALID_GAME_PERIODS: Period[] = ['daily', 'weekly', 'monthly', 'alltime'];
const VALID_EARNINGS_PERIODS: Period[] = ['weekly', 'monthly', 'alltime'];

export const getLudoLeaderboard = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const period = (req.query.period as Period) || 'alltime';
    if (!VALID_GAME_PERIODS.includes(period)) {
      res.status(400).json({ success: false, message: `Invalid period. Must be one of: ${VALID_GAME_PERIODS.join(', ')}` });
      return;
    }
    const data = await leaderboardService.getLudoLeaderboard(period, req.user!.id);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const getFreeFireLeaderboard = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const period = (req.query.period as Period) || 'alltime';
    if (!VALID_GAME_PERIODS.includes(period)) {
      res.status(400).json({ success: false, message: `Invalid period. Must be one of: ${VALID_GAME_PERIODS.join(', ')}` });
      return;
    }
    const data = await leaderboardService.getFreeFireLeaderboard(period, req.user!.id);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const getEarningsLeaderboard = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const period = (req.query.period as Period) || 'alltime';
    if (!VALID_EARNINGS_PERIODS.includes(period)) {
      res.status(400).json({ success: false, message: `Invalid period. Must be one of: ${VALID_EARNINGS_PERIODS.join(', ')}` });
      return;
    }
    const data = await leaderboardService.getEarningsLeaderboard(period, req.user!.id);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const getReferralLeaderboard = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await leaderboardService.getReferralLeaderboard(req.user!.id);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};
