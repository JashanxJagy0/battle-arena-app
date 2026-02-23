import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/auth/presentation/bloc/auth_bloc.dart';
import 'routes.dart';
import 'theme.dart';

class BattleArenaApp extends StatelessWidget {
  final AuthBloc authBloc;

  const BattleArenaApp({super.key, required this.authBloc});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: authBloc),
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
