import '../../domain/entities/wallet.dart';

class WalletModel extends Wallet {
  const WalletModel({
    required super.mainBalance,
    required super.winningBalance,
    required super.bonusBalance,
    required super.lockedBalance,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      mainBalance: (json['mainBalance'] as num?)?.toDouble() ?? 0.0,
      winningBalance: (json['winningBalance'] as num?)?.toDouble() ?? 0.0,
      bonusBalance: (json['bonusBalance'] as num?)?.toDouble() ?? 0.0,
      lockedBalance: (json['lockedBalance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
