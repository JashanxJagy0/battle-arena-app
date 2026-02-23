import '../entities/referral.dart';

abstract class ReferralRepository {
  Future<ReferralStats> getReferralStats();
}
