import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../bloc/bonus_bloc.dart';
import '../widgets/streak_indicator.dart';
import '../widgets/daily_reward_wheel.dart';
import '../widgets/weekly_bonus_card.dart';
import '../widgets/monthly_bonus_card.dart';
import '../../domain/entities/bonus.dart';

class BonusScreen extends StatefulWidget {
  const BonusScreen({super.key});

  @override
  State<BonusScreen> createState() => _BonusScreenState();
}

class _BonusScreenState extends State<BonusScreen> {
  final _promoController = TextEditingController();
  bool _isRedeemingPromo = false;

  @override
  void initState() {
    super.initState();
    context.read<BonusBloc>().add(const LoadBonuses());
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bonus Hub'),
        backgroundColor: AppColors.background,
      ),
      body: BlocConsumer<BonusBloc, BonusState>(
        listener: (context, state) {
          if (state is BonusClaimed) {
            HapticFeedback.heavyImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Bonus claimed! +\$${state.bonus.amount.toStringAsFixed(2)}'),
                backgroundColor: AppColors.secondary,
              ),
            );
          } else if (state is PromoCodeRedeemed) {
            HapticFeedback.heavyImpact();
            _promoController.clear();
            setState(() => _isRedeemingPromo = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Promo redeemed! +\$${state.bonus.amount.toStringAsFixed(2)}'),
                backgroundColor: AppColors.secondary,
              ),
            );
          } else if (state is PromoCodeError) {
            setState(() => _isRedeemingPromo = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is BonusLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (state is BonusError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                  const SizedBox(height: 12),
                  Text(state.message, style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<BonusBloc>().add(const LoadBonuses()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final loaded = state is BonusLoaded ? state : const BonusLoaded();
          return RefreshIndicator(
            onRefresh: () async => context.read<BonusBloc>().add(const LoadBonuses()),
            color: AppColors.primary,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Streak indicator
                if (loaded.currentStreak > 0) ...[
                  Center(child: StreakIndicator(streak: loaded.currentStreak)),
                  const SizedBox(height: 16),
                ],

                // Section 1 - Daily Login Reward
                FadeInDown(
                  child: _SectionCard(
                    title: '🎁 Daily Login Reward',
                    child: DailyRewardWheel(
                      currentStreak: loaded.currentStreak,
                      dailyBonus: loaded.dailyBonus,
                      onClaim: loaded.dailyBonus != null
                          ? () {
                              HapticFeedback.mediumImpact();
                              context.read<BonusBloc>().add(
                                    ClaimDailyBonusEvent(loaded.dailyBonus!.id),
                                  );
                            }
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Section 2 - Weekly Play Bonus
                FadeInDown(
                  delay: const Duration(milliseconds: 100),
                  child: _SectionCard(
                    title: '📅 Weekly Play Bonus',
                    child: WeeklyBonusCard(
                      weeklyProgress: loaded.weeklyProgress,
                      weeklyBonus: loaded.weeklyBonus,
                      onClaim: loaded.weeklyBonus != null
                          ? () {
                              HapticFeedback.mediumImpact();
                              context.read<BonusBloc>().add(
                                    ClaimWeeklyBonusEvent(loaded.weeklyBonus!.id),
                                  );
                            }
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Section 3 - Monthly Loyalty Bonus
                FadeInDown(
                  delay: const Duration(milliseconds: 200),
                  child: _SectionCard(
                    title: '🏆 Monthly Loyalty Bonus',
                    child: MonthlyBonusCard(
                      monthlyProgress: loaded.monthlyProgress,
                      monthlyBonus: loaded.monthlyBonus,
                      onClaim: loaded.monthlyBonus != null
                          ? () {
                              HapticFeedback.mediumImpact();
                              context.read<BonusBloc>().add(
                                    ClaimMonthlyBonusEvent(loaded.monthlyBonus!.id),
                                  );
                            }
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Section 4 - Promo Code
                FadeInDown(
                  delay: const Duration(milliseconds: 300),
                  child: _SectionCard(
                    title: '🎟️ Promo Code',
                    child: Column(
                      children: [
                        TextField(
                          controller: _promoController,
                          decoration: const InputDecoration(
                            hintText: 'Enter promo code',
                            prefixIcon: Icon(Icons.confirmation_number_outlined),
                          ),
                          textCapitalization: TextCapitalization.characters,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _promoController.text.isEmpty || _isRedeemingPromo
                                ? null
                                : () {
                                    HapticFeedback.mediumImpact();
                                    setState(() => _isRedeemingPromo = true);
                                    context.read<BonusBloc>().add(
                                          RedeemPromoCodeEvent(_promoController.text.trim()),
                                        );
                                  },
                            child: _isRedeemingPromo
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black,
                                    ),
                                  )
                                : const Text('Redeem'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Section 5 - Bonus History
                if (loaded.bonusHistory.isNotEmpty) ...[
                  FadeInDown(
                    delay: const Duration(milliseconds: 400),
                    child: _SectionCard(
                      title: '📋 Bonus History',
                      child: Column(
                        children: loaded.bonusHistory.take(10).map((bonus) {
                          return _BonusHistoryTile(bonus: bonus);
                        }).toList(),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
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
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _BonusHistoryTile extends StatelessWidget {
  final Bonus bonus;

  const _BonusHistoryTile({required this.bonus});

  @override
  Widget build(BuildContext context) {
    final typeLabel = bonus.bonusType.name[0].toUpperCase() + bonus.bonusType.name.substring(1);
    final date = bonus.claimedAt != null
        ? DateFormat('MMM d, HH:mm').format(bonus.claimedAt!)
        : '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.card_giftcard, color: AppColors.accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$typeLabel Bonus',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(date, style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          Text(
            '+\$${bonus.amount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: AppColors.secondary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
