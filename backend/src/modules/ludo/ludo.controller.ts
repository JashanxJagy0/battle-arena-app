import { Request, Response, NextFunction } from 'express';
import * as ludoService from './ludo.service';

export const getLobby = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const matches = await ludoService.getLobby(req.query as Parameters<typeof ludoService.getLobby>[0]);
    res.status(200).json({ success: true, data: matches });
  } catch (error) {
    next(error);
  }
};

export const createMatch = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const match = await ludoService.createMatch(req.user!.id, req.body);
    res.status(201).json({ success: true, data: match });
  } catch (error) {
    next(error);
  }
};

export const joinMatch = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const match = await ludoService.joinMatch(req.user!.id, req.params.matchId);
    res.status(200).json({ success: true, data: match });
  } catch (error) {
    next(error);
  }
};

export const getMatch = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const match = await ludoService.getMatch(req.params.matchId);
    res.status(200).json({ success: true, data: match });
  } catch (error) {
    next(error);
  }
};

export const getMatchState = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const state = await ludoService.getMatchState(req.params.matchId);
    res.status(200).json({ success: true, data: state });
  } catch (error) {
    next(error);
  }
};

export const playerReady = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const result = await ludoService.playerReady(req.user!.id, req.params.matchId);
    res.status(200).json({ success: true, data: result });
  } catch (error) {
    next(error);
  }
};

export const leaveMatch = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const result = await ludoService.leaveMatch(req.user!.id, req.params.matchId);
    res.status(200).json({ success: true, data: result });
  } catch (error) {
    next(error);
  }
};

export const getMyMatches = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const result = await ludoService.getMyMatches(
      req.user!.id,
      req.query as unknown as Parameters<typeof ludoService.getMyMatches>[1],
    );
    res.status(200).json({ success: true, data: result });
  } catch (error) {
    next(error);
  }
};

export const createDispute = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const dispute = await ludoService.createDispute(req.user!.id, req.params.matchId, req.body);
    res.status(201).json({ success: true, data: dispute });
  } catch (error) {
    next(error);
  }
};
