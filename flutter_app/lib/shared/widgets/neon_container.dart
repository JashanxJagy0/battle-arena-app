import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class NeonContainer extends StatelessWidget {
  final Widget child;
  final Color glowColor;
  final double glowRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? backgroundColor;
  final double borderWidth;

  const NeonContainer({
    super.key,
    required this.child,
    this.glowColor = AppColors.primary,
    this.glowRadius = 12,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.backgroundColor,
    this.borderWidth = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.cardBackground,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: glowColor.withOpacity(0.5),
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.15),
            blurRadius: glowRadius,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }
}
