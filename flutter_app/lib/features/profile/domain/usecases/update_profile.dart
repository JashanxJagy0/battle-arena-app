import '../entities/user_profile.dart';
import '../repositories/profile_repository.dart';

class UpdateProfile {
  final ProfileRepository _repository;
  UpdateProfile(this._repository);
  Future<UserProfile> call({
    String? username,
    String? email,
    String? freefireUid,
    String? freefireIgn,
    String? avatarUrl,
  }) => _repository.updateProfile(
    username: username,
    email: email,
    freefireUid: freefireUid,
    freefireIgn: freefireIgn,
    avatarUrl: avatarUrl,
  );
}
