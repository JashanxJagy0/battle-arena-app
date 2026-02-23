import '../../../../core/network/api_client.dart';
import '../models/referral_model.dart';

class ReferralRemoteDataSource {
  final ApiClient _apiClient;

  ReferralRemoteDataSource({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<ReferralStatsModel> getReferralStats() async {
    final response = await _apiClient.get<Map<String, dynamic>>('/referral/stats');
    final data = response.data!;
    return ReferralStatsModel.fromJson(data['stats'] as Map<String, dynamic>? ?? data);
  }
}
