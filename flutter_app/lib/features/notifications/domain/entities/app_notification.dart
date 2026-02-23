import 'package:equatable/equatable.dart';

enum NotificationType { tournament, wager, bonus, referral, wallet, system }

class AppNotification extends Equatable {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final String? referenceType;
  final String? referenceId;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.referenceType,
    this.referenceId,
  });

  @override
  List<Object?> get props => [id, isRead];
}
