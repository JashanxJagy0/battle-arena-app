import { Prisma, TournamentStatus, ParticipantStatus, WagerStatus } from '@prisma/client';
import { prisma } from '../../config/database';
import { AppError } from '../../middleware/error_handler.middleware';
import type {
  CreateTournamentInput,
  UpdateTournamentInput,
  ListTournamentsQuery,
  SubmitResultInput,
  DisputeInput,
  PublishResultsInput,
} from './tournament.validation';

const CHECKIN_WINDOW_MINUTES = 10;
const FIRST_PLACE_KEY = '1';

// ─── Public / User Functions ──────────────────────────────────────────────────

export const listTournaments = async (filters: ListTournamentsQuery) => {
  const { page, limit, status, gameMode, entryFeeMin, entryFeeMax, dateFrom, dateTo } = filters;
  const skip = (page - 1) * limit;

  const where: Prisma.TournamentWhereInput = {};
  if (status) where.status = status;
  if (gameMode) where.gameMode = gameMode;
  if (entryFeeMin !== undefined || entryFeeMax !== undefined) {
    where.entryFee = {};
    if (entryFeeMin !== undefined)
      (where.entryFee as Prisma.DecimalFilter).gte = new Prisma.Decimal(entryFeeMin);
    if (entryFeeMax !== undefined)
      (where.entryFee as Prisma.DecimalFilter).lte = new Prisma.Decimal(entryFeeMax);
  }
  if (dateFrom || dateTo) {
    where.matchStart = {};
    if (dateFrom) (where.matchStart as Prisma.DateTimeFilter).gte = new Date(dateFrom);
    if (dateTo) (where.matchStart as Prisma.DateTimeFilter).lte = new Date(dateTo);
  }

  const [total, items] = await Promise.all([
    prisma.tournament.count({ where }),
    prisma.tournament.findMany({
      where,
      orderBy: { matchStart: 'asc' },
      skip,
      take: limit,
      select: {
        id: true,
        title: true,
        game: true,
        gameMode: true,
        tournamentType: true,
        entryFee: true,
        prizePool: true,
        maxParticipants: true,
        currentParticipants: true,
        status: true,
        matchStart: true,
        registrationEnd: true,
        bannerImageUrl: true,
      },
    }),
  ]);

  return { total, page, limit, totalPages: Math.ceil(total / limit), items };
};

export const getUpcomingTournaments = async () => {
  return prisma.tournament.findMany({
    where: {
      status: {
        in: [
          TournamentStatus.UPCOMING,
          TournamentStatus.REGISTRATION_OPEN,
          TournamentStatus.REGISTRATION_CLOSED,
        ],
      },
      matchStart: { gte: new Date() },
    },
    orderBy: { matchStart: 'asc' },
    take: 20,
  });
};

export const getLiveTournaments = async () => {
  return prisma.tournament.findMany({
    where: { status: TournamentStatus.LIVE },
    orderBy: { matchStart: 'asc' },
  });
};

export const getTournamentDetails = async (tournamentId: string) => {
  const tournament = await prisma.tournament.findUnique({
    where: { id: tournamentId },
    include: {
      createdBy: { select: { username: true } },
      _count: { select: { participants: true } },
    },
  });

  if (!tournament) throw new AppError('Tournament not found', 404);
  return tournament;
};

