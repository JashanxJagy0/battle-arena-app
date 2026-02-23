import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/repositories/leaderboard_repository.dart';
import '../datasources/leaderboard_remote_datasource.dart';

class LeaderboardRepositoryImpl implements LeaderboardRepository {
  final LeaderboardRemoteDataSource _remoteDataSource;

  LeaderboardRepositoryImpl({required LeaderboardRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<List<LeaderboardEntry>> getLeaderboard({required String tab, required String period}) =>
      _remoteDataSource.getLeaderboard(tab: tab, period: period);

  @override
  Future<LeaderboardEntry?> getMyRank({required String tab, required String period}) =>
      _remoteDataSource.getMyRank(tab: tab, period: period);
}
