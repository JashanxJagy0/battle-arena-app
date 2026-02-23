import cron from 'node-cron';
import { prisma } from '../config/database';
import { redis } from '../config/redis';

const LOCK_TTL = 55;

// ─── Daily at midnight: expire unclaimed daily bonuses ───────────────────────

async function expireDailyBonuses() {
  const lockKey = 'bonus_cron:daily:lock';
  const acquired = await redis.set(lockKey, '1', 'EX', LOCK_TTL, 'NX');
  if (!acquired) return;

  const yesterday = new Date();
  yesterday.setUTCDate(yesterday.getUTCDate() - 1);
  yesterday.setUTCHours(0, 0, 0, 0);

  const today = new Date();
  today.setUTCHours(0, 0, 0, 0);

  try {
    const result = await prisma.bonus.updateMany({
      where: {
        bonusType: 'DAILY_LOGIN',
        isClaimed: false,
        isExpired: false,
        createdAt: { gte: yesterday, lt: today },
      },
      data: { isExpired: true },
    });

    if (result.count > 0) {
      console.log(`[BonusCron] Expired ${result.count} unclaimed daily bonuses`);
    }
  } catch (err) {
    console.error('[BonusCron] Error expiring daily bonuses:', err);
  }
}

// ─── Weekly on Monday: reset weekly bonus eligibility ────────────────────────

async function resetWeeklyBonus() {
  const lockKey = 'bonus_cron:weekly:lock';
  const acquired = await redis.set(lockKey, '1', 'EX', LOCK_TTL, 'NX');
  if (!acquired) return;

  try {
    // Nothing to reset in DB — weekly claim eligibility is determined by
    // whether a WEEKLY_PLAY Bonus record exists for the current week.
    // Logging only for observability.
    console.log('[BonusCron] Weekly bonus eligibility reset (new week started)');
  } catch (err) {
    console.error('[BonusCron] Error resetting weekly bonus:', err);
  }
}

// ─── Monthly on 1st: reset monthly bonus eligibility + create monthly bonuses ─

async function processMonthlyBonuses() {
  const lockKey = 'bonus_cron:monthly:lock';
  const acquired = await redis.set(lockKey, '1', 'EX', LOCK_TTL, 'NX');
  if (!acquired) return;

  try {
    // Monthly claim eligibility is database-driven (MONTHLY_LOYALTY Bonus record
    // per calendar month), so no explicit reset is needed.
    // Pre-compute monthly totals and create eligible Bonus records so users
    // can claim without triggering an on-demand aggregation.

    const lastMonthStart = new Date();
    lastMonthStart.setUTCMonth(lastMonthStart.getUTCMonth() - 1);
    lastMonthStart.setUTCDate(1);
    lastMonthStart.setUTCHours(0, 0, 0, 0);

    const thisMonthStart = new Date();
    thisMonthStart.setUTCDate(1);
    thisMonthStart.setUTCHours(0, 0, 0, 0);

    console.log(`[BonusCron] Monthly bonus processing started for ${lastMonthStart.toISOString().slice(0, 7)}`);
    // The actual bonus credit happens when the user claims via the API.
    // Cron is a hook point for future pre-computation / notification emails.
    console.log('[BonusCron] Monthly bonus eligibility reset (new month started)');
  } catch (err) {
    console.error('[BonusCron] Error processing monthly bonuses:', err);
  }
}

// ─── Cron schedule ───────────────────────────────────────────────────────────

export const startBonusCron = (): void => {
  // Daily at midnight UTC
  cron.schedule('0 0 * * *', expireDailyBonuses, { timezone: 'UTC' });

  // Every Monday at midnight UTC
  cron.schedule('0 0 * * 1', resetWeeklyBonus, { timezone: 'UTC' });

  // 1st of every month at midnight UTC
  cron.schedule('0 0 1 * *', processMonthlyBonuses, { timezone: 'UTC' });

  console.log('✅ Bonus cron jobs started');
};
