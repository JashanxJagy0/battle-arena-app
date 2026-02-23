import '../entities/wager.dart';
import '../repositories/wager_repository.dart';

class GetWagers {
  final WagerRepository _repository;
  GetWagers(this._repository);

  Future<List<Wager>> call({String? period, int page = 1}) =>
      _repository.getWagers(period: period, page: page);
}
