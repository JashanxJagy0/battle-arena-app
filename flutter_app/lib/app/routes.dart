import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/onboarding_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/otp_verification_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/wallet/presentation/pages/wallet_screen.dart';
import '../features/wallet/presentation/pages/deposit_screen.dart';
import '../features/wallet/presentation/pages/withdraw_screen.dart';
import '../features/wallet/presentation/pages/transaction_history_screen.dart';
import '../features/ludo/presentation/pages/ludo_lobby_screen.dart';
import '../features/ludo/presentation/pages/ludo_matchmaking_screen.dart';
import '../features/ludo/presentation/pages/ludo_game_screen.dart';
import '../features/ludo/presentation/pages/ludo_result_screen.dart';
import '../features/freefire/presentation/pages/tournament_list_screen.dart';
import '../features/freefire/presentation/pages/tournament_detail_screen.dart';
import '../features/freefire/presentation/pages/room_card_screen.dart';
import '../features/freefire/presentation/pages/join_tournament_screen.dart';
import '../features/freefire/presentation/pages/tournament_result_screen.dart';
import '../features/freefire/domain/entities/tournament.dart';
import '../features/bonus/presentation/screens/bonus_screen.dart';
import '../features/wager/presentation/screens/wager_history_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/profile/presentation/screens/edit_profile_screen.dart';
import '../features/profile/presentation/screens/settings_screen.dart';
import '../features/leaderboard/presentation/screens/leaderboard_screen.dart';
import '../features/referral/presentation/screens/referral_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';

class AppRouter {
  static GoRouter createRouter(AuthBloc authBloc) {
    return GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        final authState = authBloc.state;
        final isAuthenticated = authState is Authenticated;
        final isAuthRoute = state.matchedLocation == '/login' ||
            state.matchedLocation == '/register' ||
            state.matchedLocation == '/otp' ||
            state.matchedLocation == '/onboarding' ||
            state.matchedLocation == '/';

        if (!isAuthenticated && !isAuthRoute) {
          return '/login';
        }
        return null;
      },
      refreshListenable: _AuthStateNotifier(authBloc),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/otp',
          builder: (context, state) => const OTPVerificationScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) => HomeScreen(child: child),
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const _HomeTab(),
            ),
            GoRoute(
              path: '/home/ludo',
              builder: (context, state) => const LudoLobbyScreen(),
            ),
            GoRoute(
              path: '/home/tournaments',
              builder: (context, state) => const TournamentListScreen(),
            ),
            GoRoute(
              path: '/home/wallet',
              builder: (context, state) => const WalletScreen(),
            ),
            GoRoute(
              path: '/home/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/ludo/matchmaking',
          builder: (context, state) {
            final extra = state.extra as Map<String, String>? ?? {};
            return LudoMatchmakingScreen(
              matchId: extra['matchId'] ?? '',
              matchCode: extra['matchCode'] ?? '',
            );
          },
        ),
        GoRoute(
          path: '/ludo/match/:matchId',
          builder: (context, state) {
            final extra = state.extra as Map<String, String>? ?? {};
            return LudoGameScreen(
              matchId: state.pathParameters['matchId']!,
              myUserId: extra['myUserId'] ?? '',
            );
          },
        ),
        GoRoute(
          path: '/ludo/result/:matchId',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return LudoResultScreen(
              matchId: state.pathParameters['matchId']!,
              winnerId: extra['winnerId'] as String? ?? '',
              myUserId: extra['myUserId'] as String? ?? '',
              prizeWon: (extra['prizeWon'] as num?)?.toDouble() ?? 0.0,
            );
          },
        ),
        GoRoute(
          path: '/freefire/tournaments',
          builder: (context, state) => const TournamentListScreen(),
        ),
        GoRoute(
          path: '/freefire/tournament/:id/detail',
          builder: (context, state) => TournamentDetailScreen(
            tournamentId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/freefire/tournament/:id/join',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return JoinTournamentScreen(
              tournamentId: state.pathParameters['id']!,
              tournament: extra['tournament'] as Tournament?,
            );
          },
        ),
        GoRoute(
          path: '/freefire/tournament/:id/room',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return RoomCardScreen(
              tournamentId: state.pathParameters['id']!,
              tournamentTitle: extra['title'] as String?,
              roomVisibleAt: extra['roomVisibleAt'] as DateTime?,
            );
          },
        ),
        GoRoute(
          path: '/freefire/tournament/:id/results',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return TournamentResultScreen(
              tournamentId: state.pathParameters['id']!,
              currentUserId: extra['userId'] as String?,
            );
          },
        ),
        GoRoute(
          path: '/wallet/deposit',
          builder: (context, state) => const DepositScreen(),
        ),
        GoRoute(
          path: '/wallet/withdraw',
          builder: (context, state) => const WithdrawScreen(),
        ),
        GoRoute(
          path: '/wallet/transactions',
          builder: (context, state) => const TransactionHistoryScreen(),
        ),
        GoRoute(
          path: '/wagers',
          builder: (context, state) => const WagerHistoryScreen(),
        ),
        GoRoute(
          path: '/bonuses',
          builder: (context, state) => const BonusScreen(),
        ),
        GoRoute(
          path: '/leaderboard',
          builder: (context, state) => const LeaderboardScreen(),
        ),
        GoRoute(
          path: '/referral',
          builder: (context, state) => const ReferralScreen(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/profile/edit',
          builder: (context, state) => const EditProfileScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    );
  }
}

class _AuthStateNotifier extends ChangeNotifier {
  _AuthStateNotifier(AuthBloc bloc) {
    bloc.stream.listen((_) => notifyListeners());
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
