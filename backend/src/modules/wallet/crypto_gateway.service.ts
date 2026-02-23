import axios, { AxiosInstance } from 'axios';
import crypto from 'crypto';
import { env } from '../../config/env';

const RETRY_ATTEMPTS = 3;
const RETRY_DELAY_MS = 1000;

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

const createAxiosInstance = (): AxiosInstance => {
  return axios.create({
    baseURL: env.NOWPAYMENTS_API_URL,
    headers: {
      'x-api-key': env.NOWPAYMENTS_API_KEY || '',
      'Content-Type': 'application/json',
    },
    timeout: 15000,
  });
};

const withRetry = async <T>(fn: () => Promise<T>, attempts = RETRY_ATTEMPTS): Promise<T> => {
  for (let i = 0; i < attempts; i++) {
    try {
      return await fn();
    } catch (error) {
      if (i === attempts - 1) throw error;
      await sleep(RETRY_DELAY_MS * (i + 1));
    }
  }
  throw new Error('Max retry attempts reached');
};

export interface CreatePaymentResult {
  paymentId: string;
  paymentStatus: string;
  payAddress: string;
  payAmount: number;
  payCurrency: string;
  orderId: string;
  expirationEstimateDate: string;
}

export interface PaymentStatus {
  paymentId: string;
  paymentStatus: string;
  payAddress: string;
  payAmount: number;
  actuallyPaid: number;
  payCurrency: string;
  orderId: string;
}

export interface CreatePayoutResult {
  id: string;
  status: string;
  address: string;
  amount: number;
  currency: string;
}

export const createPayment = async (
  currency: string,
  amountUsd: number,
  orderId: string,
  callbackUrl: string
): Promise<CreatePaymentResult> => {
  const client = createAxiosInstance();

  return withRetry(async () => {
    const response = await client.post('/payment', {
      price_amount: amountUsd,
      price_currency: 'usd',
      pay_currency: currency.toLowerCase(),
      order_id: orderId,
      ipn_callback_url: callbackUrl,
      is_fixed_rate: false,
      is_fee_paid_by_user: false,
    });

    const data = response.data;
    return {
      paymentId: String(data.payment_id),
      paymentStatus: data.payment_status,
      payAddress: data.pay_address,
      payAmount: Number(data.pay_amount),
      payCurrency: data.pay_currency,
      orderId: data.order_id,
      expirationEstimateDate: data.expiration_estimate_date,
    };
  });
};

export const getPaymentStatus = async (paymentId: string): Promise<PaymentStatus> => {
  const client = createAxiosInstance();

  return withRetry(async () => {
    const response = await client.get(`/payment/${paymentId}`);
    const data = response.data;
    return {
      paymentId: String(data.payment_id),
      paymentStatus: data.payment_status,
      payAddress: data.pay_address,
      payAmount: Number(data.pay_amount),
      actuallyPaid: Number(data.actually_paid ?? 0),
      payCurrency: data.pay_currency,
      orderId: data.order_id,
    };
  });
};

export const createPayout = async (
  address: string,
  currency: string,
  amount: number
): Promise<CreatePayoutResult> => {
  const client = createAxiosInstance();

  return withRetry(async () => {
    const response = await client.post('/payout', {
      address,
      currency: currency.toLowerCase(),
      amount,
    });

    const data = response.data;
    return {
      id: String(data.id),
      status: data.status,
      address: data.address,
      amount: Number(data.amount),
      currency: data.currency,
    };
  });
};

export const verifyWebhookSignature = (payload: Record<string, unknown>, signature: string): boolean => {
  const secret = env.NOWPAYMENTS_IPN_SECRET;
  if (!secret) return false;

  // NOWPayments signs the alphabetically sorted JSON payload
  const sortedPayload = JSON.stringify(
    Object.fromEntries(Object.entries(payload).sort(([a], [b]) => a.localeCompare(b)))
  );

  const hmac = crypto.createHmac('sha512', secret);
  hmac.update(sortedPayload);
  const expectedSignature = hmac.digest('hex');

  try {
    return crypto.timingSafeEqual(
      Buffer.from(expectedSignature, 'hex'),
      Buffer.from(signature.toLowerCase(), 'hex')
    );
  } catch {
    return false;
  }
};
