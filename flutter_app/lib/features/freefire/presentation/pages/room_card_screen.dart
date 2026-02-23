import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/custom_room.dart';
import '../bloc/freefire_bloc.dart';
import '../widgets/countdown_timer.dart';
import '../widgets/room_info_card.dart';

class RoomCardScreen extends StatefulWidget {
  final String tournamentId;
  final String? tournamentTitle;

  /// The time after which room details become visible.
  final DateTime? roomVisibleAt;

  const RoomCardScreen({
    super.key,
    required this.tournamentId,
    this.tournamentTitle,
    this.roomVisibleAt,
  });

  @override
  State<RoomCardScreen> createState() => _RoomCardScreenState();
}

class _RoomCardScreenState extends State<RoomCardScreen> {
  Timer? _revealTimer;

  @override
  void initState() {
    super.initState();
    context.read<FreefireBloc>().add(LoadRoom(widget.tournamentId));

    // If room not yet visible, schedule a refresh when it becomes visible
    final visibleAt = widget.roomVisibleAt;
    if (visibleAt != null && DateTime.now().isBefore(visibleAt)) {
      final delay = visibleAt.difference(DateTime.now());
      _revealTimer = Timer(delay, () {
        if (mounted) {
          context.read<FreefireBloc>().add(LoadRoom(widget.tournamentId));
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          widget.tournamentTitle ?? 'Room Details',
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        leading: const BackButton(color: Colors.white),
      ),
      body: BlocConsumer<FreefireBloc, FreefireState>(
        listener: (context, state) {
          if (state is FreefireError) {
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

          if (state is RoomDetailsLoaded) {
            return _RoomBody(
              room: state.room,
              roomVisibleAt: widget.roomVisibleAt,
              tournamentId: widget.tournamentId,
            );
          }

          return const Center(
            child: Text(
              'Unable to load room details.',
              style: TextStyle(color: AppColors.textMuted),
            ),
          );
        },
      ),
    );
  }
}

class _RoomBody extends StatelessWidget {
  final CustomRoom room;
  final DateTime? roomVisibleAt;
  final String tournamentId;

  const _RoomBody({
    required this.room,
    required this.tournamentId,
    this.roomVisibleAt,
  });

  bool get _isVisible {
    if (roomVisibleAt == null) return true;
    return DateTime.now().isAfter(roomVisibleAt!);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Neon glow container
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: RoomInfoCard(room: room, roomVisibleAt: roomVisibleAt),
          ),
          const SizedBox(height: 24),

          // Countdown if not yet visible
          if (!_isVisible && roomVisibleAt != null) ...[
            const Text(
              'Room opens in',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            CountdownTimer(targetTime: roomVisibleAt!),
            const SizedBox(height: 24),
          ],

          // Match start countdown
          const Text(
            'Match starts at',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          CountdownTimer(targetTime: room.startTime),
          const SizedBox(height: 28),

          // Instructions
          if (_isVisible) ...[
            _InstructionsCard(),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}

class _InstructionsCard extends StatelessWidget {
  static const _steps = [
    'Open Free Fire',
    'Tap Custom Room',
    'Enter Room ID',
    'Enter Password',
    'Ready Up & wait for match to start',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📋 Quick Instructions',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 14),
          ..._steps.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: AppColors.primaryGradient,
                        ),
                      ),
                      child: Text(
                        '${e.key + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        e.value,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
