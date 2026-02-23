import cron from 'node-cron';
import { redis } from '../config/redis';
import { recomputeAllLeaderboards } from '../modules/leaderboard/leaderboard.service';

const LOCK_KEY = 'leaderboard_cron:lock';
const LOCK_TTL = 270; // just under 5 minutes

export const startLeaderboardCron = (): void => {
  // Every 5 minutes
  cron.schedule('*/5 * * * *', async () => {
    const acquired = await redis.set(LOCK_KEY, '1', 'EX', LOCK_TTL, 'NX');
    if (!acquired) return;

    try {
      await recomputeAllLeaderboards();
      console.log('[LeaderboardCron] All leaderboards recomputed and cached');
    } catch (err) {
      console.error('[LeaderboardCron] Error recomputing leaderboards:', err);
    }
  });

  console.log('✅ Leaderboard cron jobs started');
};
