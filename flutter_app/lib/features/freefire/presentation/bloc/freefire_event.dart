import 'package:equatable/equatable.dart';

abstract class FreefireEvent extends Equatable {
  const FreefireEvent();

  @override
  List<Object?> get props => [];
}

class LoadTournaments extends FreefireEvent {
  final String? gameMode;
  final double? minEntryFee;
  final double? maxEntryFee;

  const LoadTournaments({this.gameMode, this.minEntryFee, this.maxEntryFee});

  @override
  List<Object?> get props => [gameMode, minEntryFee, maxEntryFee];
}

class LoadTournamentDetail extends FreefireEvent {
  final String tournamentId;

  const LoadTournamentDetail(this.tournamentId);

  @override
  List<Object?> get props => [tournamentId];
}

class JoinTournament extends FreefireEvent {
  final String tournamentId;

  const JoinTournament(this.tournamentId);

  @override
  List<Object?> get props => [tournamentId];
}

class CheckIn extends FreefireEvent {
  final String tournamentId;

  const CheckIn(this.tournamentId);

  @override
  List<Object?> get props => [tournamentId];
}

class LoadRoom extends FreefireEvent {
  final String tournamentId;

  const LoadRoom(this.tournamentId);

  @override
  List<Object?> get props => [tournamentId];
}

class SubmitResult extends FreefireEvent {
  final String tournamentId;
  final int placement;
  final int kills;

  const SubmitResult({
    required this.tournamentId,
    required this.placement,
    required this.kills,
  });

  @override
  List<Object?> get props => [tournamentId, placement, kills];
}
