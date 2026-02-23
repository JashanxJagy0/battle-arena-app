import '../../domain/entities/app_notification.dart';

class NotificationModel extends AppNotification {
  const NotificationModel({
    required super.id,
    required super.type,
    required super.title,
    required super.body,
    required super.isRead,
    required super.createdAt,
    super.referenceType,
    super.referenceId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String? ?? '',
      type: _parseType(json['type'] as String? ?? ''),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? json['message'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? json['read'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      referenceType: json['referenceType'] as String?,
      referenceId: json['referenceId'] as String?,
    );
  }

  static NotificationType _parseType(String type) {
    switch (type.toLowerCase()) {
      case 'tournament': return NotificationType.tournament;
      case 'wager': return NotificationType.wager;
      case 'bonus': return NotificationType.bonus;
      case 'referral': return NotificationType.referral;
      case 'wallet': return NotificationType.wallet;
      default: return NotificationType.system;
    }
  }
}
