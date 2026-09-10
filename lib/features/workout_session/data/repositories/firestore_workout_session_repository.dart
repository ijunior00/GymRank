import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymrank/core/error/failure.dart';
import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/features/workout_session/domain/entities/workout_session.dart';
import 'package:gymrank/features/workout_session/domain/repositories/workout_session_repository.dart';

class FirestoreWorkoutSessionRepository implements WorkoutSessionRepository {
  FirestoreWorkoutSessionRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _sessions =>
      _firestore.collection('workout_sessions');

  @override
  Future<Result<WorkoutSessionEntity>> start(WorkoutSessionEntity draft) async {
    try {
      final ref = _sessions.doc();
      final session = draft.copyWithId(ref.id);
      await ref.set({
        ..._toMap(session),
        'createdAt': Timestamp.now(),
      });
      return Result.success(session);
    } on FirebaseException catch (e) {
      return Result.failure(_mapException(e));
    }
  }

  @override
  Future<Result<void>> save(WorkoutSessionEntity session) async {
    try {
      await _sessions.doc(session.id).update({
        'exercises': session.exercises.map((e) => e.toMap()).toList(),
        'totalVolumeKg': session.computedVolume,
        'updatedAt': Timestamp.now(),
      });
      return const Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(_mapException(e));
    }
  }

  @override
  Future<Result<void>> finish(WorkoutSessionEntity session) async {
    try {
      final now = DateTime.now();
      session
        ..status = SessionStatus.completada
        ..finishedAt = now
        ..durationSec = now.difference(session.startedAt).inSeconds
        ..totalVolumeKg = session.computedVolume;
      await _sessions.doc(session.id).update({
        'status': SessionStatus.completada.name,
        'finishedAt': Timestamp.fromDate(now),
        'durationSec': session.durationSec,
        'exercises': session.exercises.map((e) => e.toMap()).toList(),
        'totalVolumeKg': session.totalVolumeKg,
        'updatedAt': Timestamp.now(),
      });
      return const Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(_mapException(e));
    }
  }

  @override
  Future<Result<void>> cancel(String sessionId) async {
    try {
      await _sessions.doc(sessionId).update({
        'status': SessionStatus.cancelada.name,
        'finishedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      return const Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(_mapException(e));
    }
  }

  @override
  Stream<WorkoutSessionEntity?> watchActive(String userId) {
    return _sessions
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: SessionStatus.enCurso.name)
        .orderBy('startedAt', descending: true)
        .limit(1)
        .snapshots()
        .map((s) => s.docs.isEmpty ? null : _fromSnapshot(s.docs.first));
  }

  @override
  Stream<WorkoutSessionEntity?> watch(String sessionId) {
    return _sessions.doc(sessionId).snapshots().map(
          (doc) => doc.exists ? _fromSnapshot(doc) : null,
        );
  }

  @override
  Stream<List<WorkoutSessionEntity>> watchRecent(String userId, {int limit = 20}) {
    return _sessions
        .where('userId', isEqualTo: userId)
        .orderBy('startedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(_fromSnapshot).toList());
  }

  Map<String, dynamic> _toMap(WorkoutSessionEntity s) => {
        'userId': s.userId,
        'coachId': s.coachId,
        'planId': s.planId,
        'planVersion': s.planVersion,
        'dayIndex': s.dayIndex,
        'dayName': s.dayName,
        'status': s.status.name,
        'startedAt': Timestamp.fromDate(s.startedAt),
        'finishedAt': s.finishedAt == null ? null : Timestamp.fromDate(s.finishedAt!),
        'durationSec': s.durationSec,
        'exercises': s.exercises.map((e) => e.toMap()).toList(),
        'totalVolumeKg': s.totalVolumeKg,
        'updatedAt': Timestamp.now(),
      };

  WorkoutSessionEntity _fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return WorkoutSessionEntity(
      id: doc.id,
      userId: d['userId'] as String,
      coachId: d['coachId'] as String?,
      planId: d['planId'] as String? ?? '',
      planVersion: (d['planVersion'] as num?)?.toInt() ?? 1,
      dayIndex: (d['dayIndex'] as num?)?.toInt() ?? 0,
      dayName: d['dayName'] as String? ?? '',
      status: SessionStatus.values.byName(d['status'] as String? ?? 'enCurso'),
      startedAt: (d['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      finishedAt: (d['finishedAt'] as Timestamp?)?.toDate(),
      durationSec: (d['durationSec'] as num?)?.toInt(),
      exercises: [
        if (d['exercises'] is List)
          for (final e in d['exercises'] as List)
            if (e is Map) SessionExercise.fromMap(Map<String, dynamic>.from(e)),
      ],
      totalVolumeKg: (d['totalVolumeKg'] as num?)?.toDouble() ?? 0,
      validated: d['validated'] as bool?,
      validationReason: d['validationReason'] as String?,
      prs: [
        if (d['prs'] is List)
          for (final p in d['prs'] as List)
            if (p is Map) PersonalRecord.fromMap(Map<String, dynamic>.from(p)),
      ],
      countedForStreak: d['countedForStreak'] as bool?,
      xpGranted: (d['xpGranted'] as num?)?.toInt(),
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
