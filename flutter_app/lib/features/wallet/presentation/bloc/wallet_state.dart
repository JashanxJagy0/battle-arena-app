import 'package:equatable/equatable.dart';

import '../../domain/entities/wallet.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/crypto_rate.dart';

abstract class WalletState extends Equatable {
  const WalletState();

  @override
  List<Object?> get props => [];
}

class WalletInitial extends WalletState {
  const WalletInitial();
}

class WalletLoading extends WalletState {
  const WalletLoading();
}

class WalletLoaded extends WalletState {
  final Wallet wallet;
  final List<Transaction> transactions;
  final List<CryptoRate> cryptoRates;

  const WalletLoaded({
    required this.wallet,
    required this.transactions,
    required this.cryptoRates,
  });

  @override
  List<Object?> get props => [wallet, transactions, cryptoRates];

  WalletLoaded copyWith({
    Wallet? wallet,
    List<Transaction>? transactions,
    List<CryptoRate>? cryptoRates,
  }) {
    return WalletLoaded(
      wallet: wallet ?? this.wallet,
      transactions: transactions ?? this.transactions,
      cryptoRates: cryptoRates ?? this.cryptoRates,
    );
  }
}

class WalletError extends WalletState {
  final String message;
  const WalletError({required this.message});

  @override
  List<Object?> get props => [message];
}

class DepositCreated extends WalletState {
  final Map<String, dynamic> depositData;
  const DepositCreated({required this.depositData});

  @override
  List<Object?> get props => [depositData];
}

class WithdrawalRequested extends WalletState {
  final Map<String, dynamic> withdrawalData;
  const WithdrawalRequested({required this.withdrawalData});

  @override
  List<Object?> get props => [withdrawalData];
}

class DepositConfirmed extends WalletState {
  const DepositConfirmed();
}
