import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/tournament.dart';

/// Premium tournament card shown in tournament list screens.
class TournamentCard extends StatelessWidget {
  final Tournament tournament;
  final bool showCheckIn;
  final VoidCallback? onJoin;
  final VoidCallback? onCheckIn;

  const TournamentCard({
    super.key,
    required this.tournament,
    this.showCheckIn = false,
    this.onJoin,
    this.onCheckIn,
  });

  Color get _statusColor {
    if (tournament.isLive) return AppColors.error;
    if (tournament.isCompleted) return AppColors.textMuted;
    return AppColors.secondary;
  }

  String get _statusLabel {
    if (tournament.isLive) return 'LIVE';
    if (tournament.isCompleted) return 'ENDED';
    return tournament.status.toUpperCase().replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMM, hh:mm a').format(tournament.startTime);
    final spotsLeft =
        tournament.maxParticipants - tournament.currentParticipants;
    final progress = tournament.maxParticipants > 0
        ? (tournament.currentParticipants / tournament.maxParticipants)
            .clamp(0.0, 1.0)
        : 0.0;
    final timeToStart = tournament.startTime.difference(DateTime.now());
    final nearStart = timeToStart.inMinutes < 60 && timeToStart.inSeconds > 0;

    return GestureDetector(
      onTap: () =>
          context.push('/freefire/tournament/${tournament.id}/detail'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner / header
            Container(
              height: 56,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A1F3D), Color(0xFF0A0E21)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  // Game mode badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border:
                          Border.all(color: AppColors.accent.withOpacity(0.6)),
                    ),
                    child: Text(
                      tournament.gameMode.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Status badge
                  _StatusBadge(
                    label: _statusLabel,
                    color: _statusColor,
                    pulsing: tournament.isLive,
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    tournament.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  // Entry fee | Prize pool row
                  Row(
                    children: [
                      _FeeChip(
                        label: 'Entry',
                        value:
                            '\$${tournament.entryFee.toStringAsFixed(2)}',
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      _FeeChip(
                        label: 'Prize',
                        value:
                            '\$${tournament.prizePool.total.toStringAsFixed(0)}',
                        color: const Color(0xFFFFD700),
                        larger: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Player progress bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '👥 ${tournament.currentParticipants}/${tournament.maxParticipants} Players',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            spotsLeft > 0 ? '$spotsLeft spots left' : 'Full',
                            style: TextStyle(
                              color: spotsLeft > 0
                                  ? AppColors.primary
                                  : AppColors.error,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: AppColors.border,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primary),
                          minHeight: 5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Time row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        nearStart
                            ? '⏱️ Starts in ${timeToStart.inMinutes}m'
                            : '📅 $dateStr',
                        style: TextStyle(
                          color: nearStart
                              ? AppColors.error
                              : AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: nearStart
                              ? FontWeight.w700
                              : FontWeight.normal,
                        ),
                      ),
                      _ActionButton(
                        tournament: tournament,
                        showCheckIn: showCheckIn,
                        onJoin: onJoin,
                        onCheckIn: onCheckIn,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _StatusBadge extends StatefulWidget {
  final String label;
  final Color color;
  final bool pulsing;

  const _StatusBadge({
    required this.label,
    required this.color,
    this.pulsing = false,
  });

  @override
  State<_StatusBadge> createState() => _StatusBadgeState();
}

class _StatusBadgeState extends State<_StatusBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.pulsing) _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: widget.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: widget.color.withOpacity(0.6)),
      ),
      child: Text(
        widget.label,
        style: TextStyle(
          color: widget.color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    if (!widget.pulsing) return badge;

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => Opacity(opacity: _anim.value, child: child),
      child: badge,
    );
  }
}

class _FeeChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool larger;

  const _FeeChip({
    required this.label,
    required this.value,
    required this.color,
    this.larger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: larger ? 16 : 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final Tournament tournament;
  final bool showCheckIn;
  final VoidCallback? onJoin;
  final VoidCallback? onCheckIn;

  const _ActionButton({
    required this.tournament,
    required this.showCheckIn,
    this.onJoin,
    this.onCheckIn,
  });

  @override
  Widget build(BuildContext context) {
    if (tournament.isCompleted) {
      return _Btn(
        label: 'Results',
        color: AppColors.textMuted,
        onTap: () => context
            .push('/freefire/tournament/${tournament.id}/results'),
      );
    }
    if (showCheckIn && tournament.canCheckIn) {
      return _Btn(
        label: 'Check In',
        color: AppColors.secondary,
        onTap: onCheckIn,
      );
    }
    if (tournament.isLive && tournament.hasJoined) {
      return _Btn(
        label: 'Room',
        color: AppColors.primary,
        onTap: () =>
            context.push('/freefire/tournament/${tournament.id}/room'),
      );
    }
    if (tournament.canJoin) {
      return _Btn(
        label: 'Join  \$${tournament.entryFee.toStringAsFixed(2)}',
        color: AppColors.secondary,
        onTap: onJoin ??
            () => context
                .push('/freefire/tournament/${tournament.id}/join'),
      );
    }
    if (tournament.hasJoined) {
      return _Btn(label: 'Joined ✓', color: AppColors.secondary, disabled: true);
    }
    return const SizedBox.shrink();
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool disabled;

  const _Btn({
    required this.label,
    required this.color,
    this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: disabled
              ? null
              : LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                ),
          color: disabled ? AppColors.border : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: disabled ? AppColors.textMuted : Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
