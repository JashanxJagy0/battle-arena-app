import { Router } from 'express';
import * as ludoController from './ludo.controller';
import { validate } from '../../middleware/validation.middleware';
import { authenticate } from '../../middleware/auth.middleware';
import {
  createMatchSchema,
  getLobbySchema,
  myMatchesSchema,
  disputeSchema,
} from './ludo.validation';

const router = Router();

// All ludo routes require authentication
router.use(authenticate);

// Lobby
router.get('/lobby', validate(getLobbySchema, 'query'), ludoController.getLobby);

// Match lifecycle
router.post('/match/create', validate(createMatchSchema), ludoController.createMatch);
router.post('/match/:matchId/join', ludoController.joinMatch);
router.get('/match/:matchId', ludoController.getMatch);
router.get('/match/:matchId/state', ludoController.getMatchState);
router.post('/match/:matchId/ready', ludoController.playerReady);
router.post('/match/:matchId/leave', ludoController.leaveMatch);
router.post('/match/:matchId/dispute', validate(disputeSchema), ludoController.createDispute);

// User match history
router.get('/my-matches', validate(myMatchesSchema, 'query'), ludoController.getMyMatches);

export default router;
