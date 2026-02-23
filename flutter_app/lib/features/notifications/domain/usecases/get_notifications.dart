import '../entities/app_notification.dart';
import '../repositories/notification_repository.dart';

class GetNotifications {
  final NotificationRepository _repository;
  GetNotifications(this._repository);

  Future<List<AppNotification>> call() => _repository.getNotifications();
}
