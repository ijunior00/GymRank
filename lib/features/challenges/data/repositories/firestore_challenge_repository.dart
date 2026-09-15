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
  Stream<List<ChallengeEntity>> watchByCoach(String coachId) {
    return _collection
        .where('coachId', isEqualTo: coachId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(_fromSnapshot).toList());
  }

  @override
  Stream<ChallengeEntity?> watchChallenge(String challengeId) {
    return _collection.doc(challengeId).snapshots().map(
          (doc) => doc.exists ? _fromSnapshot(doc) : null,
        );
  }

  @override
  Future<Result<ChallengeEntity>> save(ChallengeEntity challenge) async {
    try {
      if (challenge.id.isEmpty) {
        final ref = _collection.doc();
        final now = DateTime.now();
        final fresh = challenge.copyWith(
          id: ref.id,
          participantCount: 0,
          createdAt: now,
        );
        await ref.set({
          ..._editableFields(fresh),
          'coachId': fresh.coachId,
          'participantCount': 0,
          'createdAt': Timestamp.fromDate(now),
        });
        return Result.success(fresh);
      }
      await _collection.doc(challenge.id).update(_editableFields(challenge));
      return Result.success(challenge);
    } on FirebaseException catch (e) {
      return Result.failure(_mapException(e));
    }
  }

  @override
  Future<Result<void>> setActive({
    required String challengeId,
    required bool active,
  }) async {
    try {
      await _collection.doc(challengeId).update({'isActive': active});
      return const Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(_mapException(e));
    }
  }

  /// Os campos que a treinadora edita. `coachId`, `participantCount` e
  /// `createdAt` ficam de fora de propósito: a regra recusa mudá-los.
  Map<String, dynamic> _editableFields(ChallengeEntity c) => {
        'title': c.title.trim(),
        'description': c.description.trim(),
        'scope': c.scope.name,
        'period': c.period.name,
        'metric': c.metric.name,
        'targetValue': c.targetValue,
        'startsAt': Timestamp.fromDate(c.startsAt),
        'endsAt': Timestamp.fromDate(c.endsAt),
        'xpReward': c.xpReward,
        'rewardId': c.rewardId,
        'isActive': c.isActive,
      };

  @override
  Future<Result<void>> join({
    required String challengeId,
    required String userId,
  }) async {
    try {
      // Só a inscrição. O `participantCount` do reto é somado pela Cloud
      // Function `onParticipantCreated`: a regra não deixa a aluna editar
      // o reto (e antes este passo falhava em silêncio por isso).
      await _collection.doc(challengeId).collection('participants').doc(userId).set({
        'userId': userId,
        'challengeId': challengeId,
        'currentValue': 0,
        'completed': false,
      });
      return const Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(_mapException(e));
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
      return _participantFrom(userId, challengeId, doc.data()!);
    });
  }

  @override
  Stream<List<ChallengeParticipantEntity>> watchParticipants(String challengeId) {
    return _collection
        .doc(challengeId)
        .collection('participants')
        .orderBy('currentValue', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((doc) => _participantFrom(doc.id, challengeId, doc.data()))
            .toList());
  }

  static ChallengeParticipantEntity _participantFrom(
    String userId,
    String challengeId,
    Map<String, dynamic> data,
  ) {
    return ChallengeParticipantEntity(
      userId: userId,
      challengeId: challengeId,
      currentValue: (data['currentValue'] as num?)?.toDouble() ?? 0,
      completed: data['completed'] as bool? ?? false,
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
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

  Failure _mapException(FirebaseException e) {
    return switch (e.code) {
      'permission-denied' => const Failure.permissionDenied(),
      'not-found' => const Failure.notFound(),
      'unavailable' => const Failure.network(),
      _ => Failure.unexpected(e.message ?? e.code),
    };
  }
}
