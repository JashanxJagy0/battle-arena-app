import 'package:equatable/equatable.dart';

import '../../domain/entities/tournament.dart';
import '../../domain/entities/custom_room.dart';

abstract class FreefireState extends Equatable {
  const FreefireState();

  @override
  List<Object?> get props => [];
}

class FreefireInitial extends FreefireState {
  const FreefireInitial();
}

class TournamentsLoading extends FreefireState {
  const TournamentsLoading();
}

class TournamentsLoaded extends FreefireState {
  final List<Tournament> upcoming;
  final List<Tournament> live;
  final List<Tournament> myTournaments;

  const TournamentsLoaded({
    required this.upcoming,
    required this.live,
    required this.myTournaments,
  });

  @override
  List<Object?> get props => [upcoming, live, myTournaments];
}

class TournamentDetailLoaded extends FreefireState {
  final Tournament tournament;

  const TournamentDetailLoaded(this.tournament);

  @override
  List<Object?> get props => [tournament];
}

class JoinSuccess extends FreefireState {
  final Tournament tournament;

  const JoinSuccess(this.tournament);

  @override
  List<Object?> get props => [tournament];
}

class CheckInSuccess extends FreefireState {
  final Tournament tournament;

  const CheckInSuccess(this.tournament);

  @override
  List<Object?> get props => [tournament];
}

class RoomDetailsLoaded extends FreefireState {
  final CustomRoom room;

  const RoomDetailsLoaded(this.room);

  @override
  List<Object?> get props => [room];
}

class ResultSubmitted extends FreefireState {
  const ResultSubmitted();
}

class FreefireError extends FreefireState {
  final String message;

  const FreefireError(this.message);

  @override
  List<Object?> get props => [message];
}
