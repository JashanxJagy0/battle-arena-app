import { Server as SocketIOServer } from 'socket.io';

/**
 * Centralized Socket.IO instance store.
 *
 * Usage:
 *   1. Call `setIo(io)` once during server startup (in server.ts).
 *   2. Call `getIo()` anywhere in the codebase to access the io instance.
 *
 * Individual namespace handlers (e.g. ludo.gateway) are registered from
 * server.ts after calling setIo, keeping this module dependency-free.
 */

let _io: SocketIOServer | null = null;

export const setIo = (io: SocketIOServer): void => {
  _io = io;
};

export const getIo = (): SocketIOServer => {
  if (!_io) throw new Error('Socket.IO server has not been initialised yet');
  return _io;
};
