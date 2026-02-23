import '../entities/bonus.dart';
import '../repositories/bonus_repository.dart';

class RedeemPromoCode {
  final BonusRepository _repository;
  RedeemPromoCode(this._repository);

  Future<Bonus> call(String code) => _repository.redeemPromoCode(code);
}
