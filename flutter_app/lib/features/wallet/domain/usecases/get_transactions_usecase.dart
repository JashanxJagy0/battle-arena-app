import '../entities/transaction.dart';
import '../repositories/wallet_repository.dart';

class GetTransactionsUseCase {
  final WalletRepository repository;
  GetTransactionsUseCase(this.repository);
  Future<List<Transaction>> call({String? type, DateTime? from, DateTime? to, int page = 1}) =>
      repository.getTransactions(type: type, from: from, to: to, page: page);
}
