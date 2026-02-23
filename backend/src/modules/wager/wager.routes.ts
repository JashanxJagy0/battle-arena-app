import { Router } from 'express';
import * as wagerController from './wager.controller';
import { authenticate } from '../../middleware/auth.middleware';
import { validate } from '../../middleware/validation.middleware';
import { getWagersQuerySchema } from './wager.validation';

const router = Router();

router.get('/', authenticate, validate(getWagersQuerySchema, 'query'), wagerController.getWagers);
router.get('/stats', authenticate, wagerController.getWagerStats);
router.get('/stats/daily', authenticate, wagerController.getDailyStats);
router.get('/stats/weekly', authenticate, wagerController.getWeeklyStats);
router.get('/stats/monthly', authenticate, wagerController.getMonthlyStats);
router.get('/:id', authenticate, wagerController.getWagerById);

export default router;
