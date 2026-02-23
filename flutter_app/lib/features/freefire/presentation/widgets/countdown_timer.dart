import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Animated flip countdown timer showing days:hours:minutes:seconds.
class CountdownTimer extends StatefulWidget {
  final DateTime targetTime;

  /// Called when the countdown reaches zero.
  final VoidCallback? onFinished;

  const CountdownTimer({
    super.key,
    required this.targetTime,
    this.onFinished,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Timer _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _remaining = widget.targetTime.difference(DateTime.now());
    if (_remaining.isNegative) _remaining = Duration.zero;
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
  }

  void _tick(Timer _) {
    final remaining = widget.targetTime.difference(DateTime.now());
    if (!mounted) return;
    if (remaining.isNegative) {
      setState(() => _remaining = Duration.zero);
      _timer.cancel();
      widget.onFinished?.call();
    } else {
      setState(() => _remaining = remaining);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = _remaining.inDays;
    final h = _remaining.inHours.remainder(24);
    final m = _remaining.inMinutes.remainder(60);
    final s = _remaining.inSeconds.remainder(60);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (d > 0) ...[
          _FlipUnit(value: d, label: 'D'),
          _Separator(),
        ],
        _FlipUnit(value: h, label: 'H'),
        _Separator(),
        _FlipUnit(value: m, label: 'M'),
        _Separator(),
        _FlipUnit(value: s, label: 'S'),
      ],
    );
  }
}

class _FlipUnit extends StatefulWidget {
  final int value;
  final String label;

  const _FlipUnit({required this.value, required this.label});

  @override
  State<_FlipUnit> createState() => _FlipUnitState();
}

class _FlipUnitState extends State<_FlipUnit>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  int _prev = 0;

  @override
  void initState() {
    super.initState();
    _prev = widget.value;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(_FlipUnit old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _prev = old.value;
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _anim,
          builder: (context, child) {
            return Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                widget.value.toString().padLeft(2, '0'),
                style: TextStyle(
                  color: AppColors.primary,
                  fontFamily: 'Orbitron',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        Text(
          widget.label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _Separator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(4, 0, 4, 18),
      child: Text(
        ':',
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
