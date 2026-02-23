import '../entities/bonus.dart';
import '../repositories/bonus_repository.dart';

class GetWeeklyBonus {
  final BonusRepository _repository;
  GetWeeklyBonus(this._repository);

  Future<Bonus?> call() => _repository.getWeeklyBonus();
}
