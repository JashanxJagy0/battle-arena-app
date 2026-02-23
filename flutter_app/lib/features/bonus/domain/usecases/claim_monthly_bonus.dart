import '../entities/bonus.dart';
import '../repositories/bonus_repository.dart';

class ClaimMonthlyBonus {
  final BonusRepository _repository;
  ClaimMonthlyBonus(this._repository);

  Future<Bonus> call(String bonusId) => _repository.claimBonus(bonusId);
}
