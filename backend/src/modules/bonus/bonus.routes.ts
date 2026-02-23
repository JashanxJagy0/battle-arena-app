import { Router } from 'express';
import * as bonusController from './bonus.controller';
import { authenticate } from '../../middleware/auth.middleware';
import { validate } from '../../middleware/validation.middleware';
import { redeemPromoCodeSchema, getBonusHistoryQuerySchema } from './bonus.validation';

const router = Router();

router.get('/', authenticate, bonusController.getAllBonuses);
router.get('/daily', authenticate, bonusController.getDailyBonus);
router.post('/daily/claim', authenticate, bonusController.claimDailyBonus);
router.get('/weekly', authenticate, bonusController.getWeeklyBonus);
router.post('/weekly/claim', authenticate, bonusController.claimWeeklyBonus);
router.get('/monthly', authenticate, bonusController.getMonthlyBonus);
router.post('/monthly/claim', authenticate, bonusController.claimMonthlyBonus);
router.post('/promo-code', authenticate, validate(redeemPromoCodeSchema), bonusController.redeemPromoCode);
router.get('/history', authenticate, validate(getBonusHistoryQuerySchema, 'query'), bonusController.getBonusHistory);

export default router;
