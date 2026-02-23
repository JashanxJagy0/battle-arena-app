import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/models/participant_model.dart';
import '../../domain/entities/tournament.dart';
import '../bloc/freefire_bloc.dart';
import '../widgets/countdown_timer.dart';
import '../widgets/participant_list_widget.dart';
import '../widgets/prize_breakdown_widget.dart';

class TournamentDetailScreen extends StatefulWidget {
  final String tournamentId;

  const TournamentDetailScreen({super.key, required this.tournamentId});

  @override
  State<TournamentDetailScreen> createState() =>
      _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen> {
  @override
  void initState() {
    super.initState();
    context
        .read<FreefireBloc>()
        .add(LoadTournamentDetail(widget.tournamentId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FreefireBloc, FreefireState>(
      listener: (context, state) {
        if (state is JoinSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully joined the tournament! 🎮'),
              backgroundColor: AppColors.secondary,
            ),
          );
          // Reload detail after joining
          context
              .read<FreefireBloc>()
              .add(LoadTournamentDetail(widget.tournamentId));
        } else if (state is CheckInSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Checked in successfully! ✅'),
              backgroundColor: AppColors.secondary,
            ),
          );
          context
              .read<FreefireBloc>()
              .add(LoadTournamentDetail(widget.tournamentId));
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
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.surface,
              title: const Text('Tournament Detail'),
            ),
            body: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (state is TournamentDetailLoaded) {
          return _DetailBody(tournament: state.tournament);
        }

        if (state is FreefireError) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.surface,
              title: const Text('Error'),
            ),
            body: Center(
              child: Text(
                state.message,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(backgroundColor: AppColors.surface),
          body: const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      },
    );
  }
}

// ── Detail Body ───────────────────────────────────────────────────────────────

class _DetailBody extends StatelessWidget {
  final Tournament tournament;

  // Mock participant list (real impl would load from API)
  static final _mockParticipants = <ParticipantModel>[];

  const _DetailBody({required this.tournament});

