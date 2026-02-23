import '../entities/wallet.dart';
import '../entities/transaction.dart';
import '../entities/crypto_rate.dart';

abstract class WalletRepository {
  Future<Wallet> getBalance();
  Future<List<Transaction>> getTransactions({String? type, DateTime? from, DateTime? to, int page = 1});
  Future<Map<String, dynamic>> createDeposit({
    required String currency,
    required String network,
    required double amountUsd,
  });
  Future<Map<String, dynamic>> requestWithdrawal({
    required String currency,
    required String network,
    required double amountUsd,
    required String walletAddress,
  });
  Future<List<CryptoRate>> getCryptoRates();
  Future<Map<String, dynamic>> checkDepositStatus(String depositId);
}
