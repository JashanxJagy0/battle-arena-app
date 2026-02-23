import { Router } from 'express';
import * as referralController from './referral.controller';
import { authenticate } from '../../middleware/auth.middleware';

const router = Router();

router.get('/code', authenticate, referralController.getReferralInfo);
router.get('/stats', authenticate, referralController.getReferralStats);
router.get('/list', authenticate, referralController.getReferralList);

export default router;
