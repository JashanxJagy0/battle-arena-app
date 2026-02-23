import 'package:flutter/material.dart';

class GameTimerWidget extends StatefulWidget {
  final int secondsLeft;
  final int totalSeconds;
  final bool isActive;

  const GameTimerWidget({
    required this.secondsLeft,
    this.totalSeconds = 30,
    required this.isActive,
    super.key,
  });

  @override
  State<GameTimerWidget> createState() => _GameTimerWidgetState();
}

class _GameTimerWidgetState extends State<GameTimerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  double _previousProgress = 1.0;

  @override
  void initState() {
    super.initState();
    _previousProgress = _computeProgress();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      value: _previousProgress,
    );
    _progressAnimation = Tween<double>(
      begin: _previousProgress,
      end: _previousProgress,
    ).animate(CurvedAnimation(parent: _progressController, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(GameTimerWidget old) {
    super.didUpdateWidget(old);
    if (old.secondsLeft != widget.secondsLeft) {
      final newProgress = _computeProgress();
      _progressAnimation = Tween<double>(
        begin: _previousProgress,
        end: newProgress,
      ).animate(CurvedAnimation(parent: _progressController, curve: Curves.easeOut));
      _previousProgress = newProgress;
      _progressController.forward(from: 0);
    }
  }

  double _computeProgress() {
    if (widget.totalSeconds <= 0) return 0;
    return (widget.secondsLeft / widget.totalSeconds).clamp(0.0, 1.0);
  }

  Color _timerColor(double progress) {
    if (progress > 0.5) return const Color(0xFF00FF88); // green
    if (progress > 0.25) return const Color(0xFFFFD700); // yellow
    return const Color(0xFFFF3366); // red
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: widget.isActive ? 1.0 : 0.4,
      duration: const Duration(milliseconds: 300),
      child: AnimatedBuilder(
        animation: _progressAnimation,
        builder: (context, _) {
          final progress = _progressAnimation.value;
          final color = _timerColor(progress);
          return SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 5,
                    backgroundColor: Colors.white.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                Text(
                  '${widget.secondsLeft}',
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
