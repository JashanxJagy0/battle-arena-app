import '../entities/leaderboard_entry.dart';
import '../repositories/leaderboard_repository.dart';

class GetLeaderboard {
  final LeaderboardRepository _repository;
  GetLeaderboard(this._repository);

  Future<List<LeaderboardEntry>> call({required String tab, required String period}) =>
      _repository.getLeaderboard(tab: tab, period: period);
}
