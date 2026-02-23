import '../entities/wallet.dart';
import '../repositories/wallet_repository.dart';

class GetBalanceUseCase {
  final WalletRepository repository;
  GetBalanceUseCase(this.repository);
  Future<Wallet> call() => repository.getBalance();
}
