import crypto from 'crypto';
import { LudoColor } from '@prisma/client';

// ─── Board Constants ──────────────────────────────────────────────────────────

/** Absolute board positions that are safe (pieces cannot be killed here). */
export const SAFE_ZONES = new Set([0, 8, 13, 21, 26, 34, 39, 47]);

/** Absolute starting position on the main track for each color. */
export const COLOR_OFFSETS: Record<LudoColor, number> = {
  RED: 0,
  GREEN: 13,
  YELLOW: 26,
  BLUE: 39,
};

/** Clockwise color turn order. */
export const COLOR_ORDER: LudoColor[] = ['RED', 'GREEN', 'YELLOW', 'BLUE'];

export const HOME_COLUMN_START = 52; // First home-column local position
export const HOME_POSITION = 57;    // Piece is fully home
export const MAIN_TRACK_SIZE = 52;  // Number of squares on the main track

// ─── Types ────────────────────────────────────────────────────────────────────

/**
 * A single game piece belonging to a player.
 * position:
 *   -1          → in yard (not yet on board)
 *   0 – 51      → on main track (relative to the player's own starting square)
 *   52 – 56     → in the player's home column
 *   57          → fully home / finished
 */
export interface PieceState {
  id: string;
  position: number;
}

export interface ValidMove {
  pieceId: string;
  fromPosition: number;
  toPosition: number;
  isKill: boolean;
  isHomeEntry: boolean;
  killedUserId?: string;
  killedPieceId?: string;
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

/** Creates the initial four pieces for a player (all in yard). */
export const initPieces = (): PieceState[] => [
  { id: 'piece_0', position: -1 },
  { id: 'piece_1', position: -1 },
  { id: 'piece_2', position: -1 },
  { id: 'piece_3', position: -1 },
];

/**
 * Converts a local (player-relative) main-track position to the absolute
 * position on the shared board.  Returns -1 for non-main-track positions.
 */
export const toAbsolutePosition = (localPos: number, color: LudoColor): number => {
  if (localPos < 0 || localPos >= HOME_COLUMN_START) return -1;
  return (localPos + COLOR_OFFSETS[color]) % MAIN_TRACK_SIZE;
};

export const isSafeZone = (absolutePos: number): boolean =>
  SAFE_ZONES.has(absolutePos);

// ─── Core Engine Functions ────────────────────────────────────────────────────

/** Rolls a fair die using a cryptographically secure RNG. Returns 1 – 6. */
export const rollDice = (): number => crypto.randomInt(1, 7);

/**
 * Returns all legal moves for `userId` in `matchId` given a `diceValue`.
 *
 * Rules applied:
 *  – Yard pieces need a 6 to come out.
 *  – Pieces cannot overshoot the home position (57).
 *  – A destination blocked by 2+ opponent pieces is invalid.
 *  – A single opponent piece on a non-safe square is killed.
 */
export const getValidMoves = (
  diceValue: number,
  myColor: LudoColor,
  myUserId: string,
  myPieces: PieceState[],
  allPlayers: { userId: string; color: LudoColor; pieces: PieceState[] }[],
): ValidMove[] => {
  // Build absolute-position map for all pieces on the main track
  const absMap = new Map<number, { userId: string; pieceId: string }[]>();

  for (const player of allPlayers) {
    for (const piece of player.pieces) {
      if (piece.position >= 0 && piece.position < HOME_COLUMN_START) {
        const absPos = toAbsolutePosition(piece.position, player.color);
        if (absPos >= 0) {
          if (!absMap.has(absPos)) absMap.set(absPos, []);
          absMap.get(absPos)!.push({ userId: player.userId, pieceId: piece.id });
        }
      }
    }
  }

  const validMoves: ValidMove[] = [];

  for (const piece of myPieces) {
    if (piece.position === HOME_POSITION) continue; // already home

    let toPosition: number;

    if (piece.position === -1) {
      // Piece is in yard — needs a 6 to come out
      if (diceValue !== 6) continue;
      toPosition = 0;
    } else {
      toPosition = piece.position + diceValue;
      if (toPosition > HOME_POSITION) continue; // cannot overshoot
    }

    let isKill = false;
    let isHomeEntry = false;
    let killedUserId: string | undefined;
    let killedPieceId: string | undefined;

    if (toPosition >= 0 && toPosition < HOME_COLUMN_START) {
      // Destination is on the main track — check for blocks / kills
      const toAbsPos = toAbsolutePosition(toPosition, myColor);
      const piecesAtDest = absMap.get(toAbsPos) ?? [];
      const opponentPieces = piecesAtDest.filter((p) => p.userId !== myUserId);

      if (opponentPieces.length >= 2) continue; // blocked by a double

      if (opponentPieces.length === 1 && !isSafeZone(toAbsPos)) {
        isKill = true;
        killedUserId = opponentPieces[0].userId;
        killedPieceId = opponentPieces[0].pieceId;
      }
    } else if (toPosition >= HOME_COLUMN_START) {
      isHomeEntry = true;
    }

    validMoves.push({
      pieceId: piece.id,
      fromPosition: piece.position,
      toPosition,
      isKill,
      isHomeEntry,
      killedUserId,
      killedPieceId,
    });
  }

  return validMoves;
};

/**
 * Returns the next active (non-eliminated) player in turn order after
 * `currentColor`, or null if no such player exists.
 */
export const getNextTurnPlayer = (
  currentColor: LudoColor,
  players: { userId: string; color: LudoColor; isEliminated: boolean }[],
): { userId: string; color: LudoColor } | null => {
  const currentIdx = COLOR_ORDER.indexOf(currentColor);

  for (let i = 1; i <= COLOR_ORDER.length; i++) {
    const nextColor = COLOR_ORDER[(currentIdx + i) % COLOR_ORDER.length];
    const nextPlayer = players.find((p) => p.color === nextColor && !p.isEliminated);
    if (nextPlayer) return { userId: nextPlayer.userId, color: nextPlayer.color };
  }
  return null;
};

/**
 * Determines the move type label for logging (LudoMoveType enum value).
 */
export const classifyMoveType = (
  toPosition: number,
  isKill: boolean,
  isPassed: boolean,
  playerColor: LudoColor,
): string => {
  if (isPassed) return 'PASS';
  if (isKill) return 'KILL';
  if (toPosition === HOME_POSITION) return 'HOME';
  if (toPosition >= HOME_COLUMN_START) return 'HOME_ENTRY';
  if (isSafeZone(toAbsolutePosition(toPosition, playerColor))) return 'SAFE';
  return 'MOVE';
};
