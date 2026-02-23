import '../../../../core/network/api_client.dart';
import '../models/notification_model.dart';

class NotificationRemoteDataSource {
  final ApiClient _apiClient;

  NotificationRemoteDataSource({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<NotificationModel>> getNotifications() async {
    final response = await _apiClient.get<Map<String, dynamic>>('/notifications');
    final data = response.data!;
    final list = data['notifications'] as List<dynamic>? ?? data['data'] as List<dynamic>? ?? [];
    return list.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> markAsRead(String notificationId) async {
    await _apiClient.put<Map<String, dynamic>>('/notifications/$notificationId/read');
  }

  Future<void> markAllAsRead() async {
    await _apiClient.put<Map<String, dynamic>>('/notifications/read-all');
  }

  Future<void> deleteNotification(String notificationId) async {
    await _apiClient.post<Map<String, dynamic>>('/notifications/$notificationId/delete');
  }
}
