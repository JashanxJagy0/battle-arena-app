import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/prize_pool.dart';

/// Displays the prize tier breakdown with rank medal icons.
class PrizeBreakdownWidget extends StatelessWidget {
  final PrizePool prizePool;

  const PrizeBreakdownWidget({super.key, required this.prizePool});

  @override
  Widget build(BuildContext context) {
    final tiers = _buildTiers();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          ...tiers.map((t) => _TierRow(tier: t)),
          if (prizePool.positions.isNotEmpty) ...[
            const Divider(color: AppColors.border, height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Total Prize Pool: \$${prizePool.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<_PrizeTier> _buildTiers() {
    final tiers = <_PrizeTier>[];

    // Top 3 always from dedicated fields
    if (prizePool.firstPlace > 0) {
      tiers.add(_PrizeTier(
        rank: 1,
        medal: '🥇',
        label: '1st Place',
        amount: prizePool.firstPlace,
        color: const Color(0xFFFFD700),
      ));
    }
    if (prizePool.secondPlace > 0) {
      tiers.add(_PrizeTier(
        rank: 2,
        medal: '🥈',
        label: '2nd Place',
        amount: prizePool.secondPlace,
        color: const Color(0xFFC0C0C0),
      ));
    }
    if (prizePool.thirdPlace > 0) {
      tiers.add(_PrizeTier(
        rank: 3,
        medal: '🥉',
        label: '3rd Place',
        amount: prizePool.thirdPlace,
        color: const Color(0xFFCD7F32),
      ));
    }

    // Additional positions from positions map (skip 1-3 if already added)
    final extras = prizePool.positions.entries
        .where((e) => e.key > 3)
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    for (final e in extras) {
      tiers.add(_PrizeTier(
        rank: e.key,
        medal: '🏅',
        label: '${e.key}${_ordinal(e.key)} Place',
        amount: e.value,
        color: AppColors.textSecondary,
      ));
    }

    return tiers;
  }

  static String _ordinal(int n) {
    if (n >= 11 && n <= 13) return 'th';
    switch (n % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }
}

class _PrizeTier {
  final int rank;
  final String medal;
  final String label;
  final double amount;
  final Color color;

  const _PrizeTier({
    required this.rank,
    required this.medal,
    required this.label,
    required this.amount,
    required this.color,
  });
}

class _TierRow extends StatelessWidget {
  final _PrizeTier tier;

  const _TierRow({required this.tier});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Text(tier.medal, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tier.label,
              style: TextStyle(
                color: tier.color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            '\$${tier.amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: tier.color,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
