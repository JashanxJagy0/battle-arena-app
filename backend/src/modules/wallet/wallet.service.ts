import { Prisma, TransactionType, TransactionStatus } from '@prisma/client';
import axios from 'axios';
import { v4 as uuidv4 } from 'uuid';
import { prisma } from '../../config/database';
import { redis } from '../../config/redis';
import { env } from '../../config/env';
import { AppError } from '../../middleware/error_handler.middleware';
import { SUPPORTED_CURRENCIES } from '../../config/currencies';
import * as cryptoGateway from './crypto_gateway.service';
import type { CreateDepositInput, RequestWithdrawalInput, GetTransactionsQuery } from './wallet.validation';

const CRYPTO_RATES_CACHE_KEY = 'crypto:rates';
const CRYPTO_RATES_TTL = 60; // seconds

export const getBalance = async (userId: string) => {
  const wallet = await prisma.wallet.findUnique({
    where: { userId },
  });

  if (!wallet) {
    throw new AppError('Wallet not found', 404);
  }

  return {
    main_balance: wallet.mainBalance,
    winning_balance: wallet.winningBalance,
    bonus_balance: wallet.bonusBalance,
    locked_balance: wallet.lockedBalance,
    total_deposited: wallet.totalDeposited,
    total_withdrawn: wallet.totalWithdrawn,
    total_wagered: wallet.totalWagered,
    total_won: wallet.totalWon,
    currency: wallet.currency,
  };
};

export const getTransactions = async (userId: string, filters: GetTransactionsQuery) => {
  const { page, limit, type, status, dateFrom, dateTo } = filters;
  const skip = (page - 1) * limit;

  const where: Prisma.TransactionWhereInput = { userId };

  if (type) where.type = type;
  if (status) where.status = status as TransactionStatus;
  if (dateFrom || dateTo) {
    where.createdAt = {};
    if (dateFrom) where.createdAt.gte = new Date(dateFrom);
    if (dateTo) where.createdAt.lte = new Date(dateTo);
  }

  const [total, items] = await Promise.all([
    prisma.transaction.count({ where }),
    prisma.transaction.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      skip,
      take: limit,
    }),
  ]);

  return {
    total,
    page,
    limit,
    totalPages: Math.ceil(total / limit),
    items,
  };
};

export const createDeposit = async (userId: string, data: CreateDepositInput) => {
  const { currency, network, amountUsd } = data;

  // Validate currency + network combo
  const supportedCurrency = SUPPORTED_CURRENCIES.find((c) => c.currency === currency.toUpperCase());
  if (!supportedCurrency) {
    throw new AppError(`Currency ${currency} is not supported`, 400);
  }

  const supportedNetwork = supportedCurrency.networks.find(
    (n) => n.network === network.toLowerCase()
  );
  if (!supportedNetwork) {
    throw new AppError(`Network ${network} is not supported for ${currency}`, 400);
  }

  if (amountUsd < supportedNetwork.minDeposit) {
    throw new AppError(`Minimum deposit for ${currency} is $${supportedNetwork.minDeposit}`, 400);
  }

  const orderId = uuidv4();
  const callbackUrl = `${env.APP_BASE_URL}/api/v1/wallet/deposit/webhook`;

  const payment = await cryptoGateway.createPayment(
    currency.toLowerCase(),
    amountUsd,
    orderId,
    callbackUrl
  );

  // Store pending transaction
  await prisma.transaction.create({
    data: {
      userId,
      type: TransactionType.DEPOSIT,
      amount: new Prisma.Decimal(amountUsd),
      currency: 'USD',
      cryptoCurrency: payment.payCurrency.toUpperCase(),
      cryptoAmount: new Prisma.Decimal(payment.payAmount),
      network: network.toLowerCase(),
      status: TransactionStatus.PENDING,
      gatewayOrderId: orderId,
      gatewayPaymentId: payment.paymentId,
      metadata: {
        payAddress: payment.payAddress,
        expirationEstimateDate: payment.expirationEstimateDate,
      },
    },
  });

  const qrCodeUrl = `https://chart.googleapis.com/chart?chs=250x250&cht=qr&chl=${encodeURIComponent(payment.payAddress)}`;

  return {
    orderId,
    deposit_address: payment.payAddress,
    qr_code_url: qrCodeUrl,
    expected_crypto_amount: payment.payAmount,
    crypto_currency: payment.payCurrency.toUpperCase(),
    amount_usd: amountUsd,
    expiry_time: payment.expirationEstimateDate,
  };
};