export const joinTournament = async (userId: string, tournamentId: string) => {
  return prisma.$transaction(async (tx) => {
    const tournament = await tx.tournament.findUnique({ where: { id: tournamentId } });
    if (!tournament) throw new AppError('Tournament not found', 404);

    if (tournament.status !== TournamentStatus.REGISTRATION_OPEN) {
      throw new AppError('Tournament registration is not open', 400);
    }
    if (tournament.currentParticipants >= tournament.maxParticipants) {
      throw new AppError('Tournament is full', 400);
    }

    const existing = await tx.tournamentParticipant.findUnique({
      where: { tournamentId_userId: { tournamentId, userId } },
    });
    if (existing) throw new AppError('You have already joined this tournament', 400);

    const user = await tx.user.findUnique({
      where: { id: userId },
      select: { freeFireUid: true, freeFireIgn: true },
    });
    if (!user) throw new AppError('User not found', 404);
    if (!user.freeFireUid) {
      throw new AppError('You must link your Free Fire UID before joining a tournament', 400);
    }

    const wallet = await tx.wallet.findUnique({ where: { userId } });
    if (!wallet) throw new AppError('Wallet not found', 404);

    const entryFee = tournament.entryFee;
    const available = wallet.mainBalance.add(wallet.bonusBalance);
    if (available.lt(entryFee)) throw new AppError('Insufficient balance', 400);

    // Deduct from main balance first, then bonus balance
    const mainDeduct = wallet.mainBalance.gte(entryFee) ? entryFee : wallet.mainBalance;
    const bonusDeduct = entryFee.sub(mainDeduct);

    if (entryFee.gt(new Prisma.Decimal(0))) {
      await tx.wallet.update({
        where: { userId },
        data: {
          mainBalance: { decrement: mainDeduct },
          bonusBalance: { decrement: bonusDeduct },
          lockedBalance: { increment: entryFee },
          totalWagered: { increment: entryFee },
        },
      });
    }

    await tx.tournamentParticipant.create({
      data: {
        tournamentId,
        userId,
        freeFireUid: user.freeFireUid,
        freeFireIgn: user.freeFireIgn ?? undefined,
        status: ParticipantStatus.REGISTERED,
      },
    });

    // potentialWin: first-place prize from distribution, or the full prize pool
    const distribution = tournament.prizeDistribution as Record<string, number> | null;
    const potentialWin = distribution?.[FIRST_PLACE_KEY] ?? Number(tournament.prizePool);

    await tx.wager.create({
      data: {
        userId,
        gameType: 'FREE_FIRE',
        referenceId: tournamentId,
        entryAmount: entryFee,
        potentialWin: new Prisma.Decimal(potentialWin),
        status: WagerStatus.ACTIVE,
      },
    });

    const newCount = tournament.currentParticipants + 1;
    const newStatus =
      newCount >= tournament.maxParticipants
        ? TournamentStatus.REGISTRATION_CLOSED
        : tournament.status;

    await tx.tournament.update({
      where: { id: tournamentId },
      data: { currentParticipants: newCount, status: newStatus },
    });

    await tx.notification.create({
      data: {
        userId,
        title: 'Tournament Joined! 🎮',
        body: `You have successfully joined "${tournament.title}". Entry fee of ₹${entryFee} has been deducted.`,
        type: 'TOURNAMENT_JOINED',
        referenceType: 'tournament',
        referenceId: tournamentId,
      },
    });

    return { message: 'Successfully joined tournament', tournamentId, entryFee, status: newStatus };
  });
};

export const checkIn = async (userId: string, tournamentId: string) => {
  const tournament = await prisma.tournament.findUnique({ where: { id: tournamentId } });
  if (!tournament) throw new AppError('Tournament not found', 404);

  if (tournament.status !== TournamentStatus.REGISTRATION_CLOSED) {
    throw new AppError('Check-in is only available when registration is closed', 400);
  }

  if (!tournament.matchStart) throw new AppError('Match start time has not been set', 400);

  const now = new Date();
  if (now >= tournament.matchStart) throw new AppError('Match has already started', 400);

  const minutesUntilStart = (tournament.matchStart.getTime() - now.getTime()) / 60_000;
  if (minutesUntilStart > CHECKIN_WINDOW_MINUTES) {
    throw new AppError(
      `Check-in opens ${CHECKIN_WINDOW_MINUTES} minutes before the match starts`,
      400,
    );
  }

  const participant = await prisma.tournamentParticipant.findUnique({
    where: { tournamentId_userId: { tournamentId, userId } },
  });
  if (!participant) throw new AppError('You are not registered for this tournament', 404);
  if (participant.status === ParticipantStatus.CONFIRMED) {
    throw new AppError('You have already checked in', 400);
  }

  await prisma.tournamentParticipant.update({
    where: { tournamentId_userId: { tournamentId, userId } },
    data: { status: ParticipantStatus.CONFIRMED },
  });

  // Return room details if they are already visible
  const roomInfo = await getRoomDetails(userId, tournamentId);
  return { checkedIn: true, ...roomInfo };
};

