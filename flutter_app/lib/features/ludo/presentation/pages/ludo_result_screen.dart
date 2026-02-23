import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../bloc/ludo_bloc.dart';

class LudoResultScreen extends StatelessWidget {
  final String matchId;
  final String winnerId;
  final String myUserId;
  final double prizeWon;

  // Optionally accept the full game for rankings; falls back to minimal display.
  final LudoGameOver? gameOverState;

  const LudoResultScreen({
    required this.matchId,
    required this.winnerId,
    required this.myUserId,
    required this.prizeWon,
    this.gameOverState,
    super.key,
  });

  bool get _iWon => winnerId == myUserId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Match Result',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 12),
            // Trophy / Result icon
            _ResultHero(iWon: _iWon),
            const SizedBox(height: 20),
            Text(
              _iWon ? 'YOU WON! 🎉' : 'BETTER LUCK\nNEXT TIME',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _iWon ? AppColors.secondary : AppColors.error,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                shadows: [
                  Shadow(
                    color: (_iWon ? AppColors.secondary : AppColors.error)
                        .withOpacity(0.6),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Prize amount
            if (_iWon && prizeWon > 0) ...[
              const Text(
                'Prize Won',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '\$${prizeWon.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  shadows: [
                    Shadow(
                      color: AppColors.secondary,
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            // Rankings list
            if (gameOverState != null) ...[
              _RankingsList(gameOverState: gameOverState!, winnerId: winnerId),
              const SizedBox(height: 24),
            ],
            // Actions
            GradientButton(
              text: 'PLAY AGAIN',
              gradient: AppColors.primaryGradient,
              icon: Icons.replay,
              onPressed: () => context.go('/home/ludo'),
            ),
            const SizedBox(height: 12),
            GradientButton(
              text: 'BACK TO LOBBY',
              gradient: AppColors.accentGradient,
              icon: Icons.home_outlined,
              onPressed: () => context.go('/home/ludo'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _share(context),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                side: const BorderSide(color: AppColors.border),
                foregroundColor: AppColors.textSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.share_outlined, size: 18),
              label: const Text(
                'SHARE',
                style:
                    TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _share(BuildContext context) {
    final result = _iWon
        ? 'I just won \$${prizeWon.toStringAsFixed(2)} in a Ludo match on Battle Arena! 🎲🏆'
        : 'I played a Ludo match on Battle Arena. Time for a rematch! 🎲';
    Share.share(result);
  }
}

// ── Result Hero ───────────────────────────────────────────────────────────────

class _ResultHero extends StatelessWidget {
  final bool iWon;

  const _ResultHero({required this.iWon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: (iWon ? AppColors.secondary : AppColors.error).withOpacity(0.12),
        boxShadow: [
          BoxShadow(
            color: (iWon ? AppColors.secondary : AppColors.error)
                .withOpacity(0.4),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Icon(
        iWon ? Icons.emoji_events : Icons.sentiment_dissatisfied_outlined,
        size: 64,
        color: iWon ? AppColors.secondary : AppColors.error,
      ),
    );
  }
}

// ── Rankings List ─────────────────────────────────────────────────────────────

class _RankingsList extends StatelessWidget {
  final LudoGameOver gameOverState;
  final String winnerId;

  const _RankingsList({
    required this.gameOverState,
    required this.winnerId,
  });

  @override
  Widget build(BuildContext context) {
    final players = gameOverState.game.players;
    // Sort: winner first, then by piecesHome descending
    final sorted = [...players]..sort((a, b) {
        if (a.userId == winnerId) return -1;
        if (b.userId == winnerId) return 1;
        return b.piecesHome.compareTo(a.piecesHome);
      });

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              'Rankings',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const Divider(color: AppColors.divider, height: 1),
          ...List.generate(sorted.length, (index) {
            final player = sorted[index];
            final isWinner = player.userId == winnerId;
            final rankColors = [
              const Color(0xFFFFD700),
              const Color(0xFFC0C0C0),
              const Color(0xFFCD7F32),
            ];
            final rankColor = index < 3
                ? rankColors[index]
                : AppColors.textMuted;

            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isWinner
                    ? AppColors.secondary.withOpacity(0.08)
                    : Colors.transparent,
                border: index < sorted.length - 1
                    ? const Border(
                        bottom:
                            BorderSide(color: AppColors.divider, width: 0.5))
                    : null,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      '#${index + 1}',
                      style: TextStyle(
                        color: rankColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface,
                      border: Border.all(
                        color: isWinner
                            ? AppColors.secondary
                            : AppColors.border,
                      ),
                    ),
                    child: ClipOval(
                      child: player.avatar != null &&
                              player.avatar!.isNotEmpty
                          ? Image.network(
                              player.avatar!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.person,
                                color: AppColors.textMuted,
                                size: 18,
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              color: AppColors.textMuted,
                              size: 18,
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      player.username,
                      style: TextStyle(
                        color: isWinner
                            ? AppColors.secondary
                            : AppColors.textPrimary,
                        fontWeight: isWinner
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: List.generate(4, (i) {
                      final isHome = i < player.piecesHome;
                      return Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isHome
                                ? AppColors.secondary
                                : Colors.transparent,
                            border: Border.all(
                              color: isHome
                                  ? AppColors.secondary
                                  : AppColors.textMuted,
                              width: 1.5,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  if (isWinner) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.emoji_events,
                      color: Color(0xFFFFD700),
                      size: 18,
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
