import '../entities/ludo_game.dart';
import '../repositories/ludo_repository.dart';

class CreateMatchUseCase {
  final LudoRepository repository;
  CreateMatchUseCase(this.repository);

  Future<LudoGame> call(String gameMode, double entryFee) =>
      repository.createMatch(gameMode: gameMode, entryFee: entryFee);
}
