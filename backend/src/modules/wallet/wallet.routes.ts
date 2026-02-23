import { Router } from 'express';
import * as walletController from './wallet.controller';
import { validate } from '../../middleware/validation.middleware';
import { authenticate } from '../../middleware/auth.middleware';
import {
  createDepositSchema,
  requestWithdrawalSchema,
  getTransactionsQuerySchema,
} from './wallet.validation';

const router = Router();

router.get('/balance', authenticate, walletController.getBalance);
router.get('/transactions', authenticate, validate(getTransactionsQuerySchema, 'query'), walletController.getTransactions);
router.post('/deposit/create', authenticate, validate(createDepositSchema), walletController.createDeposit);
router.get('/deposit/:orderId', authenticate, walletController.getDeposit);
router.post('/deposit/webhook', walletController.handleDepositWebhook);
router.post('/withdraw/request', authenticate, validate(requestWithdrawalSchema), walletController.requestWithdrawal);
router.get('/withdraw/:id', authenticate, walletController.getWithdrawal);
router.get('/crypto-rates', authenticate, walletController.getCryptoRates);
router.get('/supported-currencies', authenticate, walletController.getSupportedCurrencies);

export default router;
