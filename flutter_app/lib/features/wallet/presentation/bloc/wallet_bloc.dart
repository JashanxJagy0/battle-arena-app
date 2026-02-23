import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/crypto_rate.dart';
import '../../domain/usecases/get_balance_usecase.dart';
import '../../domain/usecases/get_transactions_usecase.dart';
import '../../domain/usecases/deposit_crypto_usecase.dart';
import '../../domain/usecases/withdraw_crypto_usecase.dart';
import '../../domain/repositories/wallet_repository.dart';
import 'wallet_event.dart';
import 'wallet_state.dart';

export 'wallet_event.dart';
export 'wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final GetBalanceUseCase _getBalance;
  final GetTransactionsUseCase _getTransactions;
  final DepositCryptoUseCase _depositCrypto;
  final WithdrawCryptoUseCase _withdrawCrypto;
  final WalletRepository _repository;

  WalletBloc({
    required GetBalanceUseCase getBalance,
    required GetTransactionsUseCase getTransactions,
    required DepositCryptoUseCase depositCrypto,
    required WithdrawCryptoUseCase withdrawCrypto,
    required WalletRepository repository,
  })  : _getBalance = getBalance,
        _getTransactions = getTransactions,
        _depositCrypto = depositCrypto,
        _withdrawCrypto = withdrawCrypto,
        _repository = repository,
        super(const WalletInitial()) {
    on<LoadBalance>(_onLoadBalance);
    on<LoadTransactions>(_onLoadTransactions);
    on<CreateDeposit>(_onCreateDeposit);
    on<RequestWithdrawal>(_onRequestWithdrawal);
    on<LoadCryptoRates>(_onLoadCryptoRates);
    on<CheckDepositStatus>(_onCheckDepositStatus);
  }

  Future<void> _onLoadBalance(LoadBalance event, Emitter<WalletState> emit) async {
    emit(const WalletLoading());
    try {
      final wallet = await _getBalance();
      final transactions = await _getTransactions();
      List<CryptoRate> rates = [];
      try {
        rates = await _repository.getCryptoRates();
      } catch (_) {}
      emit(WalletLoaded(wallet: wallet, transactions: transactions, cryptoRates: rates));
    } catch (e) {
      emit(WalletError(message: e.toString()));
    }
  }

  Future<void> _onLoadTransactions(LoadTransactions event, Emitter<WalletState> emit) async {
    try {
      final transactions = await _getTransactions(
        type: event.type,
        from: event.from,
        to: event.to,
        page: event.page,
      );
      final current = state;
      if (current is WalletLoaded) {
        emit(current.copyWith(transactions: transactions));
      }
    } catch (e) {
      emit(WalletError(message: e.toString()));
    }
  }

  Future<void> _onCreateDeposit(CreateDeposit event, Emitter<WalletState> emit) async {
    emit(const WalletLoading());
    try {
      final data = await _depositCrypto(
        currency: event.currency,
        network: event.network,
        amountUsd: event.amountUsd,
      );
      emit(DepositCreated(depositData: data));
    } catch (e) {
      emit(WalletError(message: e.toString()));
    }
  }

  Future<void> _onRequestWithdrawal(RequestWithdrawal event, Emitter<WalletState> emit) async {
    emit(const WalletLoading());
    try {
      final data = await _withdrawCrypto(
        currency: event.currency,
        network: event.network,
        amountUsd: event.amountUsd,
        walletAddress: event.walletAddress,
      );
      emit(WithdrawalRequested(withdrawalData: data));
    } catch (e) {
      emit(WalletError(message: e.toString()));
    }
  }

  Future<void> _onLoadCryptoRates(LoadCryptoRates event, Emitter<WalletState> emit) async {
    try {
      final rates = await _repository.getCryptoRates();
      final current = state;
      if (current is WalletLoaded) {
        emit(current.copyWith(cryptoRates: rates));
      }
    } catch (_) {}
  }

  Future<void> _onCheckDepositStatus(CheckDepositStatus event, Emitter<WalletState> emit) async {
    try {
      final data = await _repository.checkDepositStatus(event.depositId);
      final status = data['status'] as String?;
      if (status == 'completed' || status == 'confirmed') {
        emit(const DepositConfirmed());
        add(const LoadBalance());
      }
    } catch (_) {}
  }
}
