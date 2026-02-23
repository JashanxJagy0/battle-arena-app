import { Router } from 'express';
import * as notificationController from './notification.controller';
import { authenticate } from '../../middleware/auth.middleware';
import { validate } from '../../middleware/validation.middleware';
import { getNotificationsQuerySchema, registerFcmTokenSchema } from './notification.validation';

const router = Router();

router.get('/', authenticate, validate(getNotificationsQuerySchema, 'query'), notificationController.getNotifications);
router.put('/:id/read', authenticate, notificationController.markAsRead);
router.put('/read-all', authenticate, notificationController.markAllAsRead);
router.delete('/:id', authenticate, notificationController.deleteNotification);
router.post('/fcm-token', authenticate, validate(registerFcmTokenSchema), notificationController.registerFcmToken);

export default router;
