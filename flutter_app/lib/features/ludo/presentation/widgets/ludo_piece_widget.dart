import 'package:flutter/material.dart';

class LudoPieceWidget extends StatefulWidget {
  final Color color;
  final bool isSelectable;
  final bool isAnimating;
  final VoidCallback? onTap;

  const LudoPieceWidget({
    required this.color,
    required this.isSelectable,
    required this.isAnimating,
    this.onTap,
    super.key,
  });

  @override
  State<LudoPieceWidget> createState() => _LudoPieceWidgetState();
}

class _LudoPieceWidgetState extends State<LudoPieceWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scaleController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut));

    _syncAnimations();
  }

  @override
  void didUpdateWidget(LudoPieceWidget old) {
    super.didUpdateWidget(old);
    if (old.isSelectable != widget.isSelectable ||
        old.isAnimating != widget.isAnimating) {
      _syncAnimations();
    }
  }

  void _syncAnimations() {
    if (widget.isSelectable) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }

    if (widget.isAnimating) {
      _scaleController.repeat();
    } else {
      _scaleController.stop();
      _scaleController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isSelectable ? widget.onTap : null,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseAnimation, _scaleAnimation]),
        builder: (context, _) {
          final scale = widget.isAnimating
              ? _scaleAnimation.value
              : (widget.isSelectable ? _pulseAnimation.value : 1.0);

          return Transform.scale(
            scale: scale,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = constraints.maxWidth * 0.7;
                return Center(
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: const Alignment(-0.35, -0.35),
                        radius: 0.85,
                        colors: [
                          Color.alphaBlend(Colors.white.withOpacity(0.45), widget.color),
                          widget.color,
                          Color.alphaBlend(Colors.black.withOpacity(0.4), widget.color),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.45),
                          blurRadius: 6,
                          offset: const Offset(2, 3),
                        ),
                        if (widget.isSelectable)
                          BoxShadow(
                            color: widget.color.withOpacity(0.7),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                      ],
                      border: Border.all(
                        color: Colors.white.withOpacity(0.65),
                        width: 1.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
