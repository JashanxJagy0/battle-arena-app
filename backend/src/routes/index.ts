import { Router } from 'express';
import authRouter from '../modules/auth/auth.routes';
import userRouter from '../modules/user/user.routes';
import walletRouter from '../modules/wallet/wallet.routes';

export const apiRouter = Router();

apiRouter.use('/auth', authRouter);
apiRouter.use('/users', userRouter);
apiRouter.use('/wallet', walletRouter);
