import { Request, Response, NextFunction } from 'express';
import * as userService from './user.service';

export const getProfile = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const user = await userService.getProfile(req.user!.id);
    res.status(200).json({ success: true, data: user });
  } catch (error) {
    next(error);
  }
};

export const updateProfile = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const user = await userService.updateProfile(req.user!.id, req.body);
    res.status(200).json({ success: true, data: user });
  } catch (error) {
    next(error);
  }
};

export const linkFreeFireAccount = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const user = await userService.linkFreeFireAccount(req.user!.id, req.body);
    res.status(200).json({ success: true, data: user });
  } catch (error) {
    next(error);
  }
};

export const getStats = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const stats = await userService.getStats(req.user!.id);
    res.status(200).json({ success: true, data: stats });
  } catch (error) {
    next(error);
  }
};
