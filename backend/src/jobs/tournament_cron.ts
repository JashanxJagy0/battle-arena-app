import cron from 'node-cron';
import { prisma } from '../config/database';
import { redis } from '../config/redis';
import { TournamentStatus } from '@prisma/client';

const CRON_LOCK_KEY = 'tournament_cron:lock';
const CRON_LOCK_TTL_SECONDS = 55; // just under 1 minute so the next run can acquire it

const cancelWithRefund = async (tournamentId: string, title: string, entryFee: number, participants: { userId: string }[]) => {
  const hasEntryFee = entryFee > 0;
  await prisma.$transaction(async (tx) => {
    for (const participant of participants) {
      if (hasEntryFee) {
        await tx.wallet.update({
          where: { userId: participant.userId },
          data: {
            lockedBalance: { decrement: entryFee },
            mainBalance: { increment: entryFee },
          },
        });
      }
      await tx.notification.create({
        data: {
          userId: participant.userId,
          title: 'Tournament Cancelled — Not Enough Players',
          body: hasEntryFee
            ? `"${title}" was cancelled due to insufficient participants. Your entry fee of ₹${entryFee} has been refunded.`
            : `"${title}" was cancelled due to insufficient participants.`,
          type: 'TOURNAMENT_CANCELLED',
          referenceType: 'tournament',
          referenceId: tournamentId,
        },
      });
    }

    await tx.wager.updateMany({
      where: { referenceId: tournamentId, gameType: 'FREE_FIRE', status: 'ACTIVE' },
      data: { status: 'REFUNDED', settledAt: new Date() },
    });

    await tx.tournament.update({
      where: { id: tournamentId },
      data: { status: TournamentStatus.CANCELLED },
    });
  });
};

export const startTournamentCron = (): void => {
  cron.schedule('* * * * *', async () => {
    // Acquire a distributed lock so only one instance runs at a time
    const acquired = await redis.set(CRON_LOCK_KEY, '1', 'EX', CRON_LOCK_TTL_SECONDS, 'NX');
    if (!acquired) return; // another instance already running

    const now = new Date();

    try {
      // 1. UPCOMING → REGISTRATION_OPEN when registrationStart has passed
      await prisma.tournament.updateMany({
        where: {
          status: TournamentStatus.UPCOMING,
          registrationStart: { lte: now },
        },
        data: { status: TournamentStatus.REGISTRATION_OPEN },
      });

      // 2. REGISTRATION_OPEN → REGISTRATION_CLOSED when registrationEnd has passed
      await prisma.tournament.updateMany({
        where: {
          status: TournamentStatus.REGISTRATION_OPEN,
          registrationEnd: { lte: now },
        },
        data: { status: TournamentStatus.REGISTRATION_CLOSED },
      });

      // 3. Auto-cancel tournaments that closed with fewer than minParticipants
      const underFilled = await prisma.tournament.findMany({
        where: {
          status: TournamentStatus.REGISTRATION_CLOSED,
          registrationEnd: { lte: now },
        },
        include: { participants: { select: { userId: true } } },
      });

      for (const tournament of underFilled) {
        if (tournament.currentParticipants < tournament.minParticipants) {
          await cancelWithRefund(
            tournament.id,
            tournament.title,
            Number(tournament.entryFee),
            tournament.participants,
          );
        }
      }

      // 4. REGISTRATION_CLOSED → LIVE when matchStart has passed
      await prisma.tournament.updateMany({
        where: {
          status: TournamentStatus.REGISTRATION_CLOSED,
          matchStart: { lte: now },
        },
        data: { status: TournamentStatus.LIVE },
      });
    } catch (err) {
      console.error('[TournamentCron] Error during status update:', err);
    }
  });

  console.log('✅ Tournament cron jobs started');
};
