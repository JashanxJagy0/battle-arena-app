import '../entities/bonus.dart';
import '../repositories/bonus_repository.dart';

class ClaimDailyBonus {
  final BonusRepository _repository;
  ClaimDailyBonus(this._repository);

  Future<Bonus> call(String bonusId) => _repository.claimBonus(bonusId);
}
