import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_tournaments_usecase.dart';
import '../../domain/usecases/get_tournament_details_usecase.dart';
import '../../domain/usecases/join_tournament_usecase.dart';
import '../../domain/usecases/submit_result_usecase.dart';
import '../../domain/repositories/tournament_repository.dart';
import 'freefire_event.dart';
import 'freefire_state.dart';

export 'freefire_event.dart';
export 'freefire_state.dart';

class FreefireBloc extends Bloc<FreefireEvent, FreefireState> {
  final GetTournamentsUseCase _getTournaments;
  final GetTournamentDetailsUseCase _getTournamentDetails;
  final JoinTournamentUseCase _joinTournament;
  final SubmitResultUseCase _submitResult;
  final TournamentRepository _repository;

  FreefireBloc({
    required GetTournamentsUseCase getTournaments,
    required GetTournamentDetailsUseCase getTournamentDetails,
    required JoinTournamentUseCase joinTournament,
    required SubmitResultUseCase submitResult,
    required TournamentRepository repository,
  })  : _getTournaments = getTournaments,
        _getTournamentDetails = getTournamentDetails,
        _joinTournament = joinTournament,
        _submitResult = submitResult,
        _repository = repository,
        super(const FreefireInitial()) {
    on<LoadTournaments>(_onLoadTournaments);
    on<LoadTournamentDetail>(_onLoadTournamentDetail);
    on<JoinTournament>(_onJoinTournament);
    on<CheckIn>(_onCheckIn);
    on<LoadRoom>(_onLoadRoom);
    on<SubmitResult>(_onSubmitResult);
  }

  Future<void> _onLoadTournaments(
    LoadTournaments event,
    Emitter<FreefireState> emit,
  ) async {
    emit(const TournamentsLoading());
    try {
      final all = await _getTournaments();
      final filtered = all.where((t) {
        if (event.gameMode != null && event.gameMode!.isNotEmpty) {
          if (t.gameMode.toLowerCase() != event.gameMode!.toLowerCase()) {
            return false;
          }
        }
        if (event.minEntryFee != null && t.entryFee < event.minEntryFee!) {
          return false;
        }
        if (event.maxEntryFee != null && t.entryFee > event.maxEntryFee!) {
          return false;
        }
        return true;
      }).toList();

      emit(TournamentsLoaded(
        upcoming: filtered.where((t) => t.isUpcoming).toList(),
        live: filtered.where((t) => t.isLive).toList(),
        myTournaments: filtered.where((t) => t.hasJoined).toList(),
      ));
    } catch (e) {
      emit(FreefireError(e.toString()));
    }
  }

  Future<void> _onLoadTournamentDetail(
    LoadTournamentDetail event,
    Emitter<FreefireState> emit,
  ) async {
    emit(const TournamentsLoading());
    try {
      final tournament = await _getTournamentDetails(event.tournamentId);
      emit(TournamentDetailLoaded(tournament));
    } catch (e) {
      emit(FreefireError(e.toString()));
    }
  }

  Future<void> _onJoinTournament(
    JoinTournament event,
    Emitter<FreefireState> emit,
  ) async {
    emit(const TournamentsLoading());
    try {
      final tournament = await _joinTournament(event.tournamentId);
      emit(JoinSuccess(tournament));
    } catch (e) {
      emit(FreefireError(e.toString()));
    }
  }

  Future<void> _onCheckIn(
    CheckIn event,
    Emitter<FreefireState> emit,
  ) async {
    emit(const TournamentsLoading());
    try {
      final tournament = await _repository.checkIn(event.tournamentId);
      emit(CheckInSuccess(tournament));
    } catch (e) {
      emit(FreefireError(e.toString()));
    }
  }

  Future<void> _onLoadRoom(
    LoadRoom event,
    Emitter<FreefireState> emit,
  ) async {
    emit(const TournamentsLoading());
    try {
      final room = await _repository.getRoomDetails(event.tournamentId);
      emit(RoomDetailsLoaded(room));
    } catch (e) {
      emit(FreefireError(e.toString()));
    }
  }

  Future<void> _onSubmitResult(
    SubmitResult event,
    Emitter<FreefireState> emit,
  ) async {
    emit(const TournamentsLoading());
    try {
      await _submitResult(
        tournamentId: event.tournamentId,
        placement: event.placement,
        kills: event.kills,
      );
      emit(const ResultSubmitted());
    } catch (e) {
      emit(FreefireError(e.toString()));
    }
  }
}
