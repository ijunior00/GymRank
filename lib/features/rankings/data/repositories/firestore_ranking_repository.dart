import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymrank/features/rankings/domain/entities/ranking_entry_entity.dart';
import 'package:gymrank/features/rankings/domain/repositories/ranking_repository.dart';

class FirestoreRankingRepository implements RankingRepository {
  FirestoreRankingRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<List<RankingEntryEntity>> watch({
    required RankingScope scope,
    required RankingCriteria criteria,
    String? scopeId,
    int limit = 100,
  }) {
    final documentId = '${scope.name}_${criteria.name}_${scopeId ?? 'global'}';
    return _firestore
        .collection('rankings')
        .doc(documentId)
        .collection('entries')
        .orderBy('position')
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((doc) {
              final data = doc.data();
              return RankingEntryEntity(
                userId: data['userId'] as String,
                userName: data['userName'] as String,
                userPhotoUrl: data['userPhotoUrl'] as String?,
                position: data['position'] as int,
                value: (data['value'] as num).toDouble(),
                scope: scope,
                criteria: criteria,
                calculatedAt: (data['calculatedAt'] as Timestamp).toDate(),
              );
            }).toList());
  }
}
