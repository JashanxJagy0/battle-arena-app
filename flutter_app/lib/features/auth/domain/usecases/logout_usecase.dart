import '../repositories/auth_repository.dart';

class LogoutUseCase {
  final AuthRepository _repository;

  LogoutUseCase({required AuthRepository repository}) : _repository = repository;

  Future<void> call() => _repository.logout();
}
