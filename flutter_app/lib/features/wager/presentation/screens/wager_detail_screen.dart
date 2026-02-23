import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../bloc/wager_bloc.dart';
import '../widgets/wager_timeline.dart';
import '../../domain/entities/wager.dart';

class WagerDetailScreen extends StatelessWidget {
  final Wager wager;

  const WagerDetailScreen({super.key, required this.wager});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Wager Details'),
        backgroundColor: AppColors.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusBanner(),
            const SizedBox(height: 16),
            _buildAmountCard(context),
            const SizedBox(height: 16),
            _buildInfoCard(context),
            const SizedBox(height: 16),
            _buildTimelineCard(context),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    final (color, label) = _statusInfo();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_statusIcon(), color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _AmountItem(label: 'Entry', amount: wager.entryAmount, color: AppColors.primary),
          Container(width: 1, height: 40, color: AppColors.divider),
          _AmountItem(label: 'Won', amount: wager.wonAmount, color: AppColors.secondary),
          Container(width: 1, height: 40, color: AppColors.divider),
          _AmountItem(
            label: 'Net',
            amount: wager.netAmount,
            color: wager.isProfit ? AppColors.secondary : AppColors.error,
            showSign: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Details', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _InfoRow(
            label: 'Game',
            value: wager.gameType == WagerGameType.freefire ? '🔥 Free Fire' : '🎲 Ludo',
          ),
          _InfoRow(
            label: 'Date',
            value: DateFormat('MMM d, yyyy HH:mm').format(wager.createdAt),
          ),
          if (wager.settledAt != null)
            _InfoRow(
              label: 'Settled',
              value: DateFormat('MMM d, yyyy HH:mm').format(wager.settledAt!),
            ),
          if (wager.matchId != null)
            _InfoRow(label: 'Match ID', value: wager.matchId!),
          if (wager.tournamentId != null)
            _InfoRow(label: 'Tournament ID', value: wager.tournamentId!),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Timeline', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          WagerTimeline(events: wager.timeline),
        ],
      ),
    );
  }

  (Color, String) _statusInfo() {
    switch (wager.status) {
      case WagerStatus.won: return (AppColors.secondary, 'WON');
      case WagerStatus.lost: return (AppColors.error, 'LOST');
      case WagerStatus.refunded: return (Colors.grey, 'REFUNDED');
      case WagerStatus.cancelled: return (Colors.grey, 'CANCELLED');
      case WagerStatus.active: return (const Color(0xFFFFB800), 'ACTIVE');
    }
  }

  IconData _statusIcon() {
    switch (wager.status) {
      case WagerStatus.won: return Icons.emoji_events;
      case WagerStatus.lost: return Icons.close;
      case WagerStatus.refunded: return Icons.replay;
      case WagerStatus.cancelled: return Icons.cancel;
      case WagerStatus.active: return Icons.hourglass_empty;
    }
  }
}

class _AmountItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final bool showSign;

  const _AmountItem({
    required this.label,
    required this.amount,
    required this.color,
    this.showSign = false,
  });

  @override
  Widget build(BuildContext context) {
    final prefix = showSign && amount >= 0 ? '+' : '';
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          '$prefix\$${amount.toStringAsFixed(2)}',
          style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
