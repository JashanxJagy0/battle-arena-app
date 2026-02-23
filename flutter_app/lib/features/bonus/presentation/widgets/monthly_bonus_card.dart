import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/bonus.dart';

class MonthlyBonusCard extends StatelessWidget {
  final Map<String, dynamic> monthlyProgress;
  final Bonus? monthlyBonus;
  final VoidCallback? onClaim;

  const MonthlyBonusCard({
    super.key,
    required this.monthlyProgress,
    this.monthlyBonus,
    this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final totalWagered = (monthlyProgress['totalWagered'] as num?)?.toDouble() ?? 0.0;
    final tiers = [
      {'wagered': 50.0, 'reward': 2.0},
      {'wagered': 200.0, 'reward': 10.0},
      {'wagered': 500.0, 'reward': 30.0},
      {'wagered': 1000.0, 'reward': 75.0},
    ];
    final maxWagered = 1000.0;
    final progress = (totalWagered / maxWagered).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accent.withOpacity(0.2), AppColors.cardBackground],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Wagered: \$${totalWagered.toStringAsFixed(2)} this month',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
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
                    gradient: const LinearGradient(colors: AppColors.accentGradient),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tiers.map((t) {
              final wagered = t['wagered'] as double;
              final reward = t['reward'] as double;
              final reached = totalWagered >= wagered;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: reached ? AppColors.accent.withOpacity(0.2) : AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: reached ? AppColors.accent : AppColors.divider,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '\$${wagered.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: reached ? AppColors.accent : Colors.white38,
                      ),
                    ),
                    Text(
                      '+\$${reward.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: reached ? Colors.white : Colors.white38,
                      ),
                    ),
                    if (reached && monthlyBonus != null && !monthlyBonus!.isClaimed)
                      GestureDetector(
                        onTap: onClaim,
                        child: const Text(
                          'Claim',
                          style: TextStyle(fontSize: 10, color: AppColors.accent),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
