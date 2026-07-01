import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymrank/features/gamification/domain/entities/achievement_entity.dart';
import 'package:gymrank/features/gamification/domain/repositories/achievement_repository.dart';

class FirestoreAchievementRepository implements AchievementRepository {
  FirestoreAchievementRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<List<UserAchievementEntity>> watchUnlocked(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('achievements')
        .snapshots()
        .map((s) => s.docs.map((doc) {
              final data = doc.data();
              return UserAchievementEntity(
                code: AchievementCode.values.byName(doc.id),
                unlockedAt: (data['unlockedAt'] as Timestamp).toDate(),
              );
            }).toList());
  }
}
