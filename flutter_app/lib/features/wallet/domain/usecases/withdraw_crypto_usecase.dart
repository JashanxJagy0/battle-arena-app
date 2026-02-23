import '../repositories/wallet_repository.dart';

class WithdrawCryptoUseCase {
  final WalletRepository repository;
  WithdrawCryptoUseCase(this.repository);
  Future<Map<String, dynamic>> call({
    required String currency,
    required String network,
    required double amountUsd,
    required String walletAddress,
  }) =>
      repository.requestWithdrawal(
        currency: currency,
        network: network,
        amountUsd: amountUsd,
        walletAddress: walletAddress,
      );
}
