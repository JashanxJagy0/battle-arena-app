import '../../domain/entities/wallet.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/crypto_rate.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_remote_datasource.dart';

class WalletRepositoryImpl implements WalletRepository {
  final WalletRemoteDataSource _remoteDataSource;

  WalletRepositoryImpl({required WalletRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Wallet> getBalance() => _remoteDataSource.getBalance();

  @override
  Future<List<Transaction>> getTransactions({
    String? type,
    DateTime? from,
    DateTime? to,
    int page = 1,
  }) =>
      _remoteDataSource.getTransactions(type: type, from: from, to: to, page: page);

  @override
  Future<Map<String, dynamic>> createDeposit({
    required String currency,
    required String network,
    required double amountUsd,
  }) =>
      _remoteDataSource.createDeposit(
          currency: currency, network: network, amountUsd: amountUsd);

  @override
  Future<Map<String, dynamic>> requestWithdrawal({
    required String currency,
    required String network,
    required double amountUsd,
    required String walletAddress,
  }) =>
      _remoteDataSource.requestWithdrawal(
        currency: currency,
        network: network,
        amountUsd: amountUsd,
        walletAddress: walletAddress,
      );

  @override
  Future<List<CryptoRate>> getCryptoRates() => _remoteDataSource.getCryptoRates();

  @override
  Future<Map<String, dynamic>> checkDepositStatus(String depositId) =>
      _remoteDataSource.checkDepositStatus(depositId);
}
