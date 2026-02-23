import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class PlayerPanel extends StatelessWidget {
  final String username;
  final String? avatarUrl;
  final String color;
  final int piecesHome;
  final bool isMyTurn;
  final bool isConnected;
  final double? prizeAmount;

  const PlayerPanel({
    required this.username,
    required this.avatarUrl,
    required this.color,
    required this.piecesHome,
    required this.isMyTurn,
    required this.isConnected,
    this.prizeAmount,
    super.key,
  });

  Color get _colorValue {
    switch (color.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow.shade700;
      case 'blue':
        return Colors.blue.shade600;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMyTurn ? _colorValue.withOpacity(0.8) : AppColors.border,
          width: isMyTurn ? 2 : 1,
        ),
        boxShadow: isMyTurn
            ? [
                BoxShadow(
                  color: _colorValue.withOpacity(0.35),
                  blurRadius: 12,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: Row(
        children: [
          _Avatar(avatarUrl: avatarUrl, colorValue: _colorValue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        username,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _ConnectionDot(isConnected: isConnected),
                  ],
                ),
                if (prizeAmount != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '💰 \$${prizeAmount!.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.secondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                _PieceProgress(piecesHome: piecesHome, colorValue: _colorValue),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ColorDot(colorValue: _colorValue),
              if (isMyTurn) ...[
                const SizedBox(height: 4),
                const _TurnBadge(),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? avatarUrl;
  final Color colorValue;

  const _Avatar({required this.avatarUrl, required this.colorValue});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: colorValue, width: 2),
      ),
      child: ClipOval(
        child: avatarUrl != null && avatarUrl!.isNotEmpty
            ? Image.network(
                avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholderIcon,
              )
            : _placeholderIcon,
      ),
    );
  }

  Widget get _placeholderIcon => Container(
        color: AppColors.surface,
        child: const Icon(Icons.person, color: AppColors.textSecondary, size: 24),
      );
}

class _ConnectionDot extends StatelessWidget {
  final bool isConnected;

  const _ConnectionDot({required this.isConnected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isConnected ? AppColors.secondary : Colors.yellow.shade600,
        boxShadow: [
          BoxShadow(
            color: (isConnected ? AppColors.secondary : Colors.yellow.shade600)
                .withOpacity(0.6),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color colorValue;

  const _ColorDot({required this.colorValue});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorValue,
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
      ),
    );
  }
}

class _TurnBadge extends StatelessWidget {
  const _TurnBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.secondaryGradient),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'YOUR\nTURN',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.black,
          fontSize: 7,
          fontWeight: FontWeight.w800,
          height: 1.2,
        ),
      ),
    );
  }
}

class _PieceProgress extends StatelessWidget {
  final int piecesHome;
  final Color colorValue;

  const _PieceProgress({required this.piecesHome, required this.colorValue});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(4, (i) {
        final isHome = i < piecesHome;
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isHome ? colorValue : Colors.transparent,
              border: Border.all(
                color: isHome ? colorValue : AppColors.textMuted,
                width: 1.5,
              ),
            ),
          ),
        );
      }),
    );
  }
}
