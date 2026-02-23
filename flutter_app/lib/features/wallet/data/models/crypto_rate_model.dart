import '../../domain/entities/crypto_rate.dart';

class CryptoRateModel extends CryptoRate {
  const CryptoRateModel({
    required super.currency,
    required super.name,
    required super.usdRate,
    required super.change24h,
  });

  factory CryptoRateModel.fromJson(Map<String, dynamic> json) {
    return CryptoRateModel(
      currency: json['currency'] as String,
      name: json['name'] as String,
      usdRate: (json['usdRate'] as num).toDouble(),
      change24h: (json['change24h'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
