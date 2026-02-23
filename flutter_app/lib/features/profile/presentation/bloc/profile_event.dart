import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object?> get props => [];
}

class LoadProfile extends ProfileEvent {
  const LoadProfile();
}

class UpdateProfileEvent extends ProfileEvent {
  final String? username;
  final String? email;
  final String? freefireUid;
  final String? freefireIgn;
  final String? avatarUrl;

  const UpdateProfileEvent({this.username, this.email, this.freefireUid, this.freefireIgn, this.avatarUrl});

  @override
  List<Object?> get props => [username, email, freefireUid, freefireIgn, avatarUrl];
}
