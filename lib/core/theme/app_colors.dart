import 'package:flutter/material.dart';

/// Paleta base do GymRank. Tema escuro por padrão, com acentos vibrantes
/// para gamificação (XP, níveis, conquistas).
abstract final class AppColors {
  static const Color background = Color(0xFF0B0D12);
  static const Color surface = Color(0xFF15181F);
  static const Color surfaceElevated = Color(0xFF1E222B);

  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryVariant = Color(0xFF4834D4);
  static const Color secondary = Color(0xFF00E5A0);

  static const Color gold = Color(0xFFFFC542);
  static const Color silver = Color(0xFFB8C0CC);
  static const Color bronze = Color(0xFFCD7F32);

  static const Color danger = Color(0xFFFF5C5C);
  static const Color warning = Color(0xFFFFA94D);
  static const Color success = Color(0xFF00E5A0);

  static const Color textPrimary = Color(0xFFF5F6FA);
  static const Color textSecondary = Color(0xFFA0A4B8);
  static const Color divider = Color(0xFF262A35);

  static const List<Color> xpGradient = [primary, Color(0xFF00D2FF)];
  static const List<Color> streakGradient = [Color(0xFFFF6B6B), gold];
}
