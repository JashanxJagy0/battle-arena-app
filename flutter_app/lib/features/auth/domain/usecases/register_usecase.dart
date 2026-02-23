import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository _repository;

  RegisterUseCase({required AuthRepository repository}) : _repository = repository;

  Future<User> call({
    required String username,
    required String password,
    String? email,
    String? phone,
    String? referralCode,
  }) {
    return _repository.register(
      username: username,
      password: password,
      email: email,
      phone: phone,
      referralCode: referralCode,
    );
  }
}
