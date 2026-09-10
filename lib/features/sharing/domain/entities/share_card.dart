import 'package:flutter/material.dart';

/// Tipos de card compartilhável. O nome é o valor persistido em
/// `share_cards.type`, usado no painel da treinadora.
enum ShareCardKind { record, racha, nivel, entrenamiento, ranking }

/// Tudo que o card precisa desenhar. Montado nas telas de origem (resumo
/// da sessão, perfil, ranking) para que o widget não conheça providers.
@immutable
class ShareCardData {
  const ShareCardData({
    required this.kind,
    required this.eyebrow,
    required this.value,
    required this.caption,
    required this.athleteName,
    required this.coachName,
    this.coachHandle,
    this.inviteCode,
    this.referralUsername,
    this.brandColor,
  });

  final ShareCardKind kind;

  /// Rótulo pequeno no topo, ex.: "RÉCORD PERSONAL".
  final String eyebrow;

  /// O número grande: "110 kg × 5", "41 días", "Nivel 20".
  final String value;

  /// Linha de apoio abaixo do número.
  final String caption;

  final String athleteName;

  /// Marca da treinadora (nome do método) — o card é dela, não do app.
  final String coachName;
  final String? coachHandle;

  /// Código com que alguém entra na comunidade dela.
  final String? inviteCode;

  /// Quem convidou (o próprio aluno), para o programa de indicação.
  final String? referralUsername;

  /// Cor da marca; `null` usa o acento padrão do app.
  final Color? brandColor;

  IconData get icon => switch (kind) {
        ShareCardKind.record => Icons.emoji_events,
        ShareCardKind.racha => Icons.local_fire_department,
        ShareCardKind.nivel => Icons.military_tech,
        ShareCardKind.entrenamiento => Icons.fitness_center,
        ShareCardKind.ranking => Icons.leaderboard,
      };

  /// Texto que acompanha a imagem no compartilhamento.
  String get shareText {
    final base = switch (kind) {
      ShareCardKind.record => '¡Nuevo récord personal! $value 💪',
      ShareCardKind.racha => '$value entrenando sin parar 🔥',
      ShareCardKind.nivel => '¡Subí de nivel! $value',
      ShareCardKind.entrenamiento => 'Entrenamiento completado ✅ $value',
      ShareCardKind.ranking => '$value en mi comunidad 🏆',
    };
    final invite = inviteCode == null
        ? ''
        : '\n\nEntreno con $coachName. Únete con el código $inviteCode'
            '${referralUsername == null ? '' : ' y di que te invitó @$referralUsername'}.';
    return '$base$invite';
  }

  String get fileName =>
      'gymrank_${kind.name}_${DateTime.now().millisecondsSinceEpoch}.png';
}
