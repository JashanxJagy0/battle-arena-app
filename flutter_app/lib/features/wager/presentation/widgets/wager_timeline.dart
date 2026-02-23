import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/wager.dart';

class WagerTimeline extends StatelessWidget {
  final List<WagerTimelineEvent> events;

  const WagerTimeline({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      final defaultEvents = [
        WagerTimelineEvent(event: 'Entered', timestamp: DateTime.now().subtract(const Duration(hours: 2))),
        WagerTimelineEvent(event: 'Game Started', timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 30))),
        WagerTimelineEvent(event: 'Game Ended', timestamp: DateTime.now().subtract(const Duration(hours: 1))),
        WagerTimelineEvent(event: 'Settled', timestamp: DateTime.now().subtract(const Duration(minutes: 55))),
      ];
      return _buildTimeline(defaultEvents);
    }
    return _buildTimeline(events);
  }

  Widget _buildTimeline(List<WagerTimelineEvent> events) {
    return Column(
      children: events.asMap().entries.map((entry) {
        final index = entry.key;
        final event = entry.value;
        final isLast = index == events.length - 1;

        return IntrinsicHeight(
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isLast ? AppColors.secondary : AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isLast ? AppColors.secondary : AppColors.primary).withOpacity(0.4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: AppColors.divider,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.event,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      if (event.description != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          event.description!,
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('MMM d, HH:mm').format(event.timestamp),
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
