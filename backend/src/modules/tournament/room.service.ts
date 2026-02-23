import { prisma } from '../../config/database';
import { AppError } from '../../middleware/error_handler.middleware';

const ROOM_REVEAL_MINUTES_BEFORE_START = 15;

export const setRoom = async (
  tournamentId: string,
  roomId: string,
  roomPassword: string,
  adminId: string,
): Promise<void> => {
  const tournament = await prisma.tournament.findUnique({ where: { id: tournamentId } });
  if (!tournament) throw new AppError('Tournament not found', 404);

  // Default roomVisibleAt: 15 minutes before matchStart (if not already set)
  let roomVisibleAt = tournament.roomVisibleAt;
  if (!roomVisibleAt && tournament.matchStart) {
    roomVisibleAt = new Date(
      tournament.matchStart.getTime() - ROOM_REVEAL_MINUTES_BEFORE_START * 60 * 1000,
    );
  }

  await prisma.tournament.update({
    where: { id: tournamentId },
    data: { roomId, roomPassword, roomVisibleAt },
  });

  await prisma.auditLog.create({
    data: {
      adminId,
      action: 'SET_ROOM',
      entityType: 'tournament',
      entityId: tournamentId,
      newValue: { roomId, roomVisibleAt: roomVisibleAt?.toISOString() ?? null },
    },
  });
};

export const getRoomVisibility = async (
  tournamentId: string,
): Promise<{ isVisible: boolean; roomVisibleAt: Date | null }> => {
  const tournament = await prisma.tournament.findUnique({ where: { id: tournamentId } });
  if (!tournament) throw new AppError('Tournament not found', 404);

  const now = new Date();
  const isVisible = tournament.roomVisibleAt ? now >= tournament.roomVisibleAt : false;

  return { isVisible, roomVisibleAt: tournament.roomVisibleAt };
};

// Schedule an in-process notification when the room becomes visible
export const scheduleRoomReveal = async (tournamentId: string): Promise<void> => {
  const tournament = await prisma.tournament.findUnique({
    where: { id: tournamentId },
    include: { participants: { select: { userId: true } } },
  });

  if (!tournament || !tournament.roomVisibleAt) return;

  const delay = tournament.roomVisibleAt.getTime() - Date.now();
  if (delay <= 0) return; // already visible

  setTimeout(async () => {
    try {
      const notifications = tournament.participants.map((p) => ({
        userId: p.userId,
        title: 'Room Details Available 🚪',
        body: `The room ID and password for "${tournament.title}" are now available. Check the app and good luck!`,
        type: 'ROOM_REVEALED',
        referenceType: 'tournament',
        referenceId: tournamentId,
      }));
      await prisma.notification.createMany({ data: notifications });
    } catch (err) {
      console.error(`[scheduleRoomReveal] error for tournament ${tournamentId}:`, err);
    }
  }, delay);
};
