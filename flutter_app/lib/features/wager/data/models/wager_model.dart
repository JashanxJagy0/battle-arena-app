import '../../domain/entities/wager.dart';

class WagerTimelineEventModel extends WagerTimelineEvent {
  const WagerTimelineEventModel({
    required super.event,
    required super.timestamp,
    super.description,
  });

  factory WagerTimelineEventModel.fromJson(Map<String, dynamic> json) {
    return WagerTimelineEventModel(
      event: json['event'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      description: json['description'] as String?,
    );
  }
}

class WagerModel extends Wager {
  const WagerModel({
    required super.id,
    required super.gameType,
    required super.entryAmount,
    required super.wonAmount,
    required super.status,
    required super.createdAt,
    super.settledAt,
    super.matchId,
    super.tournamentId,
    super.timeline,
  });

  factory WagerModel.fromJson(Map<String, dynamic> json) {
    return WagerModel(
      id: json['id'] as String? ?? '',
      gameType: _parseGame(json['gameType'] as String? ?? json['game'] as String? ?? ''),
      entryAmount: (json['entryAmount'] as num?)?.toDouble() ?? (json['amount'] as num?)?.toDouble() ?? 0.0,
      wonAmount: (json['wonAmount'] as num?)?.toDouble() ?? (json['prize'] as num?)?.toDouble() ?? 0.0,
      status: _parseStatus(json['status'] as String? ?? ''),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      settledAt: json['settledAt'] != null ? DateTime.tryParse(json['settledAt'] as String) : null,
      matchId: json['matchId'] as String?,
      tournamentId: json['tournamentId'] as String?,
      timeline: (json['timeline'] as List<dynamic>? ?? [])
          .map((e) => WagerTimelineEventModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static WagerStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'won': return WagerStatus.won;
      case 'lost': return WagerStatus.lost;
      case 'refunded': return WagerStatus.refunded;
      case 'cancelled': return WagerStatus.cancelled;
      default: return WagerStatus.active;
    }
  }

  static WagerGameType _parseGame(String game) {
    if (game.toLowerCase().contains('free') || game.toLowerCase() == 'freefire') {
      return WagerGameType.freefire;
    }
    return WagerGameType.ludo;
  }
}

class WagerStatsModel extends WagerStats {
  const WagerStatsModel({
    required super.totalWagered,
    required super.totalWon,
    required super.totalLost,
    required super.netProfit,
    required super.roi,
    required super.totalBets,
  });

  factory WagerStatsModel.fromJson(Map<String, dynamic> json) {
    return WagerStatsModel(
      totalWagered: (json['totalWagered'] as num?)?.toDouble() ?? 0.0,
      totalWon: (json['totalWon'] as num?)?.toDouble() ?? 0.0,
      totalLost: (json['totalLost'] as num?)?.toDouble() ?? 0.0,
      netProfit: (json['netProfit'] as num?)?.toDouble() ?? 0.0,
      roi: (json['roi'] as num?)?.toDouble() ?? 0.0,
      totalBets: json['totalBets'] as int? ?? 0,
    );
  }
}
