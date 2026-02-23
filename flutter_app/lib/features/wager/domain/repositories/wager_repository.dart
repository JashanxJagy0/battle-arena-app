import '../entities/wager.dart';

abstract class WagerRepository {
  Future<List<Wager>> getWagers({String? period, int page});
  Future<WagerStats> getWagerStats({String? period});
  Future<Wager> getWagerDetail(String wagerId);
  Future<List<Map<String, dynamic>>> getChartData({String period});
}
