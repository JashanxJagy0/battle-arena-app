import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/transaction.dart';

class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;

  const TransactionTile({super.key, required this.transaction, this.onTap});

  static const _typeIcons = {
    'deposit': Icons.arrow_downward_rounded,
    'withdrawal': Icons.arrow_upward_rounded,
    'tournament_entry_fee': Icons.emoji_events_outlined,
    'tournament_winning': Icons.emoji_events_rounded,
    'wager': Icons.casino_outlined,
    'wager_winning': Icons.casino_rounded,
    'bonus': Icons.card_giftcard_rounded,
    'referral': Icons.people_rounded,
    'refund': Icons.refresh_rounded,
  };

  static const _typeColors = {
    'deposit': AppColors.secondary,
    'withdrawal': AppColors.error,
    'tournament_entry_fee': AppColors.accent,
    'tournament_winning': AppColors.secondary,
    'wager': AppColors.primary,
    'wager_winning': AppColors.secondary,
    'bonus': Color(0xFFFFC107),
    'referral': AppColors.primary,
    'refund': AppColors.primary,
  };

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return AppColors.secondary;
      case 'pending':
        return const Color(0xFFFFC107);
      case 'failed':
        return AppColors.error;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = _typeIcons[transaction.type] ?? Icons.swap_horiz_rounded;
    final color = _typeColors[transaction.type] ?? AppColors.primary;
    final isCredit = transaction.isCredit;
    final amountColor = isCredit ? AppColors.secondary : AppColors.error;
    final amountPrefix = isCredit ? '+\$' : '-\$';
    final statusColor = _statusColor(transaction.status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description ?? _formatType(transaction.type),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('MMM d, yyyy · h:mm a')
                        .format(transaction.createdAt.toLocal()),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$amountPrefix${transaction.amount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: amountColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    _capitalize(transaction.status),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatType(String type) {
    return type
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';
}
