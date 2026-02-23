import 'package:equatable/equatable.dart';

class Wallet extends Equatable {
  final double mainBalance;
  final double winningBalance;
  final double bonusBalance;
  final double lockedBalance;

  const Wallet({
    required this.mainBalance,
    required this.winningBalance,
    required this.bonusBalance,
    required this.lockedBalance,
  });

  double get totalBalance => mainBalance + winningBalance + bonusBalance;

  @override
  List<Object?> get props => [mainBalance, winningBalance, bonusBalance, lockedBalance];
}
