import '../entities/bonus.dart';

abstract class BonusRepository {
  Future<List<Bonus>> getBonuses();
  Future<Bonus> getDailyBonus();
  Future<Bonus?> getWeeklyBonus();
  Future<Bonus?> getMonthlyBonus();
  Future<Bonus> claimBonus(String bonusId);
  Future<Bonus> redeemPromoCode(String code);
  Future<Map<String, dynamic>> getWeeklyProgress();
  Future<Map<String, dynamic>> getMonthlyProgress();
  Future<int> getCurrentStreak();
}
