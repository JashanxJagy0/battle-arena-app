import '../../../../core/network/api_client.dart';
import '../models/leaderboard_model.dart';

class LeaderboardRemoteDataSource {
  final ApiClient _apiClient;

  LeaderboardRemoteDataSource({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<LeaderboardEntryModel>> getLeaderboard({
    required String tab,
    required String period,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/leaderboard',
      queryParameters: {'tab': tab, 'period': period, 'limit': 100},
    );
    final data = response.data!;
    final list = data['leaderboard'] as List<dynamic>? ?? data['data'] as List<dynamic>? ?? [];
    return list.asMap().entries
        .map((e) => LeaderboardEntryModel.fromJson(e.value as Map<String, dynamic>, rank: e.key + 1))
        .toList();
  }

  Future<LeaderboardEntryModel?> getMyRank({required String tab, required String period}) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/leaderboard/me',
        queryParameters: {'tab': tab, 'period': period},
      );
      final data = response.data!;
      final entryData = data['entry'] as Map<String, dynamic>?;
      if (entryData == null) return null;
      return LeaderboardEntryModel.fromJson(entryData);
    } catch (_) {
      return null;
    }
  }
}
