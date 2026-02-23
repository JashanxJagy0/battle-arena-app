import '../entities/bonus.dart';
import '../repositories/bonus_repository.dart';

class ClaimWeeklyBonus {
  final BonusRepository _repository;
  ClaimWeeklyBonus(this._repository);

  Future<Bonus> call(String bonusId) => _repository.claimBonus(bonusId);
}
