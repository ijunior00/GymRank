import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymrank/features/championships/domain/entities/championship_entity.dart';
import 'package:gymrank/features/championships/domain/repositories/championship_repository.dart';

class FirestoreChampionshipRepository implements ChampionshipRepository {
  FirestoreChampionshipRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<List<ChampionshipEntity>> watchByGym(String gymId) {
    return _firestore
        .collection('championships')
        .where('gymId', isEqualTo: gymId)
        .orderBy('startsAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((doc) {
              final data = doc.data();
              return ChampionshipEntity(
                id: doc.id,
                gymId: data['gymId'] as String,
                name: data['name'] as String,
                description: data['description'] as String,
                startsAt: (data['startsAt'] as Timestamp).toDate(),
                endsAt: (data['endsAt'] as Timestamp).toDate(),
                criteria:
                    ChampionshipCriteria.values.byName(data['criteria'] as String),
                rewardIds: List<String>.from(data['rewardIds'] as List? ?? []),
                participantCount: data['participantCount'] as int? ?? 0,
                isFinished: data['isFinished'] as bool? ?? false,
                createdAt: (data['createdAt'] as Timestamp).toDate(),
              );
            }).toList());
  }
}
