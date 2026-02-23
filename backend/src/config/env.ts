import { z } from 'zod';

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.coerce.number().default(3000),
  APP_NAME: z.string().default('BattleArena'),

  DATABASE_URL: z.string().url(),

  REDIS_URL: z.string().default('redis://localhost:6379'),

  JWT_SECRET: z.string().min(32),
  JWT_REFRESH_SECRET: z.string().min(32),
  JWT_ACCESS_EXPIRES_IN: z.string().default('15m'),
  JWT_REFRESH_EXPIRES_IN: z.string().default('7d'),

  CORS_ORIGIN: z.string().default('http://localhost:3001'),

  RATE_LIMIT_WINDOW_MS: z.coerce.number().default(900000),
  RATE_LIMIT_MAX_REQUESTS: z.coerce.number().default(100),

  FIREBASE_PROJECT_ID: z.string().optional(),
  FIREBASE_PRIVATE_KEY: z.string().optional(),
  FIREBASE_CLIENT_EMAIL: z.string().optional(),

  TWILIO_ACCOUNT_SID: z.string().optional(),
  TWILIO_AUTH_TOKEN: z.string().optional(),
  TWILIO_PHONE_NUMBER: z.string().optional(),

  ADMIN_EMAIL: z.string().email().default('admin@battlearena.com'),
  ADMIN_PASSWORD: z.string().min(8),

  NOWPAYMENTS_API_KEY: z.string().optional(),
  NOWPAYMENTS_IPN_SECRET: z.string().optional(),
  NOWPAYMENTS_API_URL: z.string().default('https://api.nowpayments.io/v1'),

  APP_BASE_URL: z.string().default('http://localhost:3000'),
  COINGECKO_API_URL: z.string().default('https://api.coingecko.com/api/v3'),

  DAILY_WITHDRAWAL_LIMIT_USD: z.coerce.number().default(500),
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  console.error('❌ Invalid environment variables:');
  console.error(parsed.error.flatten().fieldErrors);
  process.exit(1);
}

export const env = parsed.data;
export type Env = typeof env;
