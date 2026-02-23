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
              builder: (context, state) => const _PlaceholderScreen(title: 'Tournaments'),
            ),
            GoRoute(
              path: '/home/wallet',
              builder: (context, state) => const WalletScreen(),
            ),
            GoRoute(
              path: '/home/profile',
              builder: (context, state) => const _PlaceholderScreen(title: 'Profile'),
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
          path: '/tournament/:id',
          builder: (context, state) => _PlaceholderScreen(
            title: 'Tournament ${state.pathParameters['id']}',
          ),
        ),
        GoRoute(
          path: '/tournament/:id/room',
          builder: (context, state) => _PlaceholderScreen(
            title: 'Room Card ${state.pathParameters['id']}',
          ),
        ),
        GoRoute(
          path: '/tournament/:id/results',
          builder: (context, state) => _PlaceholderScreen(
            title: 'Tournament Results ${state.pathParameters['id']}',
          ),
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
          builder: (context, state) => const _PlaceholderScreen(title: 'Wager History'),
        ),
        GoRoute(
          path: '/bonuses',
          builder: (context, state) => const _PlaceholderScreen(title: 'Bonuses'),
        ),
        GoRoute(
          path: '/leaderboard',
          builder: (context, state) => const _PlaceholderScreen(title: 'Leaderboard'),
        ),
        GoRoute(
          path: '/referral',
          builder: (context, state) => const _PlaceholderScreen(title: 'Referral'),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const _PlaceholderScreen(title: 'Notifications'),
        ),
        GoRoute(
          path: '/profile/edit',
          builder: (context, state) => const _PlaceholderScreen(title: 'Edit Profile'),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const _PlaceholderScreen(title: 'Settings'),
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

class _PlaceholderScreen extends StatelessWidget {
  final String title;

  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title)),
    );
  }
}
