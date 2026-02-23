import 'dotenv/config';
import http from 'http';
import { Server as SocketIOServer } from 'socket.io';
import app from './app';
import { env } from './config/env';
import { prisma } from './config/database';
import { redis } from './config/redis';
import { setIo } from './websockets/socket_manager';
import { setupLudoGateway } from './modules/ludo/ludo.gateway';
import { startTournamentCron } from './jobs/tournament_cron';
import { startBonusCron } from './jobs/bonus_cron';
import { startLeaderboardCron } from './jobs/leaderboard_cron';

const server = http.createServer(app);

const io = new SocketIOServer(server, {
  cors: {
    origin: env.CORS_ORIGIN.split(','),
    methods: ['GET', 'POST'],
    credentials: true,
  },
});

// Register default namespace handlers
io.on('connection', (socket) => {
  console.log(`Socket connected: ${socket.id}`);

  socket.on('join-match', (matchId: string) => {
    socket.join(`match:${matchId}`);
    console.log(`Socket ${socket.id} joined match ${matchId}`);
  });

  socket.on('leave-match', (matchId: string) => {
    socket.leave(`match:${matchId}`);
  });

  socket.on('disconnect', () => {
    console.log(`Socket disconnected: ${socket.id}`);
  });
});

// Initialise socket manager (makes io available to services)
setIo(io);

// Register game-specific WebSocket namespaces
setupLudoGateway(io);

export { io };

const startServer = async () => {
  try {
    await prisma.$connect();
    console.log('✅ Database connected');

    await redis.ping();
    console.log('✅ Redis connected');

    server.listen(env.PORT, () => {
      console.log(`🚀 Server running on port ${env.PORT} in ${env.NODE_ENV} mode`);
      startTournamentCron();
      startBonusCron();
      startLeaderboardCron();
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
};

const shutdown = async (signal: string) => {
  console.log(`${signal} received, shutting down gracefully`);
  await new Promise<void>((resolve) => server.close(() => resolve()));
  await prisma.$disconnect();
  redis.disconnect();
  process.exit(0);
};

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));

startServer();
