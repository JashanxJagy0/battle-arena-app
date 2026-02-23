import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/animated_counter.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/neon_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class HomeScreen extends StatefulWidget {
  final Widget child;

  const HomeScreen({super.key, required this.child});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const _tabs = ['/home', '/home/tournaments', '/home/wallet', '/home/profile'];

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
    context.go(_tabs[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _currentIndex == 0 ? const _HomeTab() : widget.child,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground.withOpacity(0.85),
            border: Border(
              top: BorderSide(color: AppColors.primary.withOpacity(0.15), width: 1),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            backgroundColor: Colors.transparent,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: AppStrings.home,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.emoji_events_outlined),
                activeIcon: Icon(Icons.emoji_events_rounded),
                label: 'Tournaments',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_outlined),
                activeIcon: Icon(Icons.account_balance_wallet_rounded),
                label: AppStrings.wallet,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                activeIcon: Icon(Icons.person_rounded),
                label: AppStrings.profile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is Authenticated ? state.user : null;
        return CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 0,
              floating: true,
              pinned: false,
              backgroundColor: AppColors.background,
              title: Row(
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: AppColors.primaryGradient,
                    ).createShader(bounds),
                    child: Text(
                      AppStrings.appName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded),
                    onPressed: () => context.push('/notifications'),
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Balance Banner
                    _BalanceBanner(balance: user?.walletBalance ?? 0),
                    const SizedBox(height: 24),
                    // Games Section
                    Text('Choose Your Game', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _GameCard(
                            title: AppStrings.ludo,
                            subtitle: 'Classic board game',
                            icon: Icons.casino_rounded,
                            gradient: AppColors.primaryGradient,
                            onTap: () => context.push('/home/ludo'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _GameCard(
                            title: AppStrings.freeFire,
                            subtitle: 'Battle Royale',
                            icon: Icons.local_fire_department_rounded,
                            gradient: AppColors.accentGradient,
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Live Tournaments
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(AppStrings.liveTournaments, style: Theme.of(context).textTheme.titleLarge),
                        TextButton(
                          onPressed: () => context.push('/home/tournaments'),
                          child: Text(AppStrings.viewAll, style: TextStyle(color: AppColors.primary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _TournamentSlider(),
                    const SizedBox(height: 24),
                    // Bonus Reminder
                    _BonusReminder(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BalanceBanner extends StatelessWidget {
  final double balance;

  const _BalanceBanner({required this.balance});

  @override
  Widget build(BuildContext context) {
    return NeonContainer(
      padding: const EdgeInsets.all(20),
      glowColor: AppColors.primary,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.balance,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54),
                ),
                const SizedBox(height: 4),
                AnimatedCounter(
                  value: balance,
                  prefix: '₹ ',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              GradientButton(
                text: 'Deposit',
                onPressed: () => context.push('/wallet/deposit'),
                width: 100,
                height: 40,
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => context.push('/wallet/withdraw'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(100, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text('Withdraw'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _GameCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient.map((c) => c.withOpacity(0.15)).toList(),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: gradient.first.withOpacity(0.4), width: 1),
          boxShadow: [
            BoxShadow(color: gradient.first.withOpacity(0.1), blurRadius: 12, spreadRadius: 1),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TournamentSlider extends StatelessWidget {
  const _TournamentSlider({super.key});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => context.push('/tournament/${index + 1}'),
            child: NeonContainer(
              padding: const EdgeInsets.all(16),
              glowColor: index.isEven ? AppColors.primary : AppColors.secondary,
              child: SizedBox(
                width: 200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.error.withOpacity(0.4)),
                          ),
                          child: const Text('LIVE', style: TextStyle(color: AppColors.error, fontSize: 10, fontWeight: FontWeight.w700)),
                        ),
                        const Spacer(),
                        Text('₹${(index + 1) * 500}', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    Text(
                      'Ludo Tournament ${index + 1}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Row(
                      children: [
                        const Icon(Icons.people_outline, size: 14, color: Colors.white54),
                        const SizedBox(width: 4),
                        Text('${(index + 1) * 8}/32', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BonusReminder extends StatelessWidget {
  const _BonusReminder({super.key});
  @override
  Widget build(BuildContext context) {
    return NeonContainer(
      glowColor: AppColors.accent,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppColors.accentGradient),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.card_giftcard_rounded, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily Bonus Available!', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text('Claim your ₹50 daily bonus now', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.push('/bonuses'),
            child: Text('Claim', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
