import 'package:gymrank/features/rankings/domain/entities/ranking_entry_entity.dart';

abstract interface class RankingRepository {
  /// Lê o ranking materializado `rankings/{scope}_{criteria}_{scopeId}/entries`,
  /// pré-calculado por Cloud Functions. `scopeId` é o `coachId`, cidade ou
  /// `null` para ranking nacional.
  Stream<List<RankingEntryEntity>> watch({
    required RankingScope scope,
    required RankingCriteria criteria,
    String? scopeId,
    int limit,
  });
}
