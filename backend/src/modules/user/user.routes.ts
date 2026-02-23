import { Router } from 'express';
import * as userController from './user.controller';
import { authenticate } from '../../middleware/auth.middleware';
import { validate } from '../../middleware/validation.middleware';
import { z } from 'zod';

const router = Router();

const updateProfileSchema = z.object({
  username: z.string().min(3).max(30).regex(/^[a-zA-Z0-9_]+$/).optional(),
  email: z.string().email().optional(),
  avatarUrl: z.string().url().optional(),
});

const freeFireSchema = z.object({
  freeFireUid: z.string().min(1, 'Free Fire UID is required'),
  freeFireIgn: z.string().min(1, 'Free Fire IGN is required'),
});

router.use(authenticate);

router.get('/profile', userController.getProfile);
router.put('/profile', validate(updateProfileSchema), userController.updateProfile);
router.put('/free-fire-id', validate(freeFireSchema), userController.linkFreeFireAccount);
router.get('/stats', userController.getStats);

export default router;
