import '../repositories/ludo_repository.dart';

class RollDiceUseCase {
  final LudoRepository repository;
  RollDiceUseCase(this.repository);

  Future<Map<String, dynamic>> call(String matchId) => repository.rollDice(matchId);
}
