import '../entities/wager.dart';
import '../repositories/wager_repository.dart';

class GetWagerStats {
  final WagerRepository _repository;
  GetWagerStats(this._repository);

  Future<WagerStats> call({String? period}) => _repository.getWagerStats(period: period);
}
