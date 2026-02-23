import '../entities/user.dart';

abstract class AuthRepository {
  Future<({String accessToken, String refreshToken, User user})> login({
    required String identifier,
    required String password,
  });

  Future<User> register({
    required String username,
    required String password,
    String? email,
    String? phone,
    String? referralCode,
  });

  Future<void> sendOtp({required String phone});

  Future<({String accessToken, String refreshToken, User user})> verifyOtp({
    required String phone,
    required String otp,
  });

  Future<void> logout();

  Future<User?> getCurrentUser();

  Future<bool> isAuthenticated();
}
