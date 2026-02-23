import '../../domain/entities/ludo_player.dart';

class LudoPlayerModel extends LudoPlayer {
  const LudoPlayerModel({
    required super.userId,
    required super.username,
    super.avatar,
    required super.color,
    required super.pieces,
    required super.piecesHome,
    required super.isEliminated,
  });

  factory LudoPlayerModel.fromJson(Map<String, dynamic> json) {
    return LudoPlayerModel(
      userId: json['userId'] as String,
      username: json['username'] as String,
      avatar: json['avatar'] as String?,
      color: json['color'] as String,
      pieces: List<int>.from(
        (json['pieces'] as List<dynamic>).map((e) => (e as num).toInt()),
      ),
      piecesHome: (json['piecesHome'] as num?)?.toInt() ?? 0,
      isEliminated: json['isEliminated'] as bool? ?? false,
    );
  }
}
