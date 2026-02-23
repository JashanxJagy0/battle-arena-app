import '../entities/bonus.dart';
import '../repositories/bonus_repository.dart';

class GetMonthlyBonus {
  final BonusRepository _repository;
  GetMonthlyBonus(this._repository);

  Future<Bonus?> call() => _repository.getMonthlyBonus();
}
