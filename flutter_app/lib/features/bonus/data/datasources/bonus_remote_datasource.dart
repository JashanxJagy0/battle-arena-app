import '../../../../core/network/api_client.dart';
import '../models/bonus_model.dart';

class BonusRemoteDataSource {
  final ApiClient _apiClient;

  BonusRemoteDataSource({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<BonusModel>> getBonuses() async {
    final response = await _apiClient.get<Map<String, dynamic>>('/bonuses');
    final data = response.data!;
    final list = data['bonuses'] as List<dynamic>? ?? data['data'] as List<dynamic>? ?? [];
    return list.map((e) => BonusModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<BonusModel> getDailyBonus() async {
    final response = await _apiClient.get<Map<String, dynamic>>('/bonuses/daily');
    final data = response.data!;
    return BonusModel.fromJson(data['bonus'] as Map<String, dynamic>? ?? data);
  }

  Future<BonusModel?> getWeeklyBonus() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>('/bonuses/weekly');
      final data = response.data!;
      final bonusData = data['bonus'] as Map<String, dynamic>?;
      if (bonusData == null) return null;
      return BonusModel.fromJson(bonusData);
    } catch (_) {
      return null;
    }
  }

  Future<BonusModel?> getMonthlyBonus() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>('/bonuses/monthly');
      final data = response.data!;
      final bonusData = data['bonus'] as Map<String, dynamic>?;
      if (bonusData == null) return null;
      return BonusModel.fromJson(bonusData);
    } catch (_) {
      return null;
    }
  }

  Future<BonusModel> claimBonus(String bonusId) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/bonuses/$bonusId/claim',
    );
    final data = response.data!;
    return BonusModel.fromJson(data['bonus'] as Map<String, dynamic>? ?? data);
  }

  Future<BonusModel> redeemPromoCode(String code) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/bonuses/redeem',
      data: {'code': code},
    );
    final data = response.data!;
    return BonusModel.fromJson(data['bonus'] as Map<String, dynamic>? ?? data);
  }

  Future<Map<String, dynamic>> getWeeklyProgress() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>('/bonuses/weekly/progress');
      return response.data ?? {};
    } catch (_) {
      return {'gamesPlayed': 0, 'milestones': []};
    }
  }

  Future<Map<String, dynamic>> getMonthlyProgress() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>('/bonuses/monthly/progress');
      return response.data ?? {};
    } catch (_) {
      return {'totalWagered': 0, 'tiers': []};
    }
  }

  Future<int> getCurrentStreak() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>('/bonuses/streak');
      final data = response.data!;
      return data['streak'] as int? ?? 0;
    } catch (_) {
      return 0;
    }
  }
}