export const getRoomDetails = async (userId: string, tournamentId: string) => {
  const tournament = await prisma.tournament.findUnique({ where: { id: tournamentId } });
  if (!tournament) throw new AppError('Tournament not found', 404);

  const participant = await prisma.tournamentParticipant.findUnique({
    where: { tournamentId_userId: { tournamentId, userId } },
  });
  if (!participant) throw new AppError('You are not a participant of this tournament', 403);

  const now = new Date();

  if (!tournament.roomVisibleAt || now < tournament.roomVisibleAt) {
    const minutesUntilVisible = tournament.roomVisibleAt
      ? Math.ceil((tournament.roomVisibleAt.getTime() - now.getTime()) / 60_000)
      : null;
    return { roomVisibleAt: tournament.roomVisibleAt, minutesUntilVisible };
  }

  if (!tournament.roomId || !tournament.roomPassword) {
    throw new AppError('Room details have not been set yet', 404);
  }

  return { roomId: tournament.roomId, roomPassword: tournament.roomPassword };
};

export const getParticipants = async (tournamentId: string) => {
  const tournament = await prisma.tournament.findUnique({ where: { id: tournamentId } });
  if (!tournament) throw new AppError('Tournament not found', 404);

  return prisma.tournamentParticipant.findMany({
    where: { tournamentId },
    include: { user: { select: { username: true, avatarUrl: true } } },
    orderBy: { joinedAt: 'asc' },
  });
};

export const getResults = async (tournamentId: string) => {
  const tournament = await prisma.tournament.findUnique({ where: { id: tournamentId } });
  if (!tournament) throw new AppError('Tournament not found', 404);

  return prisma.tournamentParticipant.findMany({
    where: { tournamentId, placement: { not: null } },
    include: { user: { select: { username: true, avatarUrl: true } } },
    orderBy: { placement: 'asc' },
  });
};

export const submitResult = async (
  userId: string,
  tournamentId: string,
  data: SubmitResultInput,
) => {
  const tournament = await prisma.tournament.findUnique({ where: { id: tournamentId } });
  if (!tournament) throw new AppError('Tournament not found', 404);

  if (tournament.status !== TournamentStatus.LIVE) {
    throw new AppError('Results can only be submitted while the tournament is live', 400);
  }

  const participant = await prisma.tournamentParticipant.findUnique({
    where: { tournamentId_userId: { tournamentId, userId } },
  });
  if (!participant) throw new AppError('You are not a participant of this tournament', 403);

  await prisma.tournamentParticipant.update({
    where: { tournamentId_userId: { tournamentId, userId } },
    data: {
      kills: data.kills,
      placement: data.placement,
      screenshotUrl: data.screenshotUrl,
      status: ParticipantStatus.COMPLETED,
    },
  });

  return { message: 'Result submitted successfully' };
};

export const createDispute = async (
  userId: string,
  tournamentId: string,
  data: DisputeInput,
) => {
  const tournament = await prisma.tournament.findUnique({ where: { id: tournamentId } });
  if (!tournament) throw new AppError('Tournament not found', 404);

  const participant = await prisma.tournamentParticipant.findUnique({
    where: { tournamentId_userId: { tournamentId, userId } },
  });
  if (!participant) throw new AppError('You are not a participant of this tournament', 403);

  return prisma.dispute.create({
    data: {
      userId,
      gameType: 'FREE_FIRE',
      referenceId: tournamentId,
      reason: data.reason,
      evidenceUrls: data.evidenceUrls ?? [],
      status: 'OPEN',
    },
  });
};

