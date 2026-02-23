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
import '../features/bonus/data/datasources/bonus_remote_datasource.dart';
import '../features/bonus/data/repositories/bonus_repository_impl.dart';
import '../features/bonus/domain/usecases/claim_daily_bonus.dart';
import '../features/bonus/domain/usecases/claim_weekly_bonus.dart';
import '../features/bonus/domain/usecases/claim_monthly_bonus.dart';
import '../features/bonus/domain/usecases/redeem_promo_code.dart';
import '../features/bonus/presentation/bloc/bonus_bloc.dart';
import '../features/wager/data/datasources/wager_remote_datasource.dart';
import '../features/wager/data/repositories/wager_repository_impl.dart';
import '../features/wager/domain/usecases/get_wagers.dart';
import '../features/wager/domain/usecases/get_wager_stats.dart';
import '../features/wager/presentation/bloc/wager_bloc.dart';
import '../features/profile/data/datasources/profile_remote_datasource.dart';
import '../features/profile/data/repositories/profile_repository_impl.dart';
import '../features/profile/domain/usecases/get_profile.dart';
import '../features/profile/domain/usecases/update_profile.dart';
import '../features/profile/presentation/bloc/profile_bloc.dart';
import '../features/leaderboard/data/datasources/leaderboard_remote_datasource.dart';
import '../features/leaderboard/data/repositories/leaderboard_repository_impl.dart';
import '../features/leaderboard/domain/usecases/get_leaderboard.dart';
import '../features/leaderboard/presentation/bloc/leaderboard_bloc.dart';
import '../features/referral/data/datasources/referral_remote_datasource.dart';
import '../features/referral/data/repositories/referral_repository_impl.dart';
import '../features/referral/domain/usecases/get_referral_stats.dart';
import '../features/referral/presentation/bloc/referral_bloc.dart';
import '../features/notifications/data/datasources/notification_remote_datasource.dart';
import '../features/notifications/data/repositories/notification_repository_impl.dart';
import '../features/notifications/domain/usecases/get_notifications.dart';
import '../features/notifications/domain/usecases/mark_notification_read.dart';
import '../features/notifications/presentation/bloc/notification_bloc.dart';
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

    final bonusRemoteDataSource = BonusRemoteDataSource(apiClient: apiClient);
    final bonusRepository = BonusRepositoryImpl(remoteDataSource: bonusRemoteDataSource);
    final bonusBloc = BonusBloc(
      claimDailyBonus: ClaimDailyBonus(bonusRepository),
      claimWeeklyBonus: ClaimWeeklyBonus(bonusRepository),
      claimMonthlyBonus: ClaimMonthlyBonus(bonusRepository),
      redeemPromoCode: RedeemPromoCode(bonusRepository),
      repository: bonusRepository,
    );

    final wagerRemoteDataSource = WagerRemoteDataSource(apiClient: apiClient);
    final wagerRepository = WagerRepositoryImpl(remoteDataSource: wagerRemoteDataSource);
    final wagerBloc = WagerBloc(
      getWagers: GetWagers(wagerRepository),
      getWagerStats: GetWagerStats(wagerRepository),
      repository: wagerRepository,
    );

    final profileRemoteDataSource = ProfileRemoteDataSource(apiClient: apiClient);
    final profileRepository = ProfileRepositoryImpl(remoteDataSource: profileRemoteDataSource);
    final profileBloc = ProfileBloc(
      getProfile: GetProfile(profileRepository),
      updateProfile: UpdateProfile(profileRepository),
    );

    final leaderboardRemoteDataSource = LeaderboardRemoteDataSource(apiClient: apiClient);
    final leaderboardRepository = LeaderboardRepositoryImpl(remoteDataSource: leaderboardRemoteDataSource);
    final leaderboardBloc = LeaderboardBloc(
      getLeaderboard: GetLeaderboard(leaderboardRepository),
      repository: leaderboardRepository,
    );

    final referralRemoteDataSource = ReferralRemoteDataSource(apiClient: apiClient);
    final referralRepository = ReferralRepositoryImpl(remoteDataSource: referralRemoteDataSource);
    final referralBloc = ReferralBloc(
      getReferralStats: GetReferralStats(referralRepository),
    );

    final notificationRemoteDataSource = NotificationRemoteDataSource(apiClient: apiClient);
    final notificationRepository = NotificationRepositoryImpl(remoteDataSource: notificationRemoteDataSource);
    final notificationBloc = NotificationBloc(
      getNotifications: GetNotifications(notificationRepository),
      markNotificationRead: MarkNotificationRead(notificationRepository),
      repository: notificationRepository,
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: authBloc),
        BlocProvider<WalletBloc>.value(value: walletBloc),
        BlocProvider<LudoBloc>.value(value: ludoBloc),
        BlocProvider<FreefireBloc>.value(value: freefireBloc),
        BlocProvider<BonusBloc>.value(value: bonusBloc),
        BlocProvider<WagerBloc>.value(value: wagerBloc),
        BlocProvider<ProfileBloc>.value(value: profileBloc),
        BlocProvider<LeaderboardBloc>.value(value: leaderboardBloc),
        BlocProvider<ReferralBloc>.value(value: referralBloc),
        BlocProvider<NotificationBloc>.value(value: notificationBloc),
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
