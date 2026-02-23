import '../repositories/wallet_repository.dart';

class DepositCryptoUseCase {
  final WalletRepository repository;
  DepositCryptoUseCase(this.repository);
  Future<Map<String, dynamic>> call({
    required String currency,
    required String network,
    required double amountUsd,
  }) =>
      repository.createDeposit(currency: currency, network: network, amountUsd: amountUsd);
}
