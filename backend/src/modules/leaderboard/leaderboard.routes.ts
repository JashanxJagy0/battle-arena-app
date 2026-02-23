import { Router } from 'express';
import * as leaderboardController from './leaderboard.controller';
import { authenticate } from '../../middleware/auth.middleware';

const router = Router();

router.get('/ludo', authenticate, leaderboardController.getLudoLeaderboard);
router.get('/freefire', authenticate, leaderboardController.getFreeFireLeaderboard);
router.get('/earnings', authenticate, leaderboardController.getEarningsLeaderboard);
router.get('/referrals', authenticate, leaderboardController.getReferralLeaderboard);

export default router;
