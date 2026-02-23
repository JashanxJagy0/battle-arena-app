import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/constants/app_colors.dart';
import '../bloc/wallet_bloc.dart';
import '../widgets/balance_card.dart';
import '../widgets/transaction_tile.dart';
import '../../domain/entities/transaction.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    context.read<WalletBloc>().add(const LoadBalance());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<WalletBloc, WalletState>(
        builder: (context, state) {
          if (state is WalletLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (state is WalletError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                  const SizedBox(height: 12),
                  Text(state.message,
                      style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<WalletBloc>().add(const LoadBalance()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          final loaded = state is WalletLoaded ? state : null;
          return _buildContent(context, loaded);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, WalletLoaded? state) {
    final wallet = state?.wallet;
    final transactions = state?.transactions ?? [];
    final bonusBalance = wallet?.bonusBalance ?? 0;

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async =>
              context.read<WalletBloc>().add(const LoadBalance()),
          color: AppColors.primary,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 0,
                floating: true,
                pinned: false,
                backgroundColor: AppColors.background,
                title: const Text('Wallet',
                    style: TextStyle(color: AppColors.textPrimary)),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.history_rounded,
                        color: AppColors.primary),
                    onPressed: () => context.push('/wallet/transactions'),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TotalBalanceSection(
                        totalBalance: wallet?.totalBalance ?? 0,
                        pulseAnimation: _pulseAnimation,
                      ),
                      const SizedBox(height: 16),
                      _BalanceBreakdown(
                        mainBalance: wallet?.mainBalance ?? 0,
                        winningBalance: wallet?.winningBalance ?? 0,
                        bonusBalance: bonusBalance,
                      ),
                      const SizedBox(height: 20),
                      const _ActionButtons(),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Recent Transactions',
                              style: Theme.of(context).textTheme.titleMedium),
                          TextButton(
                            onPressed: () =>
                                context.push('/wallet/transactions'),
                            child: const Text('View All',
                                style: TextStyle(color: AppColors.primary)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (transactions.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Column(
                              children: [
                                Icon(Icons.receipt_long_outlined,
                                    size: 48, color: AppColors.textMuted),
                                const SizedBox(height: 12),
                                Text('No transactions yet',
                                    style:
                                        TextStyle(color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                        )
                      else
                        ...transactions.take(10).map((tx) => FadeInUp(
                              child: TransactionTile(
                                transaction: tx,
                                onTap: () =>
                                    _showTransactionDetails(context, tx),
                              ),
                            )),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (bonusBalance > 0)
          Positioned(
            bottom: 20,
            right: 16,
            child: FadeInUp(
              child: GestureDetector(
                onTap: () => context.push('/bonuses'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: AppColors.accentGradient),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.accentGlow,
                          blurRadius: 16,
                          spreadRadius: 2)
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.card_giftcard_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Bonus: \$${bonusBalance.toStringAsFixed(2)}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showTransactionDetails(BuildContext context, Transaction tx) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: TransactionTile(transaction: tx),
      ),
    );
  }
}

class _TotalBalanceSection extends StatelessWidget {
  final double totalBalance;
  final Animation<double> pulseAnimation;

  const _TotalBalanceSection(
      {required this.totalBalance, required this.pulseAnimation});

  @override
  Widget build(BuildContext context) {
    return FadeInDown(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF141729), Color(0xFF0A0E21)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppColors.primary.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
                color: AppColors.primaryGlow, blurRadius: 20, spreadRadius: 2)
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: pulseAnimation,
                  builder: (context, child) => Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondary
                              .withOpacity(pulseAnimation.value),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Total Balance',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppColors.primary, Color(0xFF00FF88)],
              ).createShader(bounds),
              child: Text(
                '\$${totalBalance.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceBreakdown extends StatelessWidget {
  final double mainBalance;
  final double winningBalance;
  final double bonusBalance;

  const _BalanceBreakdown({
    required this.mainBalance,
    required this.winningBalance,
    required this.bonusBalance,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: BalanceCard(
            label: 'Main',
            amount: mainBalance,
            icon: Icons.account_balance_wallet_rounded,
            glowColor: AppColors.primary,
            gradient: AppColors.primaryGradient,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: BalanceCard(
            label: 'Winnings',
            amount: winningBalance,
            icon: Icons.emoji_events_rounded,
            glowColor: AppColors.secondary,
            gradient: AppColors.secondaryGradient,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: BalanceCard(
            label: 'Bonus',
            amount: bonusBalance,
            icon: Icons.card_giftcard_rounded,
            glowColor: AppColors.accent,
            gradient: AppColors.accentGradient,
          ),
        ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              context.push('/wallet/deposit');
            },
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient:
                    const LinearGradient(colors: AppColors.secondaryGradient),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.secondaryGlow,
                      blurRadius: 12,
                      spreadRadius: 1)
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Deposit',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              context.push('/wallet/withdraw');
            },
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient:
                    const LinearGradient(colors: AppColors.primaryGradient),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.primaryGlow,
                      blurRadius: 12,
                      spreadRadius: 1)
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_upward_rounded,
                      color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Withdraw',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
