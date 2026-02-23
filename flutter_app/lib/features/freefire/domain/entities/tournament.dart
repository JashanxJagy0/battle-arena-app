import 'package:equatable/equatable.dart';

import 'prize_pool.dart';

class Tournament extends Equatable {
  final String id;
  final String title;
  final String gameMode;
  final double entryFee;
  final PrizePool prizePool;
  final String status;
  final DateTime startTime;
  final int maxParticipants;
  final int currentParticipants;
  final bool hasJoined;
  final bool isCheckedIn;
  final String? map;

  const Tournament({
    required this.id,
    required this.title,
    required this.gameMode,
    required this.entryFee,
    required this.prizePool,
    required this.status,
    required this.startTime,
    required this.maxParticipants,
    required this.currentParticipants,
    this.hasJoined = false,
    this.isCheckedIn = false,
    this.map,
  });

  bool get isUpcoming => status == 'upcoming' || status == 'registration_open';
  bool get isLive => status == 'ongoing';
  bool get isCompleted => status == 'completed' || status == 'cancelled';
  bool get isFull => currentParticipants >= maxParticipants;

  /// Returns true when a player can join (not joined, upcoming, and has spots).
  bool get canJoin => !hasJoined && isUpcoming && !isFull;

  /// Returns true during the check-in window (up to 60 minutes before start).
  bool get canCheckIn {
    if (!hasJoined || isCheckedIn) return false;
    final now = DateTime.now();
    final window = startTime.subtract(const Duration(hours: 1));
    return now.isAfter(window) && now.isBefore(startTime);
  }

  @override
  List<Object?> get props => [
        id,
        title,
        gameMode,
        entryFee,
        prizePool,
        status,
        startTime,
        maxParticipants,
        currentParticipants,
        hasJoined,
        isCheckedIn,
        map,
      ];
}
