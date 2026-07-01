import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/core/di/firebase_providers.dart';
import 'package:gymrank/features/rankings/data/repositories/firestore_ranking_repository.dart';
import 'package:gymrank/features/rankings/domain/entities/ranking_entry_entity.dart';
import 'package:gymrank/features/rankings/domain/repositories/ranking_repository.dart';

final rankingRepositoryProvider = Provider<RankingRepository>((ref) {
  return FirestoreRankingRepository(ref.watch(firestoreProvider));
});

class RankingQuery {
  const RankingQuery({
    required this.scope,
    required this.criteria,
    this.scopeId,
  });

  final RankingScope scope;
  final RankingCriteria criteria;
  final String? scopeId;

  @override
  bool operator ==(Object other) =>
      other is RankingQuery &&
      other.scope == scope &&
      other.criteria == criteria &&
      other.scopeId == scopeId;

  @override
  int get hashCode => Object.hash(scope, criteria, scopeId);
}

final rankingEntriesProvider =
    StreamProvider.family<List<RankingEntryEntity>, RankingQuery>((ref, query) {
  return ref.watch(rankingRepositoryProvider).watch(
        scope: query.scope,
        criteria: query.criteria,
        scopeId: query.scopeId,
      );
});
