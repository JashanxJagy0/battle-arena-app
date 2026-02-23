import '../../../../core/network/api_client.dart';
import '../models/wager_model.dart';

class WagerRemoteDataSource {
  final ApiClient _apiClient;

  WagerRemoteDataSource({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<WagerModel>> getWagers({String? period, int page = 1}) async {
    final params = <String, dynamic>{'page': page, 'limit': 20};
    if (period != null) params['period'] = period;
    final response = await _apiClient.get<Map<String, dynamic>>('/wagers', queryParameters: params);
    final data = response.data!;
    final list = data['wagers'] as List<dynamic>? ?? data['data'] as List<dynamic>? ?? [];
    return list.map((e) => WagerModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<WagerStatsModel> getWagerStats({String? period}) async {
    try {
      final params = <String, dynamic>{};
      if (period != null) params['period'] = period;
      final response = await _apiClient.get<Map<String, dynamic>>('/wagers/stats', queryParameters: params);
      final data = response.data!;
      return WagerStatsModel.fromJson(data['stats'] as Map<String, dynamic>? ?? data);
    } catch (_) {
      return const WagerStatsModel(
        totalWagered: 0, totalWon: 0, totalLost: 0, netProfit: 0, roi: 0, totalBets: 0,
      );
    }
  }

  Future<WagerModel> getWagerDetail(String wagerId) async {
    final response = await _apiClient.get<Map<String, dynamic>>('/wagers/$wagerId');
    final data = response.data!;
    return WagerModel.fromJson(data['wager'] as Map<String, dynamic>? ?? data);
  }

  Future<List<Map<String, dynamic>>> getChartData({String period = 'daily'}) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/wagers/chart', queryParameters: {'period': period},
      );
      final data = response.data!;
      return (data['data'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }
}
