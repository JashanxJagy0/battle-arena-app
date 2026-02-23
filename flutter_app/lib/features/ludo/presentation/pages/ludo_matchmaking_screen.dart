import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../bloc/ludo_bloc.dart';

class LudoMatchmakingScreen extends StatefulWidget {
  final String matchId;
  final String matchCode;

  const LudoMatchmakingScreen({
    required this.matchId,
    required this.matchCode,
    super.key,
  });

  @override
  State<LudoMatchmakingScreen> createState() =>
      _LudoMatchmakingScreenState();
}

class _LudoMatchmakingScreenState extends State<LudoMatchmakingScreen>
    with TickerProviderStateMixin {
  late AnimationController _spinController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  int _countdown = 60;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_countdown <= 1) {
        t.cancel();
        setState(() => _countdown = 0);
      } else {
        setState(() => _countdown--);
      }
    });
  }

  @override
  void dispose() {
    _spinController.dispose();
    _pulseController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: widget.matchCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Match code copied!'),
        duration: Duration(seconds: 1),
        backgroundColor: AppColors.secondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LudoBloc, LudoState>(
      listener: (context, state) {
        if (state is LudoInProgress) {
          context.go('/ludo/match/${widget.matchId}');
        } else if (state is LudoError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final match = state is LudoWaitingForPlayers
            ? state.match
            : state is LudoMatchmaking
                ? state.match
                : null;

        final players = match?.players ?? [];
        final gameMode = match?.gameMode ?? '1v1';
        final maxPlayers = gameMode.toLowerCase() == '1v1' ? 2 : 4;
        final allFilled = players.length >= maxPlayers;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            title: const Text(
              'Finding Match...',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  context
                      .read<LudoBloc>()
                      .add(const DisconnectFromMatch());
                  context.go('/home/ludo');
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Animated searching indicator
                _SpinningArcIndicator(controller: _spinController),
                const SizedBox(height: 32),
                // Countdown
                Text(
                  '${_countdown}s',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 28),
                // Match code
                GestureDetector(
                  onTap: _copyCode,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.matchCode,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 6,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.copy,
                          color: AppColors.textMuted,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap to copy match code',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 36),
                // Player slots
                Text(
                  '${players.length}/$maxPlayers Players',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(maxPlayers, (i) {
                    final filled = i < players.length;
                    final player = filled ? players[i] : null;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _PlayerSlot(
                        isFilled: filled,
                        username: player?.username,
                        avatarUrl: player?.avatar,
                        pulseAnimation: _pulseAnimation,
                      ),
                    );
                  }),
                ),
                const Spacer(),
                if (allFilled)
                  GradientButton(
                    text: 'READY',
                    gradient: AppColors.secondaryGradient,
                    icon: Icons.check_circle_outline,
                    onPressed: () {
                      context
                          .read<LudoBloc>()
                          .add(const PlayerReady());
                    },
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Spinning Arc Indicator ────────────────────────────────────────────────────

class _SpinningArcIndicator extends StatelessWidget {
  final AnimationController controller;

  const _SpinningArcIndicator({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return SizedBox(
          width: 120,
          height: 120,
          child: CustomPaint(
            painter: _ArcPainter(progress: controller.value),
          ),
        );
      },
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;

  const _ArcPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Background circle
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );

    // Spinning arc
    final arcPaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.primary, AppColors.secondary],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      (2 * math.pi * progress) - math.pi / 2,
      math.pi * 1.2,
      false,
      arcPaint,
    );

    // Center icon
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '🎲',
        style: TextStyle(fontSize: 36),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2,
          center.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress;
}

// ── Player Slot ───────────────────────────────────────────────────────────────

class _PlayerSlot extends StatelessWidget {
  final bool isFilled;
  final String? username;
  final String? avatarUrl;
  final Animation<double> pulseAnimation;

  const _PlayerSlot({
    required this.isFilled,
    required this.pulseAnimation,
    this.username,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        isFilled
            ? _FilledAvatar(username: username, avatarUrl: avatarUrl)
            : _PulsingPlaceholder(animation: pulseAnimation),
        const SizedBox(height: 6),
        Text(
          isFilled ? (username ?? 'Player') : 'Waiting...',
          style: TextStyle(
            color: isFilled
                ? AppColors.textPrimary
                : AppColors.textMuted,
            fontSize: 11,
            fontWeight:
                isFilled ? FontWeight.w600 : FontWeight.w400,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _FilledAvatar extends StatelessWidget {
  final String? username;
  final String? avatarUrl;

  const _FilledAvatar({this.username, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.secondary, width: 2),
        boxShadow: [
          BoxShadow(color: AppColors.secondaryGlow, blurRadius: 10),
        ],
      ),
      child: ClipOval(
        child: avatarUrl != null && avatarUrl!.isNotEmpty
            ? Image.network(
                avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder,
              )
            : _placeholder,
      ),
    );
  }

  Widget get _placeholder => Container(
        color: AppColors.surface,
        child: const Icon(Icons.person,
            color: AppColors.textSecondary, size: 30),
      );
}

class _PulsingPlaceholder extends StatelessWidget {
  final Animation<double> animation;

  const _PulsingPlaceholder({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Opacity(
          opacity: animation.value,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.border, width: 2),
              color: AppColors.cardBackground,
            ),
            child: const Icon(Icons.person_add_outlined,
                color: AppColors.textMuted, size: 28),
          ),
        );
      },
    );
  }
}
