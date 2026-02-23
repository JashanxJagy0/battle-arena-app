import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animate_do/animate_do.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../bloc/wager_bloc.dart';
import '../widgets/wager_stat_card.dart';
import '../../domain/entities/wager.dart';

class WagerHistoryScreen extends StatefulWidget {
  const WagerHistoryScreen({super.key});

  @override
  State<WagerHistoryScreen> createState() => _WagerHistoryScreenState();
}

class _WagerHistoryScreenState extends State<WagerHistoryScreen> {
  String _selectedPeriod = 'daily';

  @override
  void initState() {
    super.initState();
    context.read<WagerBloc>().add(const LoadWagerHistory());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Wager History'),
        backgroundColor: AppColors.background,
      ),
      body: BlocBuilder<WagerBloc, WagerState>(
        builder: (context, state) {
          if (state is WagerLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (state is WagerError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                  const SizedBox(height: 12),
                  Text(state.message, style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<WagerBloc>().add(const LoadWagerHistory()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is! WagerLoaded) return const SizedBox.shrink();
          return _buildContent(context, state);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, WagerLoaded state) {
    return RefreshIndicator(
      onRefresh: () async =>
          context.read<WagerBloc>().add(LoadWagerHistory(period: _selectedPeriod)),
      color: AppColors.primary,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats row
                  FadeInDown(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 120,
                            child: WagerStatCard(
                              label: 'Total Wagered',
                              value: '\$${state.stats.totalWagered.toStringAsFixed(2)}',
                              icon: Icons.monetization_on,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 120,
                            child: WagerStatCard(
                              label: 'Total Won',
                              value: '\$${state.stats.totalWon.toStringAsFixed(2)}',
                              icon: Icons.emoji_events,
                              color: AppColors.secondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 120,
                            child: WagerStatCard(
                              label: 'Total Lost',
                              value: '\$${state.stats.totalLost.toStringAsFixed(2)}',
                              icon: Icons.trending_down,
                              color: AppColors.error,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 120,
                            child: WagerStatCard(
                              label: 'Net Profit',
                              value: '${state.stats.netProfit >= 0 ? '+' : ''}\$${state.stats.netProfit.toStringAsFixed(2)}',
                              icon: Icons.show_chart,
                              color: state.stats.netProfit >= 0 ? AppColors.secondary : AppColors.error,
                              trendIcon: state.stats.netProfit >= 0
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 120,
                            child: WagerStatCard(
                              label: 'ROI %',
                              value: '${state.stats.roi >= 0 ? '+' : ''}${state.stats.roi.toStringAsFixed(1)}%',
                              icon: Icons.percent,
                              color: state.stats.roi >= 0 ? AppColors.secondary : AppColors.error,
                              trendIcon: state.stats.roi >= 0
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Period toggle
                  FadeInDown(
                    delay: const Duration(milliseconds: 100),
                    child: Row(
                      children: ['daily', 'weekly', 'monthly'].map((period) {
                        final isSelected = _selectedPeriod == period;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedPeriod = period);
                            context.read<WagerBloc>().add(ChangePeriod(period));
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.divider,
                              ),
                            ),
                            child: Text(
                              period[0].toUpperCase() + period.substring(1),
                              style: TextStyle(
                                color: isSelected ? Colors.black : Colors.white70,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Chart
                  FadeInDown(
                    delay: const Duration(milliseconds: 200),
                    child: Container(
                      height: 180,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                      ),
                      child: state.chartData.isEmpty
                          ? const Center(
                              child: Text('No chart data', style: TextStyle(color: Colors.white38)),
                            )
                          : LineChart(
                              LineChartData(
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  getDrawingHorizontalLine: (_) => FlLine(
                                    color: AppColors.divider.withOpacity(0.5),
                                    strokeWidth: 1,
                                  ),
                                ),
                                titlesData: const FlTitlesData(show: false),
                                borderData: FlBorderData(show: false),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: state.chartData.asMap().entries.map((e) {
                                      final value = (e.value['profit'] as num?)?.toDouble() ?? 0.0;
                                      return FlSpot(e.key.toDouble(), value);
                                    }).toList(),
                                    isCurved: true,
                                    color: AppColors.primary,
                                    barWidth: 2,
                                    dotData: const FlDotData(show: false),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: AppColors.primary.withOpacity(0.1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Wager List',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // Wager list
          if (state.wagers.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.history, size: 48, color: Colors.white38),
                      SizedBox(height: 12),
                      Text('No wagers yet', style: TextStyle(color: Colors.white38)),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == state.wagers.length) {
                    return state.hasMore
                        ? Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: TextButton(
                                onPressed: () =>
                                    context.read<WagerBloc>().add(const LoadMoreWagers()),
                                child: const Text('Load More'),
                              ),
                            ),
                          )
                        : const SizedBox(height: 80);
                  }
                  return FadeInUp(
                    child: _WagerTile(
                      wager: state.wagers[index],
                    ),
                  );
                },
                childCount: state.wagers.length + 1,
              ),
            ),
        ],
      ),
    );
  }
}

class _WagerTile extends StatelessWidget {
  final Wager wager;

  const _WagerTile({required this.wager});

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusLabel) = _statusInfo();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                wager.gameType == WagerGameType.freefire ? '🔥' : '🎲',
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  wager.gameType == WagerGameType.freefire ? 'Free Fire' : 'Ludo',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  DateFormat('MMM d, HH:mm').format(wager.createdAt),
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Entry: \$${wager.entryAmount.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              Text(
                '${wager.netAmount >= 0 ? '+' : ''}\$${wager.netAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: wager.netAmount >= 0 ? AppColors.secondary : AppColors.error,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
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
}
