import 'package:equatable/equatable.dart';

class ParticipantModel extends Equatable {
  final String userId;
  final String username;
  final int kills;
  final int placement;
  final int points;
  final bool isCheckedIn;

  const ParticipantModel({
    required this.userId,
    required this.username,
    required this.kills,
    required this.placement,
    required this.points,
    required this.isCheckedIn,
  });

  factory ParticipantModel.fromJson(Map<String, dynamic> json) {
    return ParticipantModel(
      userId: json['userId'] as String? ?? json['_id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      kills: json['kills'] as int? ?? 0,
      placement: json['placement'] as int? ?? 0,
      points: json['points'] as int? ?? 0,
      isCheckedIn: json['isCheckedIn'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props =>
      [userId, username, kills, placement, points, isCheckedIn];
}
