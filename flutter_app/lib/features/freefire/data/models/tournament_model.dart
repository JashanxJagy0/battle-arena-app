import '../../domain/entities/tournament.dart';
import '../../domain/entities/prize_pool.dart';

class TournamentModel extends Tournament {
  const TournamentModel({
    required super.id,
    required super.title,
    required super.gameMode,
    required super.entryFee,
    required super.prizePool,
    required super.status,
    required super.startTime,
    required super.maxParticipants,
    required super.currentParticipants,
    super.hasJoined,
    super.isCheckedIn,
    super.map,
  });

  factory TournamentModel.fromJson(Map<String, dynamic> json) {
    final prizeJson = json['prizePool'] as Map<String, dynamic>? ?? {};
    final positions = <int, double>{};
    if (prizeJson['positions'] is Map) {
      (prizeJson['positions'] as Map).forEach((k, v) {
        final pos = int.tryParse(k.toString());
        if (pos != null) positions[pos] = (v as num).toDouble();
      });
    }

    return TournamentModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      gameMode: json['gameMode'] as String? ?? 'solo',
      entryFee: (json['entryFee'] as num?)?.toDouble() ?? 0.0,
      prizePool: PrizePool(
        total: (prizeJson['total'] as num?)?.toDouble() ?? 0.0,
        firstPlace: (prizeJson['firstPlace'] as num?)?.toDouble() ?? 0.0,
        secondPlace: (prizeJson['secondPlace'] as num?)?.toDouble() ?? 0.0,
        thirdPlace: (prizeJson['thirdPlace'] as num?)?.toDouble() ?? 0.0,
        positions: positions,
      ),
      status: json['status'] as String? ?? 'upcoming',
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : DateTime.now(),
      maxParticipants: json['maxParticipants'] as int? ?? 0,
      currentParticipants: json['currentParticipants'] as int? ?? 0,
      hasJoined: json['hasJoined'] as bool? ?? false,
      isCheckedIn: json['isCheckedIn'] as bool? ?? false,
      map: json['map'] as String?,
    );
  }
}
