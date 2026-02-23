import '../entities/user_profile.dart';

abstract class ProfileRepository {
  Future<UserProfile> getProfile();
  Future<UserProfile> updateProfile({
    String? username,
    String? email,
    String? freefireUid,
    String? freefireIgn,
    String? avatarUrl,
  });
  Future<void> changePassword({required String currentPassword, required String newPassword});
  Future<void> deleteAccount();
}