export const getDepositByOrderId = async (userId: string, orderId: string) => {
  const transaction = await prisma.transaction.findFirst({
    where: { gatewayOrderId: orderId, userId },
  });

  if (!transaction) {
    throw new AppError('Deposit not found', 404);
  }

  return transaction;
};

export const handleDepositWebhook = async (
  webhookData: Record<string, unknown>,
  signature: string
) => {
  // Verify webhook signature using sorted JSON (NOWPayments IPN verification)
  if (!cryptoGateway.verifyWebhookSignature(webhookData, signature)) {
    throw new AppError('Invalid webhook signature', 401);
  }

  const orderId = String(webhookData.order_id ?? '');
  const paymentStatus = String(webhookData.payment_status ?? '');
  const actuallyPaid = Number(webhookData.actually_paid ?? 0);

  if (paymentStatus !== 'finished' && paymentStatus !== 'confirmed') {
    // Not a completed payment, ignore
    return { processed: false, status: paymentStatus };
  }

  const transaction = await prisma.transaction.findFirst({
    where: { gatewayOrderId: orderId, status: TransactionStatus.PENDING },
  });

  if (!transaction) {
    // Already processed or not found
    return { processed: false, reason: 'transaction_not_found_or_already_processed' };
  }

  const expectedCrypto = Number(transaction.cryptoAmount ?? 0);
  // Allow 1% tolerance for network fees
  const tolerance = expectedCrypto * 0.01;
  if (actuallyPaid < expectedCrypto - tolerance) {
    // Underpaid - mark as failed
    await prisma.transaction.update({
      where: { id: transaction.id },
      data: { status: TransactionStatus.FAILED, adminNote: 'Underpaid' },
    });
    return { processed: false, reason: 'underpaid' };
  }

  await prisma.$transaction(async (tx) => {
    await tx.transaction.update({
      where: { id: transaction.id },
      data: {
        status: TransactionStatus.COMPLETED,
        cryptoTxHash: String(webhookData.outcome_hash ?? webhookData.payment_id ?? ''),
        metadata: {
          ...(transaction.metadata as object),
          actuallyPaid,
          paymentStatus,
        },
      },
    });

    await tx.wallet.update({
      where: { userId: transaction.userId },
      data: {
        mainBalance: { increment: transaction.amount },
        totalDeposited: { increment: transaction.amount },
      },
    });

    await tx.notification.create({
      data: {
        userId: transaction.userId,
        title: 'Deposit Confirmed',
        body: `Your deposit of $${transaction.amount} has been confirmed and credited to your wallet.`,
        type: 'DEPOSIT_CONFIRMED',
        referenceType: 'transaction',
        referenceId: transaction.id,
      },
    });
  });

  return { processed: true };
};

