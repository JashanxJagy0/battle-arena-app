import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource _remoteDataSource;

  NotificationRepositoryImpl({required NotificationRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<List<AppNotification>> getNotifications() => _remoteDataSource.getNotifications();

  @override
  Future<void> markAsRead(String notificationId) => _remoteDataSource.markAsRead(notificationId);

  @override
  Future<void> markAllAsRead() => _remoteDataSource.markAllAsRead();

  @override
  Future<void> deleteNotification(String notificationId) =>
      _remoteDataSource.deleteNotification(notificationId);
}
