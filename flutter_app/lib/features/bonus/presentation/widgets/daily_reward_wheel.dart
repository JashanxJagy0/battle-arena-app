import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/bonus.dart';

class DailyRewardWheel extends StatefulWidget {
  final int currentStreak;
  final Bonus? dailyBonus;
  final VoidCallback? onClaim;

  const DailyRewardWheel({
    super.key,
    required this.currentStreak,
    this.dailyBonus,
    this.onClaim,
  });

  @override
  State<DailyRewardWheel> createState() => _DailyRewardWheelState();
}

class _DailyRewardWheelState extends State<DailyRewardWheel>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  static const List<double> _dayRewards = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 5.0];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isClaimed = widget.dailyBonus?.isClaimed ?? false;
    final currentDay = (widget.currentStreak % 7).clamp(0, 6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 7,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final isPast = index < currentDay;
              final isCurrent = index == currentDay;
              final isFuture = index > currentDay;
              final reward = _dayRewards[index];

              return AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    width: 64,
                    decoration: BoxDecoration(
                      color: isPast
                          ? AppColors.secondary.withOpacity(0.2)
                          : isCurrent
                              ? AppColors.primary.withOpacity(0.15)
                              : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isPast
                            ? AppColors.secondary
                            : isCurrent
                                ? AppColors.primary.withOpacity(isClaimed ? 0.5 : _pulseAnimation.value)
                                : AppColors.divider,
                        width: isCurrent ? 2 : 1,
                      ),
                      boxShadow: isCurrent && !isClaimed
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3 * _pulseAnimation.value),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        isPast
                            ? const Icon(Icons.check_circle, color: AppColors.secondary, size: 20)
                            : isCurrent && isClaimed
                                ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
                                : isFuture
                                    ? const Icon(Icons.lock, color: Colors.white38, size: 16)
                                    : Text(
                                        'Day ${index + 1}',
                                        style: const TextStyle(
                                          fontSize: 9,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                        const SizedBox(height: 2),
                        Text(
                          '\$${reward.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isFuture ? Colors.white38 : Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (isCurrent && !isClaimed)
                          const Text(
                            'CLAIM',
                            style: TextStyle(
                              fontSize: 8,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        if (!isClaimed && widget.dailyBonus != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onClaim,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'CLAIM NOW',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),
            ),
          )
        else if (isClaimed)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: AppColors.secondary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Come back tomorrow',
                  style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
