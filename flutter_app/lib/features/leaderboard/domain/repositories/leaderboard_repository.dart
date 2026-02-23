import '../entities/leaderboard_entry.dart';

abstract class LeaderboardRepository {
  Future<List<LeaderboardEntry>> getLeaderboard({
    required String tab,
    required String period,
  });
  Future<LeaderboardEntry?> getMyRank({required String tab, required String period});
}
