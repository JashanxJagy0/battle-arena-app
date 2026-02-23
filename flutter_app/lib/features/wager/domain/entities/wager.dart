import 'package:equatable/equatable.dart';

enum WagerStatus { active, won, lost, refunded, cancelled }
enum WagerGameType { ludo, freefire }

class Wager extends Equatable {
  final String id;
  final WagerGameType gameType;
  final double entryAmount;
  final double wonAmount;
  final WagerStatus status;
  final DateTime createdAt;
  final DateTime? settledAt;
  final String? matchId;
  final String? tournamentId;
  final List<WagerTimelineEvent> timeline;

  const Wager({
    required this.id,
    required this.gameType,
    required this.entryAmount,
    required this.wonAmount,
    required this.status,
    required this.createdAt,
    this.settledAt,
    this.matchId,
    this.tournamentId,
    this.timeline = const [],
  });

  double get netAmount => wonAmount - entryAmount;
  bool get isProfit => netAmount > 0;

  @override
  List<Object?> get props => [id, gameType, entryAmount, wonAmount, status, createdAt];
}

class WagerTimelineEvent extends Equatable {
  final String event;
  final DateTime timestamp;
  final String? description;

  const WagerTimelineEvent({
    required this.event,
    required this.timestamp,
    this.description,
  });

  @override
  List<Object?> get props => [event, timestamp];
}

class WagerStats extends Equatable {
  final double totalWagered;
  final double totalWon;
  final double totalLost;
  final double netProfit;
  final double roi;
  final int totalBets;

  const WagerStats({
    required this.totalWagered,
    required this.totalWon,
    required this.totalLost,
    required this.netProfit,
    required this.roi,
    required this.totalBets,
  });

  @override
  List<Object?> get props => [totalWagered, totalWon, totalLost, netProfit, roi, totalBets];
}
