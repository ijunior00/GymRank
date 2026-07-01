import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymrank/core/constants/app_constants.dart';
import 'package:gymrank/core/error/failure.dart';
import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/features/challenges/domain/entities/challenge_entity.dart';
import 'package:gymrank/features/challenges/domain/repositories/challenge_repository.dart';

class FirestoreChallengeRepository implements ChallengeRepository {
  FirestoreChallengeRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('challenges');

  @override
  Stream<List<ChallengeEntity>> watchActive({String? gymId}) {
    Query<Map<String, dynamic>> query =
        _collection.where('isActive', isEqualTo: true);
    if (gymId != null) {
      query = query.where('gymId', whereIn: [gymId, null]);
    }
    return query.snapshots().map((s) => s.docs.map(_fromSnapshot).toList());
  }

  @override
  Future<Result<void>> join({
    required String challengeId,
    required String userId,
  }) async {
    try {
      await _collection.doc(challengeId).collection('participants').doc(userId).set({
        'userId': userId,
        'challengeId': challengeId,
        'currentValue': 0,
        'completed': false,
      });
      await _collection.doc(challengeId).update({
        'participantCount': FieldValue.increment(1),
      });
      return const Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(Failure.unexpected(e.message ?? e.code));
    }
  }

  @override
  Stream<ChallengeParticipantEntity?> watchParticipation({
    required String challengeId,
    required String userId,
  }) {
    return _collection
        .doc(challengeId)
        .collection('participants')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      final data = doc.data()!;
      return ChallengeParticipantEntity(
        userId: userId,
        challengeId: challengeId,
        currentValue: (data['currentValue'] as num).toDouble(),
        completed: data['completed'] as bool,
        completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      );
    });
  }

  ChallengeEntity _fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ChallengeEntity(
      id: doc.id,
      gymId: data['gymId'] as String?,
      title: data['title'] as String,
      description: data['description'] as String,
      scope: ChallengeScope.values.byName(data['scope'] as String),
      period: ChallengePeriod.values.byName(data['period'] as String),
      metric: ChallengeMetric.values.byName(data['metric'] as String),
      targetValue: (data['targetValue'] as num).toDouble(),
      startsAt: (data['startsAt'] as Timestamp).toDate(),
      endsAt: (data['endsAt'] as Timestamp).toDate(),
      xpReward: data['xpReward'] as int,
      rewardId: data['rewardId'] as String?,
      participantCount: data['participantCount'] as int? ?? 0,
      isActive: data['isActive'] as bool,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
