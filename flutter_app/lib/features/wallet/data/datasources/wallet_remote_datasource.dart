import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../models/wallet_model.dart';
import '../models/transaction_model.dart';
import '../models/crypto_rate_model.dart';

class WalletRemoteDataSource {
  final ApiClient _apiClient;

  WalletRemoteDataSource({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<WalletModel> getBalance() async {
    final response = await _apiClient.get<Map<String, dynamic>>(ApiEndpoints.walletBalance);
    final data = response.data!;
    final walletData = data['wallet'] as Map<String, dynamic>? ?? data;
    return WalletModel.fromJson(walletData);
  }

  Future<List<TransactionModel>> getTransactions({
    String? type,
    DateTime? from,
    DateTime? to,
    int page = 1,
  }) async {
    final params = <String, dynamic>{'page': page, 'limit': 20};
    if (type != null && type != 'all') params['type'] = type;
    if (from != null) params['from'] = from.toIso8601String();
    if (to != null) params['to'] = to.toIso8601String();

    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.transactions,
      queryParameters: params,
    );
    final data = response.data!;
    final list = data['transactions'] as List<dynamic>? ??
        data['data'] as List<dynamic>? ??
        [];
    return list.map((e) => TransactionModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> createDeposit({
    required String currency,
    required String network,
    required double amountUsd,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.deposit,
      data: {'currency': currency, 'network': network, 'amountUsd': amountUsd},
    );
    return response.data!;
  }

  Future<Map<String, dynamic>> requestWithdrawal({
    required String currency,
    required String network,
    required double amountUsd,
    required String walletAddress,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.withdraw,
      data: {
        'currency': currency,
        'network': network,
        'amountUsd': amountUsd,
        'walletAddress': walletAddress,
      },
    );
    return response.data!;
  }

  Future<List<CryptoRateModel>> getCryptoRates() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>('/wallet/crypto-rates');
      final data = response.data!;
      final list = data['rates'] as List<dynamic>? ?? [];
      return list.map((e) => CryptoRateModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return _defaultRates;
    }
  }

  Future<Map<String, dynamic>> checkDepositStatus(String depositId) async {
    final response =
        await _apiClient.get<Map<String, dynamic>>('/wallet/deposit/$depositId/status');
    return response.data!;
  }

  static final List<CryptoRateModel> _defaultRates = [
    const CryptoRateModel(currency: 'BTC', name: 'Bitcoin', usdRate: 65000, change24h: 2.5),
    const CryptoRateModel(currency: 'ETH', name: 'Ethereum', usdRate: 3500, change24h: 1.8),
    const CryptoRateModel(currency: 'USDT', name: 'Tether', usdRate: 1.0, change24h: 0.01),
    const CryptoRateModel(currency: 'SOL', name: 'Solana', usdRate: 180, change24h: 3.2),
    const CryptoRateModel(currency: 'BNB', name: 'BNB', usdRate: 600, change24h: 1.1),
    const CryptoRateModel(currency: 'USDC', name: 'USD Coin', usdRate: 1.0, change24h: 0.02),
  ];
}
