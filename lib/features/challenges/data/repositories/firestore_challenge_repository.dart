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
  Stream<List<ChallengeEntity>> watchActive({String? coachId}) {
    // Isto era um `whereIn: [coachId, null]`, que o SDK rejeita na hora
    // ("'in' filters cannot contain 'null'") e derrubava a aba Retos
    // inteira. Dava para pedir ao servidor "coachId == X OU coachId nulo",
    // mas o Firestore não considera nulo um campo que simplesmente não
    // existe — e os retos globais são criados à mão no console, onde é
    // fácil esquecer o campo. Ler os ativos e separar aqui é o que
    // funciona nos dois casos; são poucos documentos.
    return _collection
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((s) => s.docs
            .map(_fromSnapshot)
            .where((c) => isVisibleTo(c, coachId: coachId))
            .toList());
  }

  /// Um reto aparece para a aluna se for da comunidade dela ou global.
  /// Sem comunidade (aluna ainda sem treinadora), só os globais.
  static bool isVisibleTo(ChallengeEntity challenge, {required String? coachId}) {
    return challenge.coachId == null || challenge.coachId == coachId;
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

  /// Tolerante a campo faltando: os retos são criados à mão no console e
  /// um único documento incompleto não pode derrubar a aba inteira.
  static ChallengeEntity _fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    final now = DateTime.now();
    return ChallengeEntity(
      id: doc.id,
      coachId: data['coachId'] as String?,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      scope: ChallengeScope.values.asNameMap()[data['scope'] as String? ?? ''] ??
          ChallengeScope.comunidad,
      period:
          ChallengePeriod.values.asNameMap()[data['period'] as String? ?? ''] ??
              ChallengePeriod.semanal,
      metric:
          ChallengeMetric.values.asNameMap()[data['metric'] as String? ?? ''] ??
              ChallengeMetric.diasTreinados,
      targetValue: (data['targetValue'] as num?)?.toDouble() ?? 0,
      startsAt: (data['startsAt'] as Timestamp?)?.toDate() ?? now,
      endsAt: (data['endsAt'] as Timestamp?)?.toDate() ?? now,
      xpReward: (data['xpReward'] as num?)?.toInt() ?? 0,
      rewardId: data['rewardId'] as String?,
      participantCount: (data['participantCount'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? now,
    );
  }
}
