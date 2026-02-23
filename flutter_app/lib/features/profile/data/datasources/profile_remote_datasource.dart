import '../../../../core/network/api_client.dart';
import '../models/profile_model.dart';

class ProfileRemoteDataSource {
  final ApiClient _apiClient;

  ProfileRemoteDataSource({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<ProfileModel> getProfile() async {
    final response = await _apiClient.get<Map<String, dynamic>>('/user/profile');
    final data = response.data!;
    return ProfileModel.fromJson(data['user'] as Map<String, dynamic>? ?? data);
  }

  Future<ProfileModel> updateProfile({
    String? username,
    String? email,
    String? freefireUid,
    String? freefireIgn,
    String? avatarUrl,
  }) async {
    final body = <String, dynamic>{};
    if (username != null) body['username'] = username;
    if (email != null) body['email'] = email;
    if (freefireUid != null) body['freefireUid'] = freefireUid;
    if (freefireIgn != null) body['freefireIgn'] = freefireIgn;
    if (avatarUrl != null) body['avatarUrl'] = avatarUrl;

    final response = await _apiClient.put<Map<String, dynamic>>('/user/profile', data: body);
    final data = response.data!;
    return ProfileModel.fromJson(data['user'] as Map<String, dynamic>? ?? data);
  }

  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    await _apiClient.put<Map<String, dynamic>>(
      '/user/change-password',
      data: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }

  Future<void> deleteAccount() async {
    await _apiClient.post<Map<String, dynamic>>('/user/delete-account');
  }
}
