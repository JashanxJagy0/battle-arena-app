import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository _repository;

  LoginUseCase({required AuthRepository repository}) : _repository = repository;

  Future<({String accessToken, String refreshToken, User user})> call({
    required String identifier,
    required String password,
  }) {
    return _repository.login(identifier: identifier, password: password);
  }
}
