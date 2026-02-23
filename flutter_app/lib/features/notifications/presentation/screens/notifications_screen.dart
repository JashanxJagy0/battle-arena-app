import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../bloc/notification_bloc.dart';
import '../../domain/entities/app_notification.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationBloc>().add(const LoadNotifications());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.background,
        actions: [
          TextButton(
            onPressed: () {
              context.read<NotificationBloc>().add(const MarkAllNotificationsAsRead());
            },
            child: const Text('Mark all read', style: TextStyle(color: AppColors.primary, fontSize: 12)),
          ),
        ],
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (state is NotificationError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                  const SizedBox(height: 12),
                  Text(state.message, style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<NotificationBloc>().add(const LoadNotifications()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is! NotificationLoaded) return const SizedBox.shrink();

          if (state.notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.white38),
                  SizedBox(height: 16),
                  Text('No notifications yet', style: TextStyle(color: Colors.white54, fontSize: 16)),
                  SizedBox(height: 8),
                  Text("You're all caught up!", style: TextStyle(color: Colors.white38, fontSize: 13)),
                ],
              ),
            );
          }

          // Group by date
          final grouped = <String, List<AppNotification>>{};
          for (final n in state.notifications) {
            final key = _dateLabel(n.createdAt);
            grouped.putIfAbsent(key, () => []).add(n);
          }

          return RefreshIndicator(
            onRefresh: () async => context.read<NotificationBloc>().add(const LoadNotifications()),
            color: AppColors.primary,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 80),
              children: grouped.entries.expand((entry) {
                return [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      entry.key,
                      style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  ...entry.value.asMap().entries.map((e) {
                    return FadeInUp(
                      child: Dismissible(
                        key: Key(e.value.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) {
                          context.read<NotificationBloc>().add(
                                DeleteNotificationEvent(e.value.id),
                              );
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          color: AppColors.error.withOpacity(0.2),
                          child: const Icon(Icons.delete_rounded, color: AppColors.error),
                        ),
                        child: _NotificationTile(
                          notification: e.value,
                          onTap: () {
                            context.read<NotificationBloc>().add(
                                  MarkNotificationAsRead(e.value.id),
                                );
                          },
                        ),
                      ),
                    );
                  }),
                ];
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Today';
    if (d == yesterday) return 'Yesterday';
    return DateFormat('MMM d, yyyy').format(date);
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onTap;

  const _NotificationTile({required this.notification, this.onTap});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _iconForType();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: notification.isRead ? AppColors.cardBackground : AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notification.isRead
                ? AppColors.primary.withOpacity(0.1)
                : AppColors.primary.withOpacity(0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.body,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _timeAgo(notification.createdAt),
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4, left: 8),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  (IconData, Color) _iconForType() {
    switch (notification.type) {
      case NotificationType.tournament:
        return (Icons.emoji_events_rounded, const Color(0xFFFFD700));
      case NotificationType.wager:
        return (Icons.casino_rounded, AppColors.accent);
      case NotificationType.bonus:
        return (Icons.card_giftcard_rounded, AppColors.secondary);
      case NotificationType.referral:
        return (Icons.people_rounded, AppColors.primary);
      case NotificationType.wallet:
        return (Icons.account_balance_wallet_rounded, AppColors.secondary);
      case NotificationType.system:
        return (Icons.info_rounded, Colors.white54);
    }
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
