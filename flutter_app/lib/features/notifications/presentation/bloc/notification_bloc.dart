import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_notifications.dart';
import '../../domain/usecases/mark_notification_read.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/entities/app_notification.dart';
import 'notification_event.dart';
import 'notification_state.dart';

export 'notification_event.dart';
export 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final GetNotifications _getNotifications;
  final MarkNotificationRead _markNotificationRead;
  final NotificationRepository _repository;

  NotificationBloc({
    required GetNotifications getNotifications,
    required MarkNotificationRead markNotificationRead,
    required NotificationRepository repository,
  })  : _getNotifications = getNotifications,
        _markNotificationRead = markNotificationRead,
        _repository = repository,
        super(const NotificationInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<MarkNotificationAsRead>(_onMarkAsRead);
    on<MarkAllNotificationsAsRead>(_onMarkAllAsRead);
    on<DeleteNotificationEvent>(_onDeleteNotification);
  }

  Future<void> _onLoadNotifications(LoadNotifications event, Emitter<NotificationState> emit) async {
    emit(const NotificationLoading());
    try {
      final notifications = await _getNotifications();
      emit(NotificationLoaded(notifications: notifications));
    } catch (e) {
      emit(NotificationError(message: e.toString()));
    }
  }

  Future<void> _onMarkAsRead(MarkNotificationAsRead event, Emitter<NotificationState> emit) async {
    try {
      await _markNotificationRead(event.notificationId);
      final current = state;
      if (current is NotificationLoaded) {
        final updated = current.notifications.map((n) {
          if (n.id == event.notificationId) {
            return AppNotification(
              id: n.id,
              type: n.type,
              title: n.title,
              body: n.body,
              isRead: true,
              createdAt: n.createdAt,
              referenceType: n.referenceType,
              referenceId: n.referenceId,
            );
          }
          return n;
        }).toList();
        emit(current.copyWith(notifications: updated));
      }
    } catch (_) {}
  }

  Future<void> _onMarkAllAsRead(MarkAllNotificationsAsRead event, Emitter<NotificationState> emit) async {
    try {
      await _repository.markAllAsRead();
      final current = state;
      if (current is NotificationLoaded) {
        final updated = current.notifications.map((n) => AppNotification(
              id: n.id,
              type: n.type,
              title: n.title,
              body: n.body,
              isRead: true,
              createdAt: n.createdAt,
              referenceType: n.referenceType,
              referenceId: n.referenceId,
            )).toList();
        emit(current.copyWith(notifications: updated));
      }
    } catch (_) {}
  }

  Future<void> _onDeleteNotification(DeleteNotificationEvent event, Emitter<NotificationState> emit) async {
    try {
      await _repository.deleteNotification(event.notificationId);
      final current = state;
      if (current is NotificationLoaded) {
        final updated = current.notifications.where((n) => n.id != event.notificationId).toList();
        emit(current.copyWith(notifications: updated));
      }
    } catch (_) {}
  }
}
