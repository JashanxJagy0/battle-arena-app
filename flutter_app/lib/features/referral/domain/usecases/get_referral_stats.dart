import '../entities/referral.dart';
import '../repositories/referral_repository.dart';

class GetReferralStats {
  final ReferralRepository _repository;
  GetReferralStats(this._repository);

  Future<ReferralStats> call() => _repository.getReferralStats();
}
