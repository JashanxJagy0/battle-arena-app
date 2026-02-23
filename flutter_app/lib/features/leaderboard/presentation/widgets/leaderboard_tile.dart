import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/leaderboard_entry.dart';
import 'rank_badge.dart';

class LeaderboardTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isCurrentUser;

  const LeaderboardTile({super.key, required this.entry, this.isCurrentUser = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppColors.primary.withOpacity(0.1)
            : Colors.transparent,
        border: isCurrentUser
            ? Border.all(color: AppColors.primary.withOpacity(0.3))
            : null,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          RankBadge(rank: entry.rank),
          const SizedBox(width: 12),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: entry.avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      entry.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.person, color: AppColors.primary, size: 18),
                    ),
                  )
                : const Icon(Icons.person, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              entry.username,
              style: TextStyle(
                color: isCurrentUser ? AppColors.primary : Colors.white,
                fontWeight: isCurrentUser ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            entry.statValue >= 100
                ? '\$${entry.statValue.toStringAsFixed(0)}'
                : entry.statValue.toStringAsFixed(1),
            style: TextStyle(
              color: isCurrentUser ? AppColors.primary : Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