export const getMyTournaments = async (userId: string) => {
  return prisma.tournamentParticipant.findMany({
    where: { userId },
    include: { tournament: true },
    orderBy: { joinedAt: 'desc' },
  });
};

// ─── Admin Functions ──────────────────────────────────────────────────────────

export const createTournament = async (adminId: string, data: CreateTournamentInput) => {
  return prisma.tournament.create({
    data: {
      title: data.title,
      description: data.description,
      game: data.game,
      gameMode: data.gameMode,
      tournamentType: data.tournamentType,
      mapName: data.mapName,
      entryFee: new Prisma.Decimal(data.entryFee),
      prizePool: new Prisma.Decimal(data.prizePool),
      platformFee: new Prisma.Decimal(data.platformFee),
      maxParticipants: data.maxParticipants,
      minParticipants: data.minParticipants,
      perKillPrize: data.perKillPrize !== undefined ? new Prisma.Decimal(data.perKillPrize) : undefined,
      prizeDistribution: data.prizeDistribution as Prisma.InputJsonValue | undefined,
      roomVisibleAt: data.roomVisibleAt ? new Date(data.roomVisibleAt) : undefined,
      registrationStart: data.registrationStart ? new Date(data.registrationStart) : undefined,
      registrationEnd: data.registrationEnd ? new Date(data.registrationEnd) : undefined,
      matchStart: data.matchStart ? new Date(data.matchStart) : undefined,
      matchEnd: data.matchEnd ? new Date(data.matchEnd) : undefined,
      rules: data.rules,
      bannerImageUrl: data.bannerImageUrl,
      createdById: adminId,
      status: TournamentStatus.UPCOMING,
    },
  });
};

export const updateTournament = async (
  tournamentId: string,
  adminId: string,
  data: UpdateTournamentInput,
) => {
  const tournament = await prisma.tournament.findUnique({ where: { id: tournamentId } });
  if (!tournament) throw new AppError('Tournament not found', 404);

  if (
    tournament.status === TournamentStatus.COMPLETED ||
    tournament.status === TournamentStatus.CANCELLED
  ) {
    throw new AppError('Cannot update a completed or cancelled tournament', 400);
  }

  const updated = await prisma.tournament.update({
    where: { id: tournamentId },
    data: {
      title: data.title,
      description: data.description,
      game: data.game,
      gameMode: data.gameMode,
      tournamentType: data.tournamentType,
      mapName: data.mapName,
      entryFee: data.entryFee !== undefined ? new Prisma.Decimal(data.entryFee) : undefined,
      prizePool: data.prizePool !== undefined ? new Prisma.Decimal(data.prizePool) : undefined,
      platformFee: data.platformFee !== undefined ? new Prisma.Decimal(data.platformFee) : undefined,
      maxParticipants: data.maxParticipants,
      minParticipants: data.minParticipants,
      perKillPrize: data.perKillPrize !== undefined ? new Prisma.Decimal(data.perKillPrize) : undefined,
      prizeDistribution: data.prizeDistribution !== undefined
        ? (data.prizeDistribution as Prisma.InputJsonValue)
        : undefined,
      roomVisibleAt: data.roomVisibleAt ? new Date(data.roomVisibleAt) : undefined,
      registrationStart: data.registrationStart ? new Date(data.registrationStart) : undefined,
      registrationEnd: data.registrationEnd ? new Date(data.registrationEnd) : undefined,
      matchStart: data.matchStart ? new Date(data.matchStart) : undefined,
      matchEnd: data.matchEnd ? new Date(data.matchEnd) : undefined,
      rules: data.rules,
      bannerImageUrl: data.bannerImageUrl,
    },
  });

  await prisma.auditLog.create({
    data: {
      adminId,
      action: 'UPDATE_TOURNAMENT',
      entityType: 'tournament',
      entityId: tournamentId,
      oldValue: { status: tournament.status, title: tournament.title },
      newValue: data as unknown as Prisma.InputJsonValue,
    },
  });

  return updated;
};

