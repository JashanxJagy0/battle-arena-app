import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_profile.dart';
import '../../domain/usecases/update_profile.dart';
import 'profile_event.dart';
import 'profile_state.dart';

export 'profile_event.dart';
export 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetProfile _getProfile;
  final UpdateProfile _updateProfile;

  ProfileBloc({
    required GetProfile getProfile,
    required UpdateProfile updateProfile,
  })  : _getProfile = getProfile,
        _updateProfile = updateProfile,
        super(const ProfileInitial()) {
    on<LoadProfile>(_onLoadProfile);
    on<UpdateProfileEvent>(_onUpdateProfile);
  }

  Future<void> _onLoadProfile(LoadProfile event, Emitter<ProfileState> emit) async {
    emit(const ProfileLoading());
    try {
      final profile = await _getProfile();
      emit(ProfileLoaded(profile: profile));
    } catch (e) {
      emit(ProfileError(message: e.toString()));
    }
  }

  Future<void> _onUpdateProfile(UpdateProfileEvent event, Emitter<ProfileState> emit) async {
    emit(const ProfileLoading());
    try {
      final profile = await _updateProfile(
        username: event.username,
        email: event.email,
        freefireUid: event.freefireUid,
        freefireIgn: event.freefireIgn,
        avatarUrl: event.avatarUrl,
      );
      emit(ProfileUpdated(profile: profile));
    } catch (e) {
      emit(ProfileError(message: e.toString()));
    }
  }
}
