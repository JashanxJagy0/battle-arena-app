import { Router } from 'express';
import * as tournamentController from './tournament.controller';
import { validate } from '../../middleware/validation.middleware';
import { authenticate } from '../../middleware/auth.middleware';
import { requireAdmin } from '../../middleware/admin.middleware';
import {
  createTournamentSchema,
  updateTournamentSchema,
  listTournamentsQuerySchema,
  submitResultSchema,
  disputeSchema,
  publishResultsSchema,
  setRoomSchema,
  updateStatusSchema,
} from './tournament.validation';

// ─── Public Routes (authentication required) ──────────────────────────────────

const router = Router();

router.use(authenticate);

// Static routes must come before parameterized ones
router.get('/', validate(listTournamentsQuerySchema, 'query'), tournamentController.listTournaments);
router.get('/upcoming', tournamentController.getUpcomingTournaments);
router.get('/live', tournamentController.getLiveTournaments);
router.get('/my-tournaments', tournamentController.getMyTournaments);

// Parameterized routes
router.get('/:id', tournamentController.getTournamentDetails);
router.post('/:id/join', tournamentController.joinTournament);
router.post('/:id/checkin', tournamentController.checkIn);
router.get('/:id/room', tournamentController.getRoomDetails);
router.get('/:id/participants', tournamentController.getParticipants);
router.get('/:id/results', tournamentController.getResults);
router.post('/:id/submit-result', validate(submitResultSchema), tournamentController.submitResult);
router.post('/:id/dispute', validate(disputeSchema), tournamentController.createDispute);

// ─── Admin Routes ─────────────────────────────────────────────────────────────

const adminRouter = Router();

adminRouter.use(authenticate, requireAdmin);

adminRouter.post('/', validate(createTournamentSchema), tournamentController.createTournament);
adminRouter.put('/:id', validate(updateTournamentSchema), tournamentController.updateTournament);
adminRouter.delete('/:id', tournamentController.cancelTournament);
adminRouter.put('/:id/room', validate(setRoomSchema), tournamentController.setRoom);
adminRouter.put('/:id/results', validate(publishResultsSchema), tournamentController.publishResults);
adminRouter.put('/:id/status', validate(updateStatusSchema), tournamentController.updateTournamentStatus);

export default router;
export { adminRouter as adminTournamentRouter };
