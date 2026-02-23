import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/bonus.dart';

class WeeklyBonusCard extends StatelessWidget {
  final Map<String, dynamic> weeklyProgress;
  final Bonus? weeklyBonus;
  final VoidCallback? onClaim;

  const WeeklyBonusCard({
    super.key,
    required this.weeklyProgress,
    this.weeklyBonus,
    this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final gamesPlayed = weeklyProgress['gamesPlayed'] as int? ?? 0;
    final milestones = [
      {'games': 10, 'reward': 1.0},
      {'games': 25, 'reward': 3.0},
      {'games': 50, 'reward': 7.0},
    ];
    final maxGames = 50;
    final progress = (gamesPlayed / maxGames).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You played $gamesPlayed/${maxGames} games this week',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: AppColors.primaryGradient),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: milestones.map((m) {
              final games = m['games'] as int;
              final reward = m['reward'] as double;
              final reached = gamesPlayed >= games;
              return Column(
                children: [
                  Text(
                    '$games games',
                    style: TextStyle(
                      fontSize: 10,
                      color: reached ? AppColors.primary : Colors.white38,
                    ),
                  ),
                  Text(
                    '\$${reward.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: reached ? AppColors.secondary : Colors.white38,
                    ),
                  ),
                  if (reached && weeklyBonus != null && !weeklyBonus!.isClaimed)
                    TextButton(
                      onPressed: onClaim,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                      ),
                      child: const Text('Claim', style: TextStyle(fontSize: 11)),
                    ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
