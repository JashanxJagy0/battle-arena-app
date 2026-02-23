import '../entities/ludo_game.dart';
import '../repositories/ludo_repository.dart';

class JoinMatchUseCase {
  final LudoRepository repository;
  JoinMatchUseCase(this.repository);

  Future<LudoGame> call(String matchId) => repository.joinMatch(matchId);
}
