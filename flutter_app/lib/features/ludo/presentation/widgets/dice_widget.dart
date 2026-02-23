import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class DiceWidget extends StatefulWidget {
  final int faceValue;
  final bool isRolling;
  final bool isMyTurn;
  final VoidCallback? onTap;

  const DiceWidget({
    required this.faceValue,
    required this.isRolling,
    required this.isMyTurn,
    this.onTap,
    super.key,
  });

  @override
  State<DiceWidget> createState() => _DiceWidgetState();
}

class _DiceWidgetState extends State<DiceWidget>
    with TickerProviderStateMixin {
  late AnimationController _rollController;
  late AnimationController _bounceController;
  late AnimationController _pulseController;

  late Animation<double> _rotateAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _pulseAnimation;

  int _displayFace = 1;

  @override
  void initState() {
    super.initState();

    _rollController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _rotateAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _rollController, curve: Curves.easeInOut),
    );

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.9), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _bounceController, curve: Curves.easeOut));

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _displayFace = widget.faceValue;
    _updateAnimations(false, widget.isRolling);
  }

  @override
  void didUpdateWidget(DiceWidget old) {
    super.didUpdateWidget(old);
    final wasRolling = old.isRolling;
    final isRolling = widget.isRolling;

    if (isRolling && !wasRolling) {
      _startRolling();
    } else if (!isRolling && wasRolling) {
      _stopRolling();
    }

    _updateAnimations(wasRolling, isRolling);
  }

  void _updateAnimations(bool wasRolling, bool isRolling) {
    if (widget.isMyTurn && !isRolling) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
    }
  }

  void _startRolling() {
    _rollController.repeat();
    _rollTick();
  }

  void _rollTick() {
    if (!mounted || !widget.isRolling) return;
    setState(() {
      _displayFace = math.Random().nextInt(6) + 1;
    });
    Future.delayed(const Duration(milliseconds: 80), _rollTick);
  }

  void _stopRolling() {
    _rollController.stop();
    _rollController.reset();
    setState(() => _displayFace = widget.faceValue);
    _bounceController.forward(from: 0);
  }

  @override
  void dispose() {
    _rollController.dispose();
    _bounceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge(
            [_rotateAnimation, _bounceAnimation, _pulseAnimation]),
        builder: (context, _) {
          final scale = widget.isRolling
              ? 1.0
              : (_bounceController.isAnimating
                  ? _bounceAnimation.value
                  : 1.0);

          final glowOpacity =
              widget.isMyTurn && !widget.isRolling ? _pulseAnimation.value : 0.0;

          return Transform.scale(
            scale: scale,
            child: Transform.rotate(
              angle: widget.isRolling ? _rotateAnimation.value : 0,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 8,
                      offset: const Offset(3, 3),
                    ),
                    BoxShadow(
                      color: AppColors.primary.withOpacity(glowOpacity * 0.8),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(10),
                child: _DiceFace(faceValue: _displayFace),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DiceFace extends StatelessWidget {
  final int faceValue;

  const _DiceFace({required this.faceValue});

  // Dot layout per face value: each Offset is a (row, col) index in a 3×3 grid.
  static const Map<int, List<Offset>> _dotPositions = {
    1: [Offset(1, 1)],
    2: [Offset(0, 0), Offset(2, 2)],
    3: [Offset(0, 0), Offset(1, 1), Offset(2, 2)],
    4: [Offset(0, 0), Offset(0, 2), Offset(2, 0), Offset(2, 2)],
    5: [
      Offset(0, 0),
      Offset(0, 2),
      Offset(1, 1),
      Offset(2, 0),
      Offset(2, 2)
    ],
    6: [
      Offset(0, 0),
      Offset(0, 2),
      Offset(1, 0),
      Offset(1, 2),
      Offset(2, 0),
      Offset(2, 2)
    ],
  };

  @override
  Widget build(BuildContext context) {
    final dots = _dotPositions[faceValue] ?? [];
    const dotColor = Color(0xFF1A1A2E);

    return CustomPaint(
      painter: _DotsPainter(dots: dots, dotColor: dotColor),
    );
  }
}

class _DotsPainter extends CustomPainter {
  final List<Offset> dots;
  final Color dotColor;

  const _DotsPainter({required this.dots, required this.dotColor});

  @override
  void paint(Canvas canvas, Size size) {
    final dotRadius = size.width * 0.12;
    final paint = Paint()..color = dotColor;
    final cellW = size.width / 3;
    final cellH = size.height / 3;

    for (final d in dots) {
      final cx = (d.dy + 0.5) * cellW;
      final cy = (d.dx + 0.5) * cellH;
      canvas.drawCircle(Offset(cx, cy), dotRadius, paint);
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) =>
      old.dots != dots || old.dotColor != dotColor;
}
