import 'package:flutter/material.dart';

/// Paleta do GymRank: preto profundo com um único acento amarelo/âmbar
/// (estilo fitness premium, dark). Monocromático + um acento = visual
/// limpo e profissional; o amarelo carrega a energia de gamificação.
abstract final class AppColors {
  // Fundos e superfícies (escala de cinza, sem tons quentes).
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF121212);
  static const Color surfaceElevated = Color(0xFF1C1C1E);
  static const Color divider = Color(0xFF262626);

  // Acento único.
  static const Color primary = Color(0xFFFFD60A);
  static const Color primaryVariant = Color(0xFFE6B800);
  static const Color secondary = Color(0xFFFFD60A);

  /// Cor de conteúdo sobre o amarelo (botões, chips): preto para contraste.
  static const Color onPrimary = Color(0xFF0A0A0A);

  // Pódio.
  static const Color gold = Color(0xFFFFD60A);
  static const Color silver = Color(0xFFC7C9CC);
  static const Color bronze = Color(0xFFCD7F32);

  // Semânticas.
  static const Color danger = Color(0xFFFF453A);
  static const Color warning = Color(0xFFFF9F0A);
  static const Color success = Color(0xFF32D74B);

  // Texto.
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9A9A9A);

  // Gradientes de destaque (XP, sequência).
  static const List<Color> xpGradient = [primary, Color(0xFFFF8A00)];
  static const List<Color> streakGradient = [Color(0xFFFF6B35), primary];
}
