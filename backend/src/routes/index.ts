import { Router } from 'express';
import authRouter from '../modules/auth/auth.routes';
import userRouter from '../modules/user/user.routes';
import walletRouter from '../modules/wallet/wallet.routes';
import ludoRouter from '../modules/ludo/ludo.routes';
import tournamentRouter, { adminTournamentRouter } from '../modules/tournament/tournament.routes';

export const apiRouter = Router();

apiRouter.use('/auth', authRouter);
apiRouter.use('/users', userRouter);
apiRouter.use('/wallet', walletRouter);
apiRouter.use('/ludo', ludoRouter);
apiRouter.use('/tournaments', tournamentRouter);
apiRouter.use('/admin/tournaments', adminTournamentRouter);