export const cancelTournament = async (tournamentId: string, adminId: string) => {
  return prisma.$transaction(async (tx) => {
    const tournament = await tx.tournament.findUnique({
      where: { id: tournamentId },
      include: { participants: true },
    });
    if (!tournament) throw new AppError('Tournament not found', 404);

    if (
      tournament.status === TournamentStatus.COMPLETED ||
      tournament.status === TournamentStatus.CANCELLED
    ) {
      throw new AppError('Tournament is already completed or cancelled', 400);
    }

    const entryFee = tournament.entryFee;
    const hasEntryFee = entryFee.gt(new Prisma.Decimal(0));

    for (const participant of tournament.participants) {
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
          title: 'Tournament Cancelled',
          body: hasEntryFee
            ? `"${tournament.title}" has been cancelled. Your entry fee of ₹${entryFee} has been refunded to your main balance.`
            : `"${tournament.title}" has been cancelled.`,
          type: 'TOURNAMENT_CANCELLED',
          referenceType: 'tournament',
          referenceId: tournamentId,
        },
      });
    }

    // Refund active wagers
    await tx.wager.updateMany({
      where: {
        referenceId: tournamentId,
        gameType: 'FREE_FIRE',
        status: WagerStatus.ACTIVE,
      },
      data: { status: WagerStatus.REFUNDED, settledAt: new Date() },
    });

    await tx.tournament.update({
      where: { id: tournamentId },
      data: { status: TournamentStatus.CANCELLED },
    });

    await tx.auditLog.create({
      data: {
        adminId,
        action: 'CANCEL_TOURNAMENT',
        entityType: 'tournament',
        entityId: tournamentId,
        newValue: {
          status: TournamentStatus.CANCELLED,
          refundedCount: tournament.participants.length,
        },
      },
    });

    return { cancelled: true, refundedCount: tournament.participants.length };
  });
};

