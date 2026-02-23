class LudoMoveModel {
  final int diceValue;
  final int pieceId;
  final int fromPos;
  final int toPos;
  final bool isKill;

  /// e.g. 'normal' | 'kill' | 'enter_home' | 'safe'
  final String moveType;

  const LudoMoveModel({
    required this.diceValue,
    required this.pieceId,
    required this.fromPos,
    required this.toPos,
    required this.isKill,
    required this.moveType,
  });

  factory LudoMoveModel.fromJson(Map<String, dynamic> json) {
    return LudoMoveModel(
      diceValue: (json['diceValue'] as num).toInt(),
      pieceId: (json['pieceId'] as num).toInt(),
      fromPos: (json['fromPos'] as num).toInt(),
      toPos: (json['toPos'] as num).toInt(),
      isKill: json['isKill'] as bool? ?? false,
      moveType: json['moveType'] as String,
    );
  }
}