  @override
  Widget build(BuildContext context) {
    final progress = tournament.maxParticipants > 0
        ? (tournament.currentParticipants / tournament.maxParticipants)
            .clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar with banner
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppColors.surface,
            leading: const BackButton(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0A0E21), Color(0xFF1A1F3D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      const Text('🔥', style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 8),
                      Text(
                        tournament.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          fontFamily: 'Orbitron',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Map + mode
                  if (tournament.map != null)
                    _InfoRow(
                        icon: '🗺️',
                        label: 'Map: ${tournament.map}'),
                  const SizedBox(height: 4),
                  _InfoRow(
                      icon: '🎮',
                      label: 'Mode: ${tournament.gameMode.toUpperCase()}'),
                  const SizedBox(height: 20),

                  // Entry fee + prize pool
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Entry Fee',
                          value:
                              '\$${tournament.entryFee.toStringAsFixed(2)}',
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Prize Pool',
                          value:
                              '\$${tournament.prizePool.total.toStringAsFixed(2)}',
                          color: const Color(0xFFFFD700),
                          larger: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Players progress
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '👥 ${tournament.currentParticipants}/${tournament.maxParticipants} Players',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.border,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Prize breakdown
                  _SectionHeader(title: 'Prize Breakdown'),
                  const SizedBox(height: 10),
                  PrizeBreakdownWidget(prizePool: tournament.prizePool),
                  const SizedBox(height: 20),

                  // Schedule
                  _SectionHeader(title: 'Schedule'),
                  const SizedBox(height: 10),
                  _ScheduleCard(tournament: tournament),
                  const SizedBox(height: 20),

                  // Countdown if upcoming
                  if (tournament.isUpcoming &&
                      tournament.startTime.isAfter(DateTime.now())) ...[
                    _SectionHeader(title: 'Starts In'),
                    const SizedBox(height: 12),
                    Center(
                      child: CountdownTimer(targetTime: tournament.startTime),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Rules
                  _SectionHeader(title: 'Rules'),
                  const SizedBox(height: 10),
                  _RulesCard(),
                  const SizedBox(height: 20),

                  // Participants
                  _SectionHeader(
                      title:
                          'Participants (${tournament.currentParticipants})'),
                  const SizedBox(height: 10),
                  ParticipantListWidget(participants: _mockParticipants),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomActionBar(tournament: tournament),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: const Divider(color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Expanded(child: const Divider(color: AppColors.border)),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String icon;
  final String label;

  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      '$icon  $label',
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool larger;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    this.larger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: larger ? 22 : 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final Tournament tournament;

  const _ScheduleCard({required this.tournament});

  @override
  Widget build(BuildContext context) {
    final startFmt =
        DateFormat('MMM d, yyyy – h:mm a').format(tournament.startTime);
    final regCloses = tournament.startTime.subtract(const Duration(minutes: 30));
    final roomVisible = tournament.startTime.subtract(const Duration(minutes: 15));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ScheduleRow(
              icon: '📅',
              label: startFmt),
          const SizedBox(height: 8),
          _ScheduleRow(
              icon: '⏰',
              label:
                  'Registration closes: ${DateFormat('h:mm a').format(regCloses)}'),
          const SizedBox(height: 8),
          _ScheduleRow(
              icon: '🔐',
              label:
                  'Room visible: ${DateFormat('h:mm a').format(roomVisible)}'),
        ],
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  final String icon;
  final String label;

  const _ScheduleRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      '$icon  $label',
      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
    );
  }
}

class _RulesCard extends StatelessWidget {
  static const _rules = [
    'No teaming in solo',
    'Submit screenshot after match',
    'No hacks — instant ban',
    'Must check-in 10 min before',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _rules
            .map((rule) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '• ',
                        style: TextStyle(color: AppColors.primary),
                      ),
                      Expanded(
                        child: Text(
                          rule,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ── Bottom Action Bar ─────────────────────────────────────────────────────────

class _BottomActionBar extends StatelessWidget {
  final Tournament tournament;

  const _BottomActionBar({required this.tournament});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: _buildButton(context),
    );
  }

  Widget _buildButton(BuildContext context) {
    if (tournament.isCompleted) {
      return _ActionBtn(
        label: 'View Results',
        gradient: [AppColors.textMuted, AppColors.textMuted],
        onTap: () => context
            .push('/freefire/tournament/${tournament.id}/results'),
      );
    }

    if (tournament.isLive && tournament.hasJoined) {
      return _ActionBtn(
        label: '📋 Submit Result',
        gradient: [const Color(0xFFFF6B00), const Color(0xFFFF9500)],
        onTap: () =>
            context.push('/freefire/tournament/${tournament.id}/room'),
      );
    }

    if (tournament.isLive) {
      return _ActionBtn(
        label: 'Tournament is Live',
        gradient: [AppColors.error, AppColors.error],
        onTap: null,
      );
    }

    if (tournament.isCheckedIn && tournament.hasJoined) {
      return _ActionBtn(
        label: '🔑 View Room',
        gradient: AppColors.primaryGradient,
        onTap: () =>
            context.push('/freefire/tournament/${tournament.id}/room'),
      );
    }

    if (tournament.canCheckIn) {
      return _ActionBtn(
        label: '✅ Check In',
        gradient: [const Color(0xFFFFD700), const Color(0xFFFFA500)],
        onTap: () => context
            .read<FreefireBloc>()
            .add(CheckIn(tournament.id)),
      );
    }

    if (tournament.canJoin) {
      return _ActionBtn(
        label:
            '🎮 JOIN TOURNAMENT – \$${tournament.entryFee.toStringAsFixed(2)}',
        gradient: AppColors.secondaryGradient,
        onTap: () =>
            context.push('/freefire/tournament/${tournament.id}/join'),
      );
    }

    if (tournament.hasJoined) {
      return _ActionBtn(
        label: 'Joined ✓',
        gradient: [AppColors.secondary, AppColors.secondary],
        onTap: null,
      );
    }

    return const SizedBox.shrink();
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final List<Color> gradient;
  final VoidCallback? onTap;

  const _ActionBtn({
    required this.label,
    required this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.7,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity,
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: gradient.first.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
