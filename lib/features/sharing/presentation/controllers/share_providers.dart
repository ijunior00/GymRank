import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/core/di/firebase_providers.dart';
import 'package:gymrank/core/theme/app_colors.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';
import 'package:gymrank/features/coach_panel/presentation/controllers/coach_panel_providers.dart';
import 'package:gymrank/features/sharing/data/repositories/firestore_share_repository.dart';
import 'package:gymrank/features/sharing/domain/entities/share_card.dart';
import 'package:gymrank/features/sharing/domain/repositories/share_repository.dart';

final shareRepositoryProvider = Provider<ShareRepository>((ref) {
  return FirestoreShareRepository(
    ref.watch(firestoreProvider),
    ref.watch(currentUserProvider).valueOrNull,
  );
});

/// Cards compartilhados pela comunidade da treinadora (painel dela).
final communitySharesProvider =
    StreamProvider<List<ShareEventEntity>>((ref) {
  final coachId = ref.watch(currentCoachIdProvider);
  if (coachId == null) return Stream.value(const []);
  return ref.watch(shareRepositoryProvider).watchRecent(coachId);
});

/// Cor da marca da treinadora (`coaches/{id}.brandColorHex`), com o
/// acento padrão do app como reserva.
final brandColorProvider = Provider<Color>((ref) {
  final hex = ref.watch(currentCoachProvider).valueOrNull?.brandColorHex;
  return parseBrandColor(hex) ?? AppColors.primary;
});

/// `#RRGGBB` ou `#AARRGGBB` → [Color]. `null` quando não dá para ler.
Color? parseBrandColor(String? hex) {
  if (hex == null) return null;
  var value = hex.trim().replaceFirst('#', '');
  if (value.length == 6) value = 'FF$value';
  if (value.length != 8) return null;
  final parsed = int.tryParse(value, radix: 16);
  return parsed == null ? null : Color(parsed);
}

/// Monta os dados do card a partir do usuário e da marca atuais, para as
/// telas não repetirem esse preenchimento.
ShareCardData buildShareCard(
  WidgetRef ref, {
  required ShareCardKind kind,
  required String eyebrow,
  required String value,
  required String caption,
}) {
  final user = ref.read(currentUserProvider).valueOrNull;
  final coach = ref.read(currentCoachProvider).valueOrNull;
  return ShareCardData(
    kind: kind,
    eyebrow: eyebrow,
    value: value,
    caption: caption,
    athleteName: user?.name ?? '',
    coachName: coach?.name ?? 'Mi coach',
    coachHandle: coach?.instagramHandle,
    inviteCode: coach?.inviteCode,
    referralUsername: user?.username,
    brandColor: parseBrandColor(coach?.brandColorHex),
  );
}