export const requestWithdrawal = async (userId: string, data: RequestWithdrawalInput) => {
  const { amountUsd, currency, network, walletAddress } = data;

  // Validate currency + network combo
  const supportedCurrency = SUPPORTED_CURRENCIES.find((c) => c.currency === currency.toUpperCase());
  if (!supportedCurrency) {
    throw new AppError(`Currency ${currency} is not supported`, 400);
  }

  const supportedNetwork = supportedCurrency.networks.find(
    (n) => n.network === network.toLowerCase()
  );
  if (!supportedNetwork) {
    throw new AppError(`Network ${network} is not supported for ${currency}`, 400);
  }

  if (amountUsd < supportedNetwork.minWithdrawal) {
    throw new AppError(`Minimum withdrawal for ${currency} is $${supportedNetwork.minWithdrawal}`, 400);
  }

  // Validate wallet address format
  if (!supportedNetwork.addressRegex.test(walletAddress)) {
    throw new AppError(`Invalid wallet address for ${currency} on ${network} network`, 400);
  }

  const wallet = await prisma.wallet.findUnique({ where: { userId } });
  if (!wallet) {
    throw new AppError('Wallet not found', 404);
  }

  if (wallet.winningBalance.lt(new Prisma.Decimal(amountUsd))) {
    throw new AppError('Insufficient winning balance', 400);
  }

  // Check daily withdrawal limit
  const dailyLimit = env.DAILY_WITHDRAWAL_LIMIT_USD;
  const now = new Date();
  const startOfDay = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));

  const dailyWithdrawnResult = await prisma.transaction.aggregate({
    where: {
      userId,
      type: TransactionType.WITHDRAWAL,
      status: { in: [TransactionStatus.PENDING, TransactionStatus.PROCESSING, TransactionStatus.COMPLETED] },
      createdAt: { gte: startOfDay },
    },
    _sum: { amount: true },
  });

  const dailyWithdrawn = Number(dailyWithdrawnResult._sum.amount ?? 0);
  if (dailyWithdrawn + amountUsd > dailyLimit) {
    throw new AppError(
      `Daily withdrawal limit of $${dailyLimit} exceeded. Already withdrawn: $${dailyWithdrawn.toFixed(2)}`,
      400
    );
  }

  const withdrawal = await prisma.$transaction(async (tx) => {
    await tx.wallet.update({
      where: { userId },
      data: {
        winningBalance: { decrement: new Prisma.Decimal(amountUsd) },
        lockedBalance: { increment: new Prisma.Decimal(amountUsd) },
      },
    });

    const newTransaction = await tx.transaction.create({
      data: {
        userId,
        type: TransactionType.WITHDRAWAL,
        amount: new Prisma.Decimal(amountUsd),
        currency: 'USD',
        cryptoCurrency: currency.toUpperCase(),
        network: network.toLowerCase(),
        status: TransactionStatus.PENDING,
        metadata: {
          walletAddress,
          currency,
          network,
        },
      },
    });

    await tx.notification.create({
      data: {
        userId,
        title: 'Withdrawal Request Submitted',
        body: `Your withdrawal request for $${amountUsd} has been submitted and is pending review.`,
        type: 'WITHDRAWAL_PENDING',
        referenceType: 'transaction',
        referenceId: newTransaction.id,
      },
    });

    return newTransaction;
  });

  return { withdrawalId: withdrawal.id, status: withdrawal.status };
};

export const getWithdrawal = async (userId: string, id: string) => {
  const transaction = await prisma.transaction.findFirst({
    where: { id, userId, type: TransactionType.WITHDRAWAL },
  });

  if (!transaction) {
    throw new AppError('Withdrawal not found', 404);
  }

  return transaction;
};

