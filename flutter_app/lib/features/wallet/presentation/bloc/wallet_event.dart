import 'package:equatable/equatable.dart';

abstract class WalletEvent extends Equatable {
  const WalletEvent();

  @override
  List<Object?> get props => [];
}

class LoadBalance extends WalletEvent {
  const LoadBalance();
}

class LoadTransactions extends WalletEvent {
  final String? type;
  final DateTime? from;
  final DateTime? to;
  final int page;

  const LoadTransactions({this.type, this.from, this.to, this.page = 1});

  @override
  List<Object?> get props => [type, from, to, page];
}

class CreateDeposit extends WalletEvent {
  final String currency;
  final String network;
  final double amountUsd;

  const CreateDeposit({
    required this.currency,
    required this.network,
    required this.amountUsd,
  });

  @override
  List<Object?> get props => [currency, network, amountUsd];
}

class RequestWithdrawal extends WalletEvent {
  final String currency;
  final String network;
  final double amountUsd;
  final String walletAddress;

  const RequestWithdrawal({
    required this.currency,
    required this.network,
    required this.amountUsd,
    required this.walletAddress,
  });

  @override
  List<Object?> get props => [currency, network, amountUsd, walletAddress];
}

class LoadCryptoRates extends WalletEvent {
  const LoadCryptoRates();
}

class CheckDepositStatus extends WalletEvent {
  final String depositId;
  const CheckDepositStatus(this.depositId);

  @override
  List<Object?> get props => [depositId];
}
