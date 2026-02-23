import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../data/models/leaderboard_model.dart';
import '../../domain/entities/tournament.dart';
import '../bloc/freefire_bloc.dart';
import '../widgets/kill_tracker_widget.dart';

class TournamentResultScreen extends StatefulWidget {
  final String tournamentId;
  final String? currentUserId;

  const TournamentResultScreen({
    super.key,
    required this.tournamentId,
    this.currentUserId,
  });

  @override
  State<TournamentResultScreen> createState() =>
      _TournamentResultScreenState();
}

class _TournamentResultScreenState extends State<TournamentResultScreen> {
  int _kills = 0;
  int _placement = 1;
  bool _submitting = false;
  bool _submitted = false;

  // Mock leaderboard – real data would come from bloc/API
  static final _mockLeaderboard = <LeaderboardModel>[];

  @override
  void initState() {
    super.initState();
    context
        .read<FreefireBloc>()
        .add(LoadTournamentDetail(widget.tournamentId));
  }

  void _submit() {
    setState(() => _submitting = true);
    context.read<FreefireBloc>().add(SubmitResult(
          tournamentId: widget.tournamentId,
          placement: _placement,
          kills: _kills,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FreefireBloc, FreefireState>(
      listener: (context, state) {
        if (state is ResultSubmitted) {
          setState(() {
            _submitting = false;
            _submitted = true;
          });
        } else if (state is FreefireError) {
          setState(() => _submitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final tournament = state is TournamentDetailLoaded
            ? state.tournament
            : null;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            title: const Text(
              'Tournament Results',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            leading: const BackButton(color: Colors.white),
          ),
          body: _submitted
              ? _SubmittedView(onBack: () => context.pop())
              : _ResultBody(
                  tournament: tournament,
                  leaderboard: _mockLeaderboard,
                  currentUserId: widget.currentUserId,
                  kills: _kills,
                  placement: _placement,
                  submitting: _submitting,
                  onKillsChanged: (v) => setState(() => _kills = v),
                  onPlacementChanged: (v) => setState(() => _placement = v),
                  onSubmit: _submit,
                ),
        );
      },
    );
  }
}

// ── Submitted confirmation view ───────────────────────────────────────────────

class _SubmittedView extends StatelessWidget {
  final VoidCallback onBack;

  const _SubmittedView({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B00), Color(0xFFFF9500)]),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 50),
            ),
            const SizedBox(height: 24),
            const Text(
              'Result Submitted!',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Your result is under review.\nPrizes will be distributed once verified.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            GradientButton(
              text: 'Back to Tournaments',
              gradient: AppColors.primaryGradient,
              onPressed: onBack,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Result body ───────────────────────────────────────────────────────────────

class _ResultBody extends StatelessWidget {
  final Tournament? tournament;
  final List<LeaderboardModel> leaderboard;
  final String? currentUserId;
  final int kills;
  final int placement;
  final bool submitting;
  final ValueChanged<int> onKillsChanged;
  final ValueChanged<int> onPlacementChanged;
  final VoidCallback onSubmit;

  const _ResultBody({
    required this.tournament,
    required this.leaderboard,
    required this.currentUserId,
    required this.kills,
    required this.placement,
    required this.submitting,
    required this.onKillsChanged,
    required this.onPlacementChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = tournament?.isCompleted ?? false;
    final isLive = tournament?.isLive ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Leaderboard (shown when there is data or tournament completed)
          if (leaderboard.isNotEmpty || isCompleted) ...[
            _SectionHeader(title: 'Final Leaderboard'),
            const SizedBox(height: 12),
            _LeaderboardTable(
              entries: leaderboard,
              currentUserId: currentUserId,
            ),
            const SizedBox(height: 24),
          ],

          // Submit result form (shown when live and player has joined)
          if (isLive && (tournament?.hasJoined ?? false)) ...[
            _SectionHeader(title: 'Submit Your Result'),
            const SizedBox(height: 12),
            Center(
              child: KillTrackerWidget(
                kills: kills,
                onChanged: onKillsChanged,
              ),
            ),
            const SizedBox(height: 20),
            _PlacementPicker(
              placement: placement,
              maxPlayers: tournament?.maxParticipants ?? 50,
              onChanged: onPlacementChanged,
            ),
            const SizedBox(height: 28),
            GradientButton(
              text: submitting ? 'Submitting...' : '📤 Submit Result',
              gradient: [const Color(0xFFFF6B00), const Color(0xFFFF9500)],
              isLoading: submitting,
              onPressed: submitting ? null : onSubmit,
            ),
          ],

          if (!isLive && !isCompleted && leaderboard.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Results will appear after the tournament ends.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Leaderboard table ─────────────────────────────────────────────────────────

class _LeaderboardTable extends StatelessWidget {
  final List<LeaderboardModel> entries;
  final String? currentUserId;

  const _LeaderboardTable({required this.entries, this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Header row
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: const Row(
              children: [
                SizedBox(width: 36, child: _HeaderCell('Rank')),
                Expanded(child: _HeaderCell('Player')),
                SizedBox(width: 48, child: _HeaderCell('Kills')),
                SizedBox(width: 56, child: _HeaderCell('Points')),
                SizedBox(width: 56, child: _HeaderCell('Prize')),
              ],
            ),
          ),
          if (entries.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'No results yet',
                style: TextStyle(color: AppColors.textMuted),
              ),
            )
          else
            ...entries.map((e) => _LeaderboardRow(
                  entry: e,
                  isCurrentUser: e.userId == currentUserId,
                )),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;

  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final LeaderboardModel entry;
  final bool isCurrentUser;

  const _LeaderboardRow({
    required this.entry,
    required this.isCurrentUser,
  });

  Color get _medalColor {
    switch (entry.rank) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return AppColors.textMuted;
    }
  }

  String get _medal {
    switch (entry.rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '#${entry.rank}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppColors.primary.withOpacity(0.08)
            : Colors.transparent,
        border: const Border(
            bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              _medal,
              style: TextStyle(
                color: _medalColor,
                fontSize: entry.rank <= 3 ? 18 : 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              entry.username,
              style: TextStyle(
                color: isCurrentUser
                    ? AppColors.primary
                    : AppColors.textPrimary,
                fontSize: 13,
                fontWeight: isCurrentUser ? FontWeight.w700 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(
              '⚔️ ${entry.kills}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          SizedBox(
            width: 56,
            child: Text(
              '${entry.points}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          SizedBox(
            width: 56,
            child: Text(
              entry.prize > 0
                  ? '\$${entry.prize.toStringAsFixed(2)}'
                  : '—',
              style: TextStyle(
                color: entry.prize > 0
                    ? const Color(0xFFFFD700)
                    : AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Placement picker ──────────────────────────────────────────────────────────

class _PlacementPicker extends StatelessWidget {
  final int placement;
  final int maxPlayers;
  final ValueChanged<int> onChanged;

  const _PlacementPicker({
    required this.placement,
    required this.maxPlayers,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🏆 Placement',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: placement.toDouble(),
                  min: 1,
                  max: maxPlayers.toDouble(),
                  divisions: maxPlayers - 1,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.border,
                  onChanged: (v) => onChanged(v.round()),
                ),
              ),
              Container(
                width: 48,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  '#$placement',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
