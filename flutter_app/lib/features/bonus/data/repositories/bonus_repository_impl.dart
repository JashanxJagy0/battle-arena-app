import '../../domain/entities/bonus.dart';
import '../../domain/repositories/bonus_repository.dart';
import '../datasources/bonus_remote_datasource.dart';

class BonusRepositoryImpl implements BonusRepository {
  final BonusRemoteDataSource _remoteDataSource;

  BonusRepositoryImpl({required BonusRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<List<Bonus>> getBonuses() => _remoteDataSource.getBonuses();

  @override
  Future<Bonus> getDailyBonus() => _remoteDataSource.getDailyBonus();

  @override
  Future<Bonus?> getWeeklyBonus() => _remoteDataSource.getWeeklyBonus();

  @override
  Future<Bonus?> getMonthlyBonus() => _remoteDataSource.getMonthlyBonus();

  @override
  Future<Bonus> claimBonus(String bonusId) => _remoteDataSource.claimBonus(bonusId);

  @override
  Future<Bonus> redeemPromoCode(String code) => _remoteDataSource.redeemPromoCode(code);

  @override
  Future<Map<String, dynamic>> getWeeklyProgress() => _remoteDataSource.getWeeklyProgress();

  @override
  Future<Map<String, dynamic>> getMonthlyProgress() => _remoteDataSource.getMonthlyProgress();

  @override
  Future<int> getCurrentStreak() => _remoteDataSource.getCurrentStreak();
}
