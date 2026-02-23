import '../repositories/ludo_repository.dart';

class MovePieceUseCase {
  final LudoRepository repository;
  MovePieceUseCase(this.repository);

  Future<void> call({
    required String matchId,
    required int pieceId,
    required int toPos,
  }) =>
      repository.movePiece(matchId: matchId, pieceId: pieceId, toPos: toPos);
}
