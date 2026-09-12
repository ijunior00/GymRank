import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymrank/features/rewards/domain/entities/reward_entity.dart';
import 'package:gymrank/features/rewards/domain/repositories/reward_repository.dart';

class FirestoreRewardRepository implements RewardRepository {
  FirestoreRewardRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<List<RewardGrantEntity>> watchMyGrants(String userId) {
    return _firestore
        .collectionGroup('grants')
        .where('userId', isEqualTo: userId)
        .orderBy('grantedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((doc) {
              final data = doc.data();
              return RewardGrantEntity(
                id: doc.id,
                rewardId: data['rewardId'] as String,
                userId: data['userId'] as String,
                sourceType: data['sourceType'] as String,
                sourceId: data['sourceId'] as String,
                status: RewardStatus.values.byName(data['status'] as String),
                grantedAt: (data['grantedAt'] as Timestamp).toDate(),
                redeemedAt: (data['redeemedAt'] as Timestamp?)?.toDate(),
              );
            }).toList());
  }

  @override
  Stream<RewardEntity?> watchReward(String rewardId) {
    return _firestore.collection('rewards').doc(rewardId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return null;
      return RewardEntity(
        id: doc.id,
        coachId: data['coachId'] as String,
        name: data['name'] as String,
        imageUrl: data['imageUrl'] as String?,
        type: RewardType.values.byName(data['type'] as String),
        stock: data['stock'] as int? ?? 0,
      );
    });
  }
}
