import { Request, Response, NextFunction } from 'express';
import * as tournamentService from './tournament.service';
import * as roomService from './room.service';

// ─── Public / User Handlers ───────────────────────────────────────────────────

export const listTournaments = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await tournamentService.listTournaments(req.query as never);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const getUpcomingTournaments = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await tournamentService.getUpcomingTournaments();
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const getLiveTournaments = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await tournamentService.getLiveTournaments();
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const getTournamentDetails = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await tournamentService.getTournamentDetails(req.params.id);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const joinTournament = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await tournamentService.joinTournament(req.user!.id, req.params.id);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const checkIn = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await tournamentService.checkIn(req.user!.id, req.params.id);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const getRoomDetails = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await tournamentService.getRoomDetails(req.user!.id, req.params.id);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const getParticipants = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await tournamentService.getParticipants(req.params.id);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const getResults = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await tournamentService.getResults(req.params.id);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const submitResult = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await tournamentService.submitResult(req.user!.id, req.params.id, req.body);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const createDispute = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await tournamentService.createDispute(req.user!.id, req.params.id, req.body);
    res.status(201).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const getMyTournaments = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await tournamentService.getMyTournaments(req.user!.id);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

// ─── Admin Handlers ───────────────────────────────────────────────────────────

export const createTournament = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await tournamentService.createTournament(req.user!.id, req.body);
    res.status(201).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const updateTournament = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await tournamentService.updateTournament(req.params.id, req.user!.id, req.body);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const cancelTournament = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await tournamentService.cancelTournament(req.params.id, req.user!.id);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const setRoom = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    await roomService.setRoom(req.params.id, req.body.roomId, req.body.roomPassword, req.user!.id);
    await roomService.scheduleRoomReveal(req.params.id);
    res.status(200).json({ success: true, message: 'Room details updated successfully' });
  } catch (error) {
    next(error);
  }
};

export const publishResults = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await tournamentService.publishResults(req.params.id, req.user!.id, req.body);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const updateTournamentStatus = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const data = await tournamentService.updateTournamentStatus(
      req.params.id,
      req.user!.id,
      req.body.status,
    );
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};
