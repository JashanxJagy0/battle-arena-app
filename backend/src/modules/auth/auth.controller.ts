import { Request, Response, NextFunction } from 'express';
import * as authService from './auth.service';

export const register = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const result = await authService.register(req.body);
    res.status(201).json({ success: true, data: result });
  } catch (error) {
    next(error);
  }
};

export const login = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const result = await authService.login(req.body);
    res.status(200).json({ success: true, data: result });
  } catch (error) {
    next(error);
  }
};

export const sendOtp = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const result = await authService.sendOtp(req.body.phone);
    res.status(200).json({ success: true, data: result });
  } catch (error) {
    next(error);
  }
};

export const verifyOtp = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const result = await authService.verifyOtp(req.body.phone, req.body.otp);
    res.status(200).json({ success: true, data: result });
  } catch (error) {
    next(error);
  }
};

export const refreshToken = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const tokens = await authService.refreshTokens(req.body.refreshToken);
    res.status(200).json({ success: true, data: tokens });
  } catch (error) {
    next(error);
  }
};

export const logout = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;
    const token = authHeader?.split(' ')[1] || '';
    await authService.logout(token, req.user!.id);
    res.status(200).json({ success: true, message: 'Logged out successfully' });
  } catch (error) {
    next(error);
  }
};

export const getMe = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const user = await authService.getMe(req.user!.id);
    res.status(200).json({ success: true, data: user });
  } catch (error) {
    next(error);
  }
};