export const publishResults = async (
  tournamentId: string,
  adminId: string,
  data: PublishResultsInput,
) => {
  return prisma.$transaction(async (tx) => {
    const tournament = await tx.tournament.findUnique({
      where: { id: tournamentId },
      include: { participants: true },
    });
    if (!tournament) throw new AppError('Tournament not found', 404);

    if (
      tournament.status !== TournamentStatus.LIVE &&
      tournament.status !== TournamentStatus.COMPLETED
    ) {
      throw new AppError(
        'Results can only be published for live or recently completed tournaments',
        400,
      );
    }

    const distribution = tournament.prizeDistribution as Record<string, number> | null;
    const perKillPrize = tournament.perKillPrize ? Number(tournament.perKillPrize) : 0;
    const entryFee = tournament.entryFee;
    const hasEntryFee = entryFee.gt(new Prisma.Decimal(0));

    const processedUserIds = new Set<string>();

    for (const result of data.results) {
      processedUserIds.add(result.userId);

      const placementPrize = distribution?.[String(result.placement)] ?? 0;
      const killBonus = result.kills * perKillPrize;
      const totalPrize = placementPrize + killBonus;

      await tx.tournamentParticipant.update({
        where: { tournamentId_userId: { tournamentId, userId: result.userId } },
        data: {
          kills: result.kills,
          placement: result.placement,
          prizeWon: totalPrize > 0 ? new Prisma.Decimal(totalPrize) : undefined,
          status: ParticipantStatus.COMPLETED,
        },
      });

      if (totalPrize > 0) {
        if (hasEntryFee) {
          await tx.wallet.update({
            where: { userId: result.userId },
            data: {
              lockedBalance: { decrement: entryFee },
              winningBalance: { increment: new Prisma.Decimal(totalPrize) },
              totalWon: { increment: new Prisma.Decimal(totalPrize) },
            },
          });
        } else {
          await tx.wallet.update({
            where: { userId: result.userId },
            data: {
              winningBalance: { increment: new Prisma.Decimal(totalPrize) },
              totalWon: { increment: new Prisma.Decimal(totalPrize) },
            },
          });
        }

        await tx.wager.updateMany({
          where: { userId: result.userId, referenceId: tournamentId, gameType: 'FREE_FIRE' },
          data: {
            status: WagerStatus.WON,
            actualWin: new Prisma.Decimal(totalPrize),
            netProfit: new Prisma.Decimal(totalPrize).sub(entryFee),
            settledAt: new Date(),
          },
        });

        await tx.user.update({
          where: { id: result.userId },
          data: { totalGamesPlayed: { increment: 1 }, totalWins: { increment: 1 } },
        });
      } else {
        if (hasEntryFee) {
          await tx.wallet.update({
            where: { userId: result.userId },
            data: { lockedBalance: { decrement: entryFee } },
          });
        }

        await tx.wager.updateMany({
          where: { userId: result.userId, referenceId: tournamentId, gameType: 'FREE_FIRE' },
          data: { status: WagerStatus.LOST, settledAt: new Date() },
        });

        await tx.user.update({
          where: { id: result.userId },
          data: { totalGamesPlayed: { increment: 1 }, totalLosses: { increment: 1 } },
        });
      }

      // Recalculate win rate
      const stats = await tx.user.findUnique({
        where: { id: result.userId },
        select: { totalWins: true, totalGamesPlayed: true },
      });
      if (stats && stats.totalGamesPlayed > 0) {
        await tx.user.update({
          where: { id: result.userId },
          data: { winRate: stats.totalWins / stats.totalGamesPlayed },
        });
      }

      await tx.notification.create({
        data: {
          userId: result.userId,
          title: totalPrize > 0 ? '🏆 Tournament Results — You Won!' : 'Tournament Results',
          body:
            totalPrize > 0
              ? `You finished #${result.placement} with ${result.kills} kills and won ₹${totalPrize.toFixed(2)}!`
              : `You finished #${result.placement} with ${result.kills} kills. Better luck next time!`,
          type: totalPrize > 0 ? 'TOURNAMENT_WON' : 'TOURNAMENT_LOST',
          referenceType: 'tournament',
          referenceId: tournamentId,
        },
      });
    }

    // Unlock entry fee for participants not included in the published results
    for (const participant of tournament.participants) {
      if (!processedUserIds.has(participant.userId)) {
        if (hasEntryFee) {
          await tx.wallet.update({
            where: { userId: participant.userId },
            data: { lockedBalance: { decrement: entryFee } },
          });
        }

        await tx.wager.updateMany({
          where: {
            userId: participant.userId,
            referenceId: tournamentId,
            gameType: 'FREE_FIRE',
            status: WagerStatus.ACTIVE,
          },
          data: { status: WagerStatus.LOST, settledAt: new Date() },
        });
      }
    }

    await tx.tournament.update({
      where: { id: tournamentId },
      data: { status: TournamentStatus.COMPLETED },
    });

    await tx.auditLog.create({
      data: {
        adminId,
        action: 'PUBLISH_RESULTS',
        entityType: 'tournament',
        entityId: tournamentId,
        newValue: {
          results: data.results,
          publishedAt: new Date().toISOString(),
        } as unknown as Prisma.InputJsonValue,
      },
    });

    return { published: true, resultsCount: data.results.length };
  });
};

export const updateTournamentStatus = async (
  tournamentId: string,
  adminId: string,
  status: TournamentStatus,
) => {
  const tournament = await prisma.tournament.findUnique({ where: { id: tournamentId } });
  if (!tournament) throw new AppError('Tournament not found', 404);

  const updated = await prisma.tournament.update({
    where: { id: tournamentId },
    data: { status },
  });

  await prisma.auditLog.create({
    data: {
      adminId,
      action: 'UPDATE_TOURNAMENT_STATUS',
      entityType: 'tournament',
      entityId: tournamentId,
      oldValue: { status: tournament.status },
      newValue: { status },
    },
  });

  return updated;
};
