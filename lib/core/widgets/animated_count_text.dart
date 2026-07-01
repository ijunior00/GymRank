import 'package:flutter/material.dart';

/// Texto numérico que "conta" de 0 até [value] ao aparecer — dá a
/// sensação de progresso vivo em stats (XP, Gym Score, sequência).
class AnimatedCountText extends StatelessWidget {
  const AnimatedCountText(
    this.value, {
    this.style,
    this.suffix = '',
    this.duration = const Duration(milliseconds: 900),
    super.key,
  });

  final num value;
  final TextStyle? style;
  final String suffix;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text('${v.round()}$suffix', style: style),
    );
  }
}
