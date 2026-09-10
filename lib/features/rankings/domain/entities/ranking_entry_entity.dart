import 'package:freezed_annotation/freezed_annotation.dart';

part 'ranking_entry_entity.freezed.dart';

/// `comunidad` = alunos da mesma treinadora (`scopeId` = coachId).
enum RankingScope { comunidad, amigos, ciudad, nacional }

enum RankingCriteria { consistencia, evolucao, xp, gymScore }

/// Item materializado de `rankings/{scope}_{criteria}_{scopeId}/entries/{userId}`.
/// Rankings são recalculados por Cloud Functions e servidos como leitura
/// direta (sem agregação no cliente) para performance em escala.
@freezed
class RankingEntryEntity with _$RankingEntryEntity {
  const factory RankingEntryEntity({
    required String userId,
    required String userName,
    required String? userPhotoUrl,
    required int position,
    required double value,
    required RankingScope scope,
    required RankingCriteria criteria,
    required DateTime calculatedAt,
  }) = _RankingEntryEntity;
}
