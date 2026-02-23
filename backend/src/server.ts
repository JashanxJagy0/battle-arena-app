import 'dotenv/config';
import http from 'http';
import { Server as SocketIOServer } from 'socket.io';
import app from './app';
import { env } from './config/env';
import { prisma } from './config/database';
import { redis } from './config/redis';

const server = http.createServer(app);

const io = new SocketIOServer(server, {
  cors: {
    origin: env.CORS_ORIGIN.split(','),
    methods: ['GET', 'POST'],
    credentials: true,
  },
});

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

export { io };

const startServer = async () => {
  try {
    await prisma.$connect();
    console.log('✅ Database connected');

    await redis.ping();
    console.log('✅ Redis connected');

    server.listen(env.PORT, () => {
      console.log(`🚀 Server running on port ${env.PORT} in ${env.NODE_ENV} mode`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
};

process.on('SIGTERM', async () => {
  console.log('SIGTERM received, shutting down gracefully');
  server.close();
  await prisma.$disconnect();
  redis.disconnect();
  process.exit(0);
});

startServer();
