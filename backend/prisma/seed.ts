import { PrismaClient, Role, BonusType, BonusFrequency } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting database seed...');

  // Create admin user
  const adminPassword = process.env.ADMIN_PASSWORD;
  if (!adminPassword) {
    throw new Error('ADMIN_PASSWORD environment variable must be set before seeding');
  }
  const adminPasswordHash = await bcrypt.hash(adminPassword, 12);

  const admin = await prisma.user.upsert({
    where: { username: 'admin' },
    update: {},
    create: {
      username: 'admin',
      phone: '+910000000000',
      email: process.env.ADMIN_EMAIL || 'admin@battlearena.com',
      passwordHash: adminPasswordHash,
      referralCode: 'ADMIN00',
      role: Role.ADMIN,
      isVerified: true,
    },
  });

  console.log('✅ Admin user created:', admin.username);

  // Create admin wallet
  await prisma.wallet.upsert({
    where: { userId: admin.id },
    update: {},
    create: { userId: admin.id },
  });

  // Default app settings
  const settings = [
    { key: 'platform_fee_percentage', value: 10, description: 'Platform fee percentage on all matches' },
    { key: 'min_deposit_amount', value: 100, description: 'Minimum deposit amount in INR' },
    { key: 'max_deposit_amount', value: 50000, description: 'Maximum deposit amount in INR' },
    { key: 'min_withdrawal_amount', value: 200, description: 'Minimum withdrawal amount in INR' },
    { key: 'referral_bonus_amount', value: 50, description: 'Referral bonus amount in INR' },
    { key: 'daily_login_bonus', value: 10, description: 'Daily login bonus amount in INR' },
    { key: 'ludo_min_entry_fee', value: 10, description: 'Minimum Ludo entry fee in INR' },
    { key: 'ludo_max_entry_fee', value: 5000, description: 'Maximum Ludo entry fee in INR' },
    { key: 'maintenance_mode', value: false, description: 'Enable/disable maintenance mode' },
  ];

  for (const setting of settings) {
    await prisma.appSetting.upsert({
      where: { key: setting.key },
      update: {},
      create: {
        key: setting.key,
        value: setting.value,
        description: setting.description,
        updatedById: admin.id,
      },
    });
  }

  console.log('✅ App settings created');

  // Sample bonus schedules
  const bonusSchedules = [
    {
      bonusType: BonusType.DAILY_LOGIN,
      frequency: BonusFrequency.DAILY,
      baseAmount: 10,
      multiplierRules: { streak_3: 1.5, streak_7: 2.0, streak_30: 3.0 },
      minGamesRequired: 0,
      minDepositRequired: 0,
    },
    {
      bonusType: BonusType.WEEKLY_PLAY,
      frequency: BonusFrequency.WEEKLY,
      baseAmount: 50,
      multiplierRules: { games_10: 1.5, games_20: 2.0 },
      minGamesRequired: 5,
      minDepositRequired: 0,
    },
    {
      bonusType: BonusType.MONTHLY_LOYALTY,
      frequency: BonusFrequency.MONTHLY,
      baseAmount: 200,
      multiplierRules: { games_50: 1.5, games_100: 2.0 },
      minGamesRequired: 20,
      minDepositRequired: 500,
    },
    {
      bonusType: BonusType.FIRST_DEPOSIT,
      frequency: BonusFrequency.ONE_TIME,
      baseAmount: 100,
      multiplierRules: { deposit_500: 1.5, deposit_1000: 2.0 },
      minGamesRequired: 0,
      minDepositRequired: 100,
    },
  ];

  for (const schedule of bonusSchedules) {
    await prisma.bonusSchedule.create({ data: schedule });
  }

  console.log('✅ Bonus schedules created');
  console.log('🌱 Seed completed successfully!');
}

main()
  .catch((error) => {
    console.error('Seed failed:', error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
