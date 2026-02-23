import { Request, Response, NextFunction } from 'express';
import * as notificationService from './notification.service';

export const getNotifications = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await notificationService.getNotifications(req.user!.id, req.query as never);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const markAsRead = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await notificationService.markAsRead(req.user!.id, req.params.id);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const markAllAsRead = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await notificationService.markAllAsRead(req.user!.id);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const deleteNotification = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    await notificationService.deleteNotification(req.user!.id, req.params.id);
    res.status(200).json({ success: true, message: 'Notification deleted' });
  } catch (error) {
    next(error);
  }
};

export const registerFcmToken = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { token } = req.body as { token: string };
    const data = await notificationService.registerFcmToken(req.user!.id, token);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};
