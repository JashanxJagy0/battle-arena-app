import '../repositories/tournament_repository.dart';

class SubmitResultUseCase {
  final TournamentRepository repository;

  SubmitResultUseCase(this.repository);

  Future<void> call({
    required String tournamentId,
    required int placement,
    required int kills,
  }) =>
      repository.submitResult(
        tournamentId: tournamentId,
        placement: placement,
        kills: kills,
      );
}
