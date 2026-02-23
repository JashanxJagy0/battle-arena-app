import { Request, Response, NextFunction } from 'express';
import * as walletService from './wallet.service';

export const getBalance = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await walletService.getBalance(req.user!.id);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const getTransactions = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await walletService.getTransactions(req.user!.id, req.query as never);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const createDeposit = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await walletService.createDeposit(req.user!.id, req.body);
    res.status(201).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const getDeposit = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await walletService.getDepositByOrderId(req.user!.id, req.params.orderId);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const handleDepositWebhook = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const signature = String(req.headers['x-nowpayments-sig'] ?? '');
    const result = await walletService.handleDepositWebhook(req.body, signature);
    res.status(200).json({ success: true, data: result });
  } catch (error) {
    next(error);
  }
};

export const requestWithdrawal = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await walletService.requestWithdrawal(req.user!.id, req.body);
    res.status(201).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const getWithdrawal = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await walletService.getWithdrawal(req.user!.id, req.params.id);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const getCryptoRates = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await walletService.getCryptoRates();
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const getSupportedCurrencies = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = walletService.getSupportedCurrencies();
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};
