import 'package:flutter/material.dart';

class MoveAnimationOverlay extends StatefulWidget {
  final Color pieceColor;
  final List<Offset> pathPositions;
  final VoidCallback onComplete;

  const MoveAnimationOverlay({
    required this.pieceColor,
    required this.pathPositions,
    required this.onComplete,
    super.key,
  });

  @override
  State<MoveAnimationOverlay> createState() => _MoveAnimationOverlayState();
}

class _MoveAnimationOverlayState extends State<MoveAnimationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _positionAnimation;

  @override
  void initState() {
    super.initState();

    final steps = widget.pathPositions.length;
    if (steps < 2) {
      // Nothing to animate; notify immediately after the first frame.
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onComplete());
      _controller = AnimationController(vsync: this, duration: Duration.zero);
      _positionAnimation = AlwaysStoppedAnimation(
        steps == 0 ? Offset.zero : widget.pathPositions.first,
      );
      return;
    }

    final stepDuration = const Duration(milliseconds: 160);
    _controller = AnimationController(
      vsync: this,
      duration: stepDuration * (steps - 1),
    );

    // Build a TweenSequence that moves through each position.
    final tweenItems = <TweenSequenceItem<Offset>>[];
    for (int i = 0; i < steps - 1; i++) {
      tweenItems.add(
        TweenSequenceItem<Offset>(
          tween: Tween<Offset>(
            begin: widget.pathPositions[i],
            end: widget.pathPositions[i + 1],
          ).chain(CurveTween(curve: Curves.easeInOut)),
          weight: 1,
        ),
      );
    }

    _positionAnimation = TweenSequence<Offset>(tweenItems).animate(_controller);

    _controller.forward().whenComplete(() {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pathPositions.isEmpty) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _positionAnimation,
      builder: (context, _) {
        final pos = _positionAnimation.value;
        return CustomPaint(
          painter: _PiecePainter(position: pos, color: widget.pieceColor),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _PiecePainter extends CustomPainter {
  final Offset position;
  final Color color;

  const _PiecePainter({required this.position, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const radius = 14.0;

    // Glow.
    canvas.drawCircle(
      position,
      radius + 6,
      Paint()
        ..color = color.withOpacity(0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Shadow.
    canvas.drawCircle(
      Offset(position.dx + 2, position.dy + 3),
      radius,
      Paint()..color = Colors.black.withOpacity(0.4),
    );

    // Fill.
    canvas.drawCircle(position, radius, Paint()..color = color);

    // Highlight.
    canvas.drawCircle(
      Offset(position.dx - radius * 0.3, position.dy - radius * 0.3),
      radius * 0.35,
      Paint()..color = Colors.white.withOpacity(0.5),
    );

    // Border.
    canvas.drawCircle(
      position,
      radius,
      Paint()
        ..color = Colors.white.withOpacity(0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_PiecePainter old) =>
      old.position != position || old.color != color;
}
