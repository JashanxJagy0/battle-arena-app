import { Router } from 'express';
import authRouter from '../modules/auth/auth.routes';
import userRouter from '../modules/user/user.routes';
import walletRouter from '../modules/wallet/wallet.routes';
import ludoRouter from '../modules/ludo/ludo.routes';
import tournamentRouter, { adminTournamentRouter } from '../modules/tournament/tournament.routes';
import bonusRouter from '../modules/bonus/bonus.routes';
import wagerRouter from '../modules/wager/wager.routes';
import leaderboardRouter from '../modules/leaderboard/leaderboard.routes';
import referralRouter from '../modules/referral/referral.routes';
import notificationRouter from '../modules/notification/notification.routes';
import adminRouter from '../modules/admin/admin.routes';

export const apiRouter = Router();

apiRouter.use('/auth', authRouter);
apiRouter.use('/users', userRouter);
apiRouter.use('/wallet', walletRouter);
apiRouter.use('/ludo', ludoRouter);
apiRouter.use('/tournaments', tournamentRouter);
apiRouter.use('/admin/tournaments', adminTournamentRouter);
apiRouter.use('/bonuses', bonusRouter);
apiRouter.use('/wagers', wagerRouter);
apiRouter.use('/leaderboard', leaderboardRouter);
apiRouter.use('/referral', referralRouter);
apiRouter.use('/notifications', notificationRouter);
apiRouter.use('/admin', adminRouter);
