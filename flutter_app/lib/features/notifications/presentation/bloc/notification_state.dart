import 'package:equatable/equatable.dart';
import '../../domain/entities/app_notification.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();
  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

class NotificationLoading extends NotificationState {
  const NotificationLoading();
}

class NotificationLoaded extends NotificationState {
  final List<AppNotification> notifications;
  const NotificationLoaded({required this.notifications});
  @override
  List<Object?> get props => [notifications];

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationLoaded copyWith({List<AppNotification>? notifications}) {
    return NotificationLoaded(notifications: notifications ?? this.notifications);
  }
}

class NotificationError extends NotificationState {
  final String message;
  const NotificationError({required this.message});
  @override
  List<Object?> get props => [message];
}