export const approveWithdrawal = async (withdrawalId: string, adminId: string) => {
  const transaction = await prisma.transaction.findUnique({
    where: { id: withdrawalId },
  });

  if (!transaction || transaction.type !== TransactionType.WITHDRAWAL) {
    throw new AppError('Withdrawal not found', 404);
  }

  if (transaction.status !== TransactionStatus.PENDING) {
    throw new AppError(`Cannot approve withdrawal with status: ${transaction.status}`, 400);
  }

  const metadata = transaction.metadata as Record<string, string> | null;
  const walletAddress = metadata?.walletAddress;
  const currency = metadata?.currency;

  if (!walletAddress || !currency) {
    throw new AppError('Withdrawal metadata is missing wallet address or currency', 400);
  }

  const payout = await cryptoGateway.createPayout(
    walletAddress,
    currency,
    Number(transaction.amount)
  );

  await prisma.$transaction(async (tx) => {
    await tx.transaction.update({
      where: { id: withdrawalId },
      data: {
        status: TransactionStatus.PROCESSING,
        gatewayPaymentId: payout.id,
        metadata: {
          ...(metadata as object),
          payoutId: payout.id,
          payoutStatus: payout.status,
        },
      },
    });

    await tx.wallet.update({
      where: { userId: transaction.userId },
      data: {
        lockedBalance: { decrement: transaction.amount },
        totalWithdrawn: { increment: transaction.amount },
      },
    });

    await tx.auditLog.create({
      data: {
        adminId,
        action: 'APPROVE_WITHDRAWAL',
        entityType: 'transaction',
        entityId: withdrawalId,
        newValue: { status: TransactionStatus.PROCESSING, payoutId: payout.id },
      },
    });

    await tx.notification.create({
      data: {
        userId: transaction.userId,
        title: 'Withdrawal Approved',
        body: `Your withdrawal of $${transaction.amount} has been approved and is being processed.`,
        type: 'WITHDRAWAL_APPROVED',
        referenceType: 'transaction',
        referenceId: withdrawalId,
      },
    });
  });

  return { status: TransactionStatus.PROCESSING, payoutId: payout.id };
};

export const rejectWithdrawal = async (withdrawalId: string, adminId: string, reason: string) => {
  const transaction = await prisma.transaction.findUnique({
    where: { id: withdrawalId },
  });

  if (!transaction || transaction.type !== TransactionType.WITHDRAWAL) {
    throw new AppError('Withdrawal not found', 404);
  }

  if (transaction.status !== TransactionStatus.PENDING) {
    throw new AppError(`Cannot reject withdrawal with status: ${transaction.status}`, 400);
  }

  await prisma.$transaction(async (tx) => {
    await tx.transaction.update({
      where: { id: withdrawalId },
      data: {
        status: TransactionStatus.FAILED,
        adminNote: reason,
      },
    });

    await tx.wallet.update({
      where: { userId: transaction.userId },
      data: {
        lockedBalance: { decrement: transaction.amount },
        winningBalance: { increment: transaction.amount },
      },
    });

    await tx.auditLog.create({
      data: {
        adminId,
        action: 'REJECT_WITHDRAWAL',
        entityType: 'transaction',
        entityId: withdrawalId,
        newValue: { status: TransactionStatus.FAILED, reason },
      },
    });

    await tx.notification.create({
      data: {
        userId: transaction.userId,
        title: 'Withdrawal Rejected',
        body: `Your withdrawal of $${transaction.amount} was rejected. Reason: ${reason}. Funds have been returned to your winning balance.`,
        type: 'WITHDRAWAL_REJECTED',
        referenceType: 'transaction',
        referenceId: withdrawalId,
      },
    });
  });

  return { status: TransactionStatus.FAILED };
};

export const getCryptoRates = async () => {
  const cached = await redis.get(CRYPTO_RATES_CACHE_KEY);
  if (cached) {
    return JSON.parse(cached);
  }

  const coinIds = SUPPORTED_CURRENCIES.map((c) => c.coingeckoId).join(',');
  const response = await axios.get(`${env.COINGECKO_API_URL}/simple/price`, {
    params: {
      ids: coinIds,
      vs_currencies: 'usd',
    },
    timeout: 10000,
  });

  const data = response.data as Record<string, { usd: number }>;
  const rates: Record<string, number> = {};
  for (const currency of SUPPORTED_CURRENCIES) {
    const rate = data[currency.coingeckoId]?.usd;
    if (rate !== undefined) {
      rates[currency.currency] = rate;
    }
  }

  await redis.setex(CRYPTO_RATES_CACHE_KEY, CRYPTO_RATES_TTL, JSON.stringify(rates));

  return rates;
};

export const getSupportedCurrencies = () => {
  return SUPPORTED_CURRENCIES.map((c) => ({
    currency: c.currency,
    name: c.name,
    networks: c.networks.map((n) => ({
      network: n.network,
      minDeposit: n.minDeposit,
      minWithdrawal: n.minWithdrawal,
      estimatedFee: n.estimatedFee,
    })),
  }));
};
