import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Backgrounds
  static const Color background = Color(0xFF0A0E21);
  static const Color surface = Color(0xFF141729);
  static const Color cardBackground = Color(0xFF1A1F3D);

  // Neon Accents
  static const Color primary = Color(0xFF00D4FF);   // neon blue
  static const Color secondary = Color(0xFF00FF88); // neon green
  static const Color accent = Color(0xFF9D4EDD);    // neon purple
  static const Color error = Color(0xFFFF3366);     // neon red

  // Text
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0B7D4);
  static const Color textMuted = Color(0xFF6B7280);

  // Borders / Dividers
  static const Color divider = Color(0xFF2D3462);
  static const Color border = Color(0xFF2D3462);

  // Gradients
  static const List<Color> primaryGradient = [Color(0xFF00D4FF), Color(0xFF0094FF)];
  static const List<Color> secondaryGradient = [Color(0xFF00FF88), Color(0xFF00C853)];
  static const List<Color> accentGradient = [Color(0xFF9D4EDD), Color(0xFF7B2FBE)];
  static const List<Color> cardGradient = [Color(0xFF1A1F3D), Color(0xFF141729)];
  static const List<Color> backgroundGradient = [Color(0xFF0A0E21), Color(0xFF141729)];

  // Glow colors (with opacity for shadow)
  static Color get primaryGlow => primary.withOpacity(0.4);
  static Color get secondaryGlow => secondary.withOpacity(0.4);
  static Color get accentGlow => accent.withOpacity(0.4);
  static Color get errorGlow => error.withOpacity(0.4);
}
