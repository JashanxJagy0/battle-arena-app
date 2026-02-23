import 'package:equatable/equatable.dart';

class CryptoRate extends Equatable {
  final String currency;
  final String name;
  final double usdRate;
  final double change24h;

  const CryptoRate({
    required this.currency,
    required this.name,
    required this.usdRate,
    required this.change24h,
  });

  @override
  List<Object?> get props => [currency, name, usdRate, change24h];
}
