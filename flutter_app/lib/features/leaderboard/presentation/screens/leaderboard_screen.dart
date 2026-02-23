import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animate_do/animate_do.dart';

import '../../../../core/constants/app_colors.dart';
import '../bloc/leaderboard_bloc.dart';
import '../widgets/leaderboard_tile.dart';
import '../../domain/entities/leaderboard_entry.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'weekly';

  static const int _topRanksCount = 100;
  final List<String> _tabs = ['ludo', 'freefire', 'earnings', 'referrals'];
  final List<String> _periods = ['daily', 'weekly', 'monthly', 'all_time'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        context.read<LeaderboardBloc>().add(
              ChangeLeaderboardTab(_tabs[_tabController.index]),
            );
      }
    });
    context.read<LeaderboardBloc>().add(const LoadLeaderboard());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Leaderboard'),
        backgroundColor: AppColors.background,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.white38,
          indicatorColor: AppColors.primary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: '🎲 Ludo'),
            Tab(text: '🔥 Free Fire'),
            Tab(text: '💰 Earnings'),
            Tab(text: '👥 Referrals'),
          ],
        ),
      ),
      body: BlocBuilder<LeaderboardBloc, LeaderboardState>(
        builder: (context, state) {
          if (state is LeaderboardLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (state is LeaderboardError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                  const SizedBox(height: 12),
                  Text(state.message, style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<LeaderboardBloc>().add(const LoadLeaderboard()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final loaded = state is LeaderboardLoaded ? state : null;
          final entries = loaded?.entries ?? [];

          return Column(
            children: [
              // Period selector
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _periods.map((period) {
                      final isSelected = _selectedPeriod == period;
                      final label = period == 'all_time' ? 'All Time' :
                          period[0].toUpperCase() + period.substring(1);
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedPeriod = period);
                          context.read<LeaderboardBloc>().add(ChangeLeaderboardPeriod(period));
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white54,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Podium - top 3
              if (entries.length >= 3)
                FadeInDown(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildPodium(entries.take(3).toList()),
                  ),
                ),

              const SizedBox(height: 8),
              const Divider(color: AppColors.divider, height: 1),

              // List
              Expanded(
                child: entries.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.emoji_events, size: 48, color: Colors.white38),
                            SizedBox(height: 12),
                            Text('No data yet', style: TextStyle(color: Colors.white38)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => context.read<LeaderboardBloc>().add(
                              LoadLeaderboard(tab: loaded?.currentTab ?? 'ludo', period: _selectedPeriod),
                            ),
                        color: AppColors.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: entries.length > 3 ? entries.length - 3 : 0,
                          itemBuilder: (context, index) {
                            final entry = entries[index + 3];
                            return FadeInUp(
                              child: LeaderboardTile(entry: entry),
                            );
                          },
                        ),
                      ),
              ),

              // My rank sticky at bottom
              if (loaded?.myEntry != null && (loaded!.myEntry!.rank > _topRanksCount || entries.isEmpty))
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border(top: BorderSide(color: AppColors.primary.withOpacity(0.3))),
                  ),
                  child: LeaderboardTile(entry: loaded.myEntry!, isCurrentUser: true),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPodium(List<LeaderboardEntry> top3) {
    final order = top3.length >= 3 ? [top3[1], top3[0], top3[2]] : top3;
    final heights = [90.0, 110.0, 70.0];
    final colors = [const Color(0xFFC0C0C0), const Color(0xFFFFD700), const Color(0xFFCD7F32)];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: order.asMap().entries.map((e) {
        final index = e.key;
        final entry = e.value;
        final isFirst = entry.rank == 1;

        return Expanded(
          child: Column(
            children: [
              if (isFirst)
                const Text('👑', style: TextStyle(fontSize: 20)),
              const SizedBox(height: 4),
              Container(
                width: 44,
                height: 44,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                  border: Border.all(color: colors[index], width: 2),
                  boxShadow: [
                    BoxShadow(color: colors[index].withOpacity(0.3), blurRadius: 8),
                  ],
                ),
                child: entry.avatarUrl != null
                    ? ClipOval(child: Image.network(entry.avatarUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white54)))
                    : const Icon(Icons.person, color: Colors.white54),
              ),
              const SizedBox(height: 4),
              Text(
                entry.username,
                style: TextStyle(
                  color: colors[index],
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                entry.statValue >= 100
                    ? '\$${entry.statValue.toStringAsFixed(0)}'
                    : entry.statValue.toStringAsFixed(1),
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              const SizedBox(height: 4),
              Container(
                height: heights[index],
                decoration: BoxDecoration(
                  color: colors[index].withOpacity(0.2),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  border: Border.all(color: colors[index].withOpacity(0.4)),
                ),
                child: Center(
                  child: Text(
                    '#${entry.rank}',
                    style: TextStyle(
                      color: colors[index],
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
