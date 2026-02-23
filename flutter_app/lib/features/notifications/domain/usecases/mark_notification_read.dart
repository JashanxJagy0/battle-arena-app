import '../repositories/notification_repository.dart';

class MarkNotificationRead {
  final NotificationRepository _repository;
  MarkNotificationRead(this._repository);

  Future<void> call(String notificationId) => _repository.markAsRead(notificationId);
}
