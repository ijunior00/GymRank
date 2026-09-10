import 'package:flutter/material.dart';

/// Paleta do GymRank: preto ameixa profundo com acento violeta e tons de
/// roxo que combinam entre si. Monocromático + um acento = visual limpo;
/// o violeta carrega a energia de gamificação.
///
/// Contraste: `primary` sobre `surface` fica em ~4.8:1 e `onPrimary`
/// (quase preto) sobre `primary` em ~5.3:1, então texto de botão passa em
/// AA mesmo em tamanho normal.
abstract final class AppColors {
  // Fundos e superfícies (escala de cinza com leve viés roxo).
  static const Color background = Color(0xFF0B0710);
  static const Color surface = Color(0xFF150F1E);
  static const Color surfaceElevated = Color(0xFF1E1730);
  static const Color divider = Color(0xFF2A2140);

  // Acento único.
  static const Color primary = Color(0xFFA855F7);
  static const Color primaryVariant = Color(0xFF7C3AED);
  static const Color secondary = Color(0xFFD946EF);

  /// Cor de conteúdo sobre o violeta (botões, chips): quase preto.
  static const Color onPrimary = Color(0xFF14081F);

  // Pódio (metálicos: semânticos, fora da paleta roxa).
  static const Color gold = Color(0xFFF5C542);
  static const Color silver = Color(0xFFC7C9CC);
  static const Color bronze = Color(0xFFCD7F32);

  // Semânticas.
  static const Color danger = Color(0xFFFF453A);
  static const Color warning = Color(0xFFFF9F0A);
  static const Color success = Color(0xFF32D74B);

  // Texto.
  static const Color textPrimary = Color(0xFFF5F3F7);
  static const Color textSecondary = Color(0xFFA29AB0);

  // Gradientes de destaque (XP, sequência).
  static const List<Color> xpGradient = [primary, Color(0xFF6366F1)];
  static const List<Color> streakGradient = [secondary, primaryVariant];

  /// Fundo dos cartões-herói (home, código de convite).
  static const List<Color> heroGradient = [Color(0xFF231738), surface];
}
