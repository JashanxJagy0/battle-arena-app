import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../bloc/auth_bloc.dart';
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.6, curve: Curves.easeIn)),
    );
    _scaleAnimation = Tween<double>(begin: 0.6, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.6, curve: Curves.elasticOut)),
    );

    _controller.forward().then((_) {
      context.read<AuthBloc>().add(const CheckAuthStatus());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          context.go('/home');
        } else if (state is Unauthenticated) {
          context.go('/onboarding');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: AppColors.backgroundGradient,
            ),
          ),
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: AppColors.primaryGradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryGlow,
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.sports_esports_rounded,
                            color: Colors.white,
                            size: 54,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: AppColors.primaryGradient,
                          ).createShader(bounds),
                          child: Text(
                            AppStrings.appName.toUpperCase(),
                            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                  color: Colors.white,
                                  letterSpacing: 4,
                                ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppStrings.appTagline,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.secondary,
                                letterSpacing: 1.5,
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
