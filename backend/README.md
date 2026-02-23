# Battle Arena Backend

A robust Node.js/TypeScript backend for the Battle Arena app — a competitive gaming platform supporting Ludo PvP matches and Free Fire tournament betting.

## Overview

Battle Arena Backend provides:
- User authentication (JWT + OTP via phone)
- Ludo PvP real-time match management via Socket.IO
- Free Fire tournament registration and prize management
- Wallet system with crypto payment support
- Bonus/referral engine
- Admin panel APIs

## Tech Stack

| Layer | Technology |
|---|---|
| Runtime | Node.js 20 |
| Language | TypeScript 5 |
| Framework | Express 4 |
| ORM | Prisma 5 |
| Database | PostgreSQL 15 |
| Cache / Session | Redis 7 (ioredis) |
| Real-time | Socket.IO 4 |
| Auth | JWT + bcryptjs |
| Validation | Zod |
| Containerisation | Docker / Docker Compose |

## Prerequisites

- Node.js >= 20
- npm >= 9
- PostgreSQL 15
- Redis 7
- Docker & Docker Compose (optional)

## Project Structure

```
backend/
├── prisma/
│   ├── schema.prisma        # Database schema
│   └── seed.ts              # Database seed script
├── src/
│   ├── config/
│   │   ├── database.ts      # Prisma client singleton
│   │   ├── env.ts           # Zod-validated env config
│   │   └── redis.ts         # Redis client
│   ├── middleware/
│   │   ├── auth.middleware.ts
│   │   ├── admin.middleware.ts
│   │   ├── error_handler.middleware.ts
│   │   ├── rate_limiter.middleware.ts
│   │   └── validation.middleware.ts
│   ├── modules/
│   │   ├── auth/
│   │   │   ├── auth.controller.ts
│   │   │   ├── auth.routes.ts
│   │   │   ├── auth.service.ts
│   │   │   └── auth.validation.ts
│   │   └── user/
│   │       ├── user.controller.ts
│   │       ├── user.routes.ts
│   │       └── user.service.ts
│   ├── routes/
│   │   └── index.ts
│   ├── app.ts
│   └── server.ts
├── .env.example
├── .dockerignore
├── Dockerfile
├── package.json
└── tsconfig.json
```

## Installation

```bash
cd backend
npm install
cp .env.example .env
# Edit .env with your values
```

## Environment Variables

| Variable | Description | Default |
|---|---|---|
| `NODE_ENV` | Environment | `development` |
| `PORT` | Server port | `3000` |
| `DATABASE_URL` | PostgreSQL connection string | — |
| `REDIS_URL` | Redis connection string | `redis://localhost:6379` |
| `JWT_SECRET` | JWT signing secret (min 32 chars) | — |
| `JWT_REFRESH_SECRET` | Refresh token secret (min 32 chars) | — |
| `JWT_ACCESS_EXPIRES_IN` | Access token TTL | `15m` |
| `JWT_REFRESH_EXPIRES_IN` | Refresh token TTL | `7d` |
| `CORS_ORIGIN` | Comma-separated allowed origins | `http://localhost:3001` |
| `RATE_LIMIT_WINDOW_MS` | Rate limit window in ms | `900000` |
| `RATE_LIMIT_MAX_REQUESTS` | Max requests per window | `100` |
| `ADMIN_EMAIL` | Seed admin email | `admin@battlearena.com` |
| `ADMIN_PASSWORD` | Seed admin password | `admin123456` |

See `.env.example` for the full list.

## Running Locally

```bash
# 1. Start PostgreSQL and Redis (or use Docker)
docker compose up postgres redis -d

# 2. Generate Prisma client
npm run prisma:generate

# 3. Run migrations
npm run prisma:migrate

# 4. Seed the database
npm run seed

# 5. Start dev server
npm run dev
```

The API will be available at `http://localhost:3000`.

## Docker Setup

```bash
# Build and start all services
docker compose up --build

# Run in background
docker compose up -d --build

# Stop services
docker compose down
```

Services exposed:
- Backend API: `http://localhost:3000`
- PostgreSQL: `localhost:5432`
- Redis: `localhost:6379`
- Admin (nginx): `http://localhost:8080`

## API Endpoints

### Health
| Method | Path | Description |
|---|---|---|
| GET | `/health` | Health check |

### Auth — `/api/v1/auth`
| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/register` | — | Register new user |
| POST | `/login` | — | Login with username/phone + password |
| POST | `/send-otp` | — | Send OTP to phone |
| POST | `/verify-otp` | — | Verify OTP |
| POST | `/refresh-token` | — | Refresh access token |
| POST | `/logout` | ✅ | Logout and invalidate token |
| GET | `/me` | ✅ | Get current user profile |

### Users — `/api/v1/users`
| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/profile` | ✅ | Get own profile |
| PUT | `/profile` | ✅ | Update profile |
| PUT | `/free-fire-id` | ✅ | Link Free Fire account |
| GET | `/stats` | ✅ | Get user stats and wager history |

## Database Schema Overview

| Model | Purpose |
|---|---|
| `User` | Player accounts with stats and role |
| `Wallet` | INR balances (main / winning / bonus / locked) |
| `CryptoWallet` | Crypto deposit/withdrawal addresses |
| `Transaction` | Full ledger of all financial movements |
| `LudoMatch` | Ludo PvP match state |
| `LudoMatchPlayer` | Per-player state within a match |
| `LudoMove` | Individual dice roll / move record |
| `Tournament` | Free Fire tournament metadata |
| `TournamentParticipant` | Registration and result per player |
| `Wager` | Bet record linking user → match/tournament |
| `Bonus` | Issued bonus credits |
| `BonusSchedule` | Bonus rules (daily login, referral, etc.) |
| `Referral` | Referral tracking |
| `Notification` | In-app notifications |
| `Dispute` | Match dispute submissions |
| `AuditLog` | Admin action audit trail |
| `AppSetting` | Key-value runtime configuration |
| `PromoCode` | Promotional coupon codes |

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Commit your changes following conventional commits
4. Push and open a Pull Request
