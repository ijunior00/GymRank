import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymrank/features/championships/domain/entities/championship_entity.dart';
import 'package:gymrank/features/championships/domain/repositories/championship_repository.dart';

class FirestoreChampionshipRepository implements ChampionshipRepository {
  FirestoreChampionshipRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<List<ChampionshipEntity>> watchByCoach(String coachId) {
    return _firestore
        .collection('championships')
        .where('coachId', isEqualTo: coachId)
        .orderBy('startsAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((doc) {
              // Torneios ainda são criados à mão no console do Firebase:
              // um campo esquecido não pode derrubar a lista inteira.
              final data = doc.data();
              final now = DateTime.now();
              return ChampionshipEntity(
                id: doc.id,
                coachId: data['coachId'] as String? ?? '',
                name: data['name'] as String? ?? '',
                description: data['description'] as String? ?? '',
                startsAt: (data['startsAt'] as Timestamp?)?.toDate() ?? now,
                endsAt: (data['endsAt'] as Timestamp?)?.toDate() ?? now,
                criteria: ChampionshipCriteria.values
                        .asNameMap()[data['criteria'] as String? ?? ''] ??
                    ChampionshipCriteria.maisXp,
                rewardIds: List<String>.from(data['rewardIds'] as List? ?? []),
                participantCount: data['participantCount'] as int? ?? 0,
                isFinished: data['isFinished'] as bool? ?? false,
                createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? now,
              );
            }).toList());
  }
}
