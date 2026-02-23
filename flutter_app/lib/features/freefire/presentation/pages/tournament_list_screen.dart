import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../domain/entities/tournament.dart';
import '../bloc/freefire_bloc.dart';

class TournamentListScreen extends StatefulWidget {
  const TournamentListScreen({super.key});

  @override
  State<TournamentListScreen> createState() => _TournamentListScreenState();
}

class _TournamentListScreenState extends State<TournamentListScreen> {
  static const _gameModes = ['', 'solo', 'duo', 'squad'];
  static const _gameModeLabels = ['All Modes', 'Solo', 'Duo', 'Squad'];

  String _selectedGameMode = '';
  RangeValues _feeRange = const RangeValues(0, 100);

  @override
  void initState() {
    super.initState();
    _loadTournaments();
  }

  void _loadTournaments() {
    context.read<FreefireBloc>().add(LoadTournaments(
          gameMode: _selectedGameMode.isEmpty ? null : _selectedGameMode,
          minEntryFee: _feeRange.start > 0 ? _feeRange.start : null,
          maxEntryFee: _feeRange.end < 100 ? _feeRange.end : null,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          title: const Text(
            'FF Tournaments',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 2,
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Live'),
              Tab(text: 'My Tournaments'),
            ],
          ),
        ),
        body: Column(
          children: [
            _FilterBar(
              gameModes: _gameModes,
              gameModeLabels: _gameModeLabels,
              selectedGameMode: _selectedGameMode,
              feeRange: _feeRange,
              onGameModeChanged: (mode) {
                setState(() => _selectedGameMode = mode);
                _loadTournaments();
              },
              onFeeRangeChanged: (range) {
                setState(() => _feeRange = range);
              },
              onFeeRangeChangeEnd: (_) => _loadTournaments(),
            ),
            Expanded(
              child: BlocConsumer<FreefireBloc, FreefireState>(
                listener: (context, state) {
                  if (state is JoinSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Successfully joined the tournament!'),
                        backgroundColor: AppColors.secondary,
                      ),
                    );
                    _loadTournaments();
                  } else if (state is FreefireError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is TournamentsLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }

                  final loaded =
                      state is TournamentsLoaded ? state : null;

                  return TabBarView(
                    children: [
                      _TournamentTab(
                        tournaments: loaded?.upcoming ?? [],
                        emptyIcon: Icons.schedule,
                        emptyMessage: 'No upcoming tournaments',
                      ),
                      _TournamentTab(
                        tournaments: loaded?.live ?? [],
                        emptyIcon: Icons.sports_esports,
                        emptyMessage: 'No live tournaments',
                      ),
                      _TournamentTab(
                        tournaments: loaded?.myTournaments ?? [],
                        emptyIcon: Icons.person_outline,
                        emptyMessage: 'You have not joined any tournament',
                        showCheckIn: true,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter Bar ────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final List<String> gameModes;
  final List<String> gameModeLabels;
  final String selectedGameMode;
  final RangeValues feeRange;
  final ValueChanged<String> onGameModeChanged;
  final ValueChanged<RangeValues> onFeeRangeChanged;
  final ValueChanged<RangeValues> onFeeRangeChangeEnd;

  const _FilterBar({
    required this.gameModes,
    required this.gameModeLabels,
    required this.selectedGameMode,
    required this.feeRange,
    required this.onGameModeChanged,
    required this.onFeeRangeChanged,
    required this.onFeeRangeChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Game mode dropdown
          Row(
            children: [
              const Text(
                'Mode: ',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedGameMode,
                    dropdownColor: AppColors.cardBackground,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    icon: const Icon(Icons.arrow_drop_down,
                        color: AppColors.primary),
                    items: List.generate(gameModes.length, (i) {
                      return DropdownMenuItem(
                        value: gameModes[i],
                        child: Text(gameModeLabels[i]),
                      );
                    }),
                    onChanged: (v) {
                      if (v != null) onGameModeChanged(v);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Entry fee range slider
          Row(
            children: [
              const Text(
                'Entry Fee: ',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '\$${feeRange.start.toStringAsFixed(0)} – \$${feeRange.end.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.border,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primaryGlow,
              valueIndicatorColor: AppColors.cardBackground,
              valueIndicatorTextStyle:
                  const TextStyle(color: AppColors.textPrimary),
            ),
            child: RangeSlider(
              values: feeRange,
              min: 0,
              max: 100,
              divisions: 20,
              labels: RangeLabels(
                '\$${feeRange.start.toStringAsFixed(0)}',
                '\$${feeRange.end.toStringAsFixed(0)}',
              ),
              onChanged: onFeeRangeChanged,
              onChangeEnd: onFeeRangeChangeEnd,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tournament Tab ────────────────────────────────────────────────────────────

class _TournamentTab extends StatelessWidget {
  final List<Tournament> tournaments;
  final IconData emptyIcon;
  final String emptyMessage;
  final bool showCheckIn;

  const _TournamentTab({
    required this.tournaments,
    required this.emptyIcon,
    required this.emptyMessage,
    this.showCheckIn = false,
  });

  @override
  Widget build(BuildContext context) {
    if (tournaments.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(emptyIcon, size: 56, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tournaments.length,
      itemBuilder: (context, index) {
        return _TournamentCard(
          tournament: tournaments[index],
          showCheckIn: showCheckIn,
        );
      },
    );
  }
}

// ── Tournament Card ───────────────────────────────────────────────────────────

class _TournamentCard extends StatelessWidget {
  final Tournament tournament;
  final bool showCheckIn;

  const _TournamentCard({
    required this.tournament,
    this.showCheckIn = false,
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
    final spotsLeft = tournament.maxParticipants - tournament.currentParticipants;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A1F3D), Color(0xFF141729)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      const SizedBox(height: 4),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border:
                        Border.all(color: _statusColor.withOpacity(0.6)),
                  ),
                  child: Text(
                    _statusLabel,
                    style: TextStyle(
                      color: _statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.sports_esports,
                      label: tournament.gameMode.toUpperCase(),
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 10),
                    _InfoChip(
                      icon: Icons.attach_money,
                      label:
                          'Entry: \$${tournament.entryFee.toStringAsFixed(2)}',
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    _InfoChip(
                      icon: Icons.emoji_events,
                      label:
                          'Prize: \$${tournament.prizePool.total.toStringAsFixed(0)}',
                      color: AppColors.secondary,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ParticipantBar(
                        current: tournament.currentParticipants,
                        max: tournament.maxParticipants,
                        spotsLeft: spotsLeft,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _ActionButton(
                      tournament: tournament,
                      showCheckIn: showCheckIn,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ParticipantBar extends StatelessWidget {
  final int current;
  final int max;
  final int spotsLeft;

  const _ParticipantBar({
    required this.current,
    required this.max,
    required this.spotsLeft,
  });

  @override
  Widget build(BuildContext context) {
    final progress = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$current/$max Players',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
            Text(
              spotsLeft > 0 ? '$spotsLeft spots left' : 'Full',
              style: TextStyle(
                color: spotsLeft > 0 ? AppColors.primary : AppColors.error,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.border,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 5,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final Tournament tournament;
  final bool showCheckIn;

  const _ActionButton({
    required this.tournament,
    required this.showCheckIn,
  });

  @override
  Widget build(BuildContext context) {
    if (tournament.isCompleted) {
      return GestureDetector(
        onTap: () => context.push('/freefire/tournament/${tournament.id}/results'),
        child: _buildButton('Results', AppColors.textMuted),
      );
    }

    if (showCheckIn && tournament.canCheckIn) {
      return GestureDetector(
        onTap: () => context
            .read<FreefireBloc>()
            .add(CheckIn(tournament.id)),
        child: _buildButton('Check In', AppColors.secondary),
      );
    }

    if (tournament.isLive && tournament.hasJoined) {
      return GestureDetector(
        onTap: () => context.push('/freefire/tournament/${tournament.id}/room'),
        child: _buildButton('Room', AppColors.primary),
      );
    }

    if (tournament.canJoin) {
      return GestureDetector(
        onTap: () => context
            .read<FreefireBloc>()
            .add(JoinTournament(tournament.id)),
        child: _buildButton('Join', AppColors.primary),
      );
    }

    if (tournament.hasJoined) {
      return _buildButton('Joined', AppColors.secondary, disabled: true);
    }

    return const SizedBox.shrink();
  }

  Widget _buildButton(String label, Color color, {bool disabled = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          fontSize: 13,
        ),
      ),
    );
  }
}
