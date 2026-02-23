import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Kill count tracker widget with increment/decrement controls.
/// Used on the result submission screen.
class KillTrackerWidget extends StatelessWidget {
  final int kills;
  final int maxKills;
  final ValueChanged<int> onChanged;

  const KillTrackerWidget({
    super.key,
    required this.kills,
    required this.onChanged,
    this.maxKills = 99,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Text(
            '⚔️ Kills',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _CircleButton(
                icon: Icons.remove,
                onTap: kills > 0 ? () => onChanged(kills - 1) : null,
              ),
              const SizedBox(width: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim,
                  child: child,
                ),
                child: Text(
                  '$kills',
                  key: ValueKey(kills),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontFamily: 'Orbitron',
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              _CircleButton(
                icon: Icons.add,
                onTap:
                    kills < maxKills ? () => onChanged(kills + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CircleButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: enabled
              ? const LinearGradient(colors: AppColors.primaryGradient)
              : null,
          color: enabled ? null : AppColors.border,
        ),
        child: Icon(
          icon,
          color: enabled ? Colors.white : AppColors.textMuted,
          size: 22,
        ),
      ),
    );
  }
}
