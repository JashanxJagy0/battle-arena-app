import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/network/api_client.dart';
import '../core/network/websocket_client.dart';
import '../core/services/storage_service.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/wallet/data/datasources/wallet_remote_datasource.dart';
import '../features/wallet/data/repositories/wallet_repository_impl.dart';
import '../features/wallet/domain/usecases/get_balance_usecase.dart';
import '../features/wallet/domain/usecases/get_transactions_usecase.dart';
import '../features/wallet/domain/usecases/deposit_crypto_usecase.dart';
import '../features/wallet/domain/usecases/withdraw_crypto_usecase.dart';
import '../features/wallet/presentation/bloc/wallet_bloc.dart';
import '../features/ludo/data/repositories/ludo_repository_impl.dart';
import '../features/ludo/presentation/bloc/ludo_bloc.dart';
import '../features/freefire/data/repositories/tournament_repository_impl.dart';
import '../features/freefire/domain/usecases/get_tournaments_usecase.dart';
import '../features/freefire/domain/usecases/get_tournament_details_usecase.dart';
import '../features/freefire/domain/usecases/join_tournament_usecase.dart';
import '../features/freefire/domain/usecases/submit_result_usecase.dart';
import '../features/freefire/presentation/bloc/freefire_bloc.dart';
import 'routes.dart';
import 'theme.dart';

class BattleArenaApp extends StatelessWidget {
  final AuthBloc authBloc;
  final ApiClient apiClient;
  final StorageService storageService;

  const BattleArenaApp({
    super.key,
    required this.authBloc,
    required this.apiClient,
    required this.storageService,
  });

  @override
  Widget build(BuildContext context) {
    final walletRemoteDataSource =
        WalletRemoteDataSource(apiClient: apiClient);
    final walletRepository =
        WalletRepositoryImpl(remoteDataSource: walletRemoteDataSource);
    final walletBloc = WalletBloc(
      getBalance: GetBalanceUseCase(walletRepository),
      getTransactions: GetTransactionsUseCase(walletRepository),
      depositCrypto: DepositCryptoUseCase(walletRepository),
      withdrawCrypto: WithdrawCryptoUseCase(walletRepository),
      repository: walletRepository,
    );

    final wsClient = WebSocketClient(storageService: storageService);
    final ludoRepository = LudoRepositoryImpl(
      apiClient: apiClient,
      wsClient: wsClient,
    );
    final ludoBloc = LudoBloc(repository: ludoRepository);

    final tournamentRepository =
        TournamentRepositoryImpl(apiClient: apiClient);
    final freefireBloc = FreefireBloc(
      getTournaments: GetTournamentsUseCase(tournamentRepository),
      getTournamentDetails: GetTournamentDetailsUseCase(tournamentRepository),
      joinTournament: JoinTournamentUseCase(tournamentRepository),
      submitResult: SubmitResultUseCase(tournamentRepository),
      repository: tournamentRepository,
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: authBloc),
        BlocProvider<WalletBloc>.value(value: walletBloc),
        BlocProvider<LudoBloc>.value(value: ludoBloc),
        BlocProvider<FreefireBloc>.value(value: freefireBloc),
      ],
      child: MaterialApp.router(
        title: 'Battle Arena',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: AppRouter.createRouter(authBloc),
      ),
    );
  }
}
