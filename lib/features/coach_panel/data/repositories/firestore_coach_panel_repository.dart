import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymrank/core/constants/app_constants.dart';
import 'package:gymrank/core/error/failure.dart';
import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/features/coach_panel/data/dtos/client_dto.dart';
import 'package:gymrank/features/coach_panel/data/dtos/coach_dto.dart';
import 'package:gymrank/features/coach_panel/domain/entities/client_entity.dart';
import 'package:gymrank/features/coach_panel/domain/entities/coach_entity.dart';
import 'package:gymrank/features/coach_panel/domain/repositories/coach_panel_repository.dart';
import 'package:gymrank/features/profile/data/dtos/user_dto.dart';
import 'package:gymrank/features/profile/domain/entities/user_entity.dart';

class FirestoreCoachPanelRepository implements CoachPanelRepository {
  FirestoreCoachPanelRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _coaches =>
      _firestore.collection('coaches');

  CollectionReference<Map<String, dynamic>> _clients(String coachId) =>
      _coaches.doc(coachId).collection('clients');

  @override
  Stream<CoachEntity?> watchCoach(String coachId) {
    return _coaches.doc(coachId).snapshots().map(
          (doc) => doc.exists ? CoachDto.fromSnapshot(doc) : null,
        );
  }

  @override
  Future<Result<CoachEntity>> createCoach(CoachEntity coach) async {
    try {
      // Id vazio = deixar o Firestore gerar.
      final saved =
          coach.id.isEmpty ? coach.copyWith(id: _coaches.doc().id) : coach;
      final batch = _firestore.batch();
      batch.set(_coaches.doc(saved.id), CoachDto.toMap(saved));
      batch.update(
        _firestore.collection('users').doc(saved.ownerUserId),
        {'coachId': saved.id},
      );
      await batch.commit();
      return Result.success(saved);
    } on FirebaseException catch (e) {
      return Result.failure(_mapException(e));
    }
  }

  @override
  Future<Result<CoachEntity>> findByInviteCode(String inviteCode) async {
    try {
      final code = _normalizeCode(inviteCode);
      if (code.isEmpty) {
        return const Result.failure(
          Failure.validation('Escribe el código de tu coach.'),
        );
      }
      final query =
          await _coaches.where('inviteCode', isEqualTo: code).limit(1).get();
      if (query.docs.isEmpty) {
        return const Result.failure(
          Failure.validation('No encontramos ningún coach con ese código.'),
        );
      }
      return Result.success(CoachDto.fromSnapshot(query.docs.first));
    } on FirebaseException catch (e) {
      return Result.failure(_mapException(e));
    }
  }

  @override
  Future<Result<CoachEntity>> joinCoach({
    required String userId,
    required String inviteCode,
  }) async {
    final found = await findByInviteCode(inviteCode);
    final coach = found.dataOrNull;
    if (coach == null) return found;

    try {
      final now = DateTime.now();
      final client = ClientEntity(
        userId: userId,
        coachId: coach.id,
        status: ClientStatus.activo,
        planName: null,
        startedAt: now,
        nextPaymentAt: null,
        tags: const [],
        lastWorkoutAt: null,
        createdAt: now,
      );
      final batch = _firestore.batch();
      batch.update(
        _firestore.collection('users').doc(userId),
        {'coachId': coach.id},
      );
      batch.set(_clients(coach.id).doc(userId), ClientDto.toMap(client));
      await batch.commit();
      return Result.success(coach);
    } on FirebaseException catch (e) {
      return Result.failure(_mapException(e));
    }
  }

  @override
  Stream<CoachDashboardStats?> watchDashboardStats(String coachId) {
    return _coaches
        .doc(coachId)
        .collection('stats')
        .doc('current')
        .snapshots()
        .map((doc) {
      final data = doc.data();
      if (data == null) return null;
      return CoachDto.statsFromMap(data);
    });
  }

  @override
  Stream<List<UserEntity>> watchStudents(String coachId, {int limit = 200}) {
    return _firestore
        .collection('users')
        .where('coachId', isEqualTo: coachId)
        .where('role', isEqualTo: UserRole.alumno.name)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(UserDto.fromSnapshot).toList());
  }

  @override
  Stream<List<ClientEntity>> watchClients(String coachId) {
    return _clients(coachId).snapshots().map(
          (s) => s.docs
              .map((doc) => ClientDto.fromSnapshot(doc, coachId: coachId))
              .toList(),
        );
  }

  @override
  Stream<ClientEntity?> watchClient({
    required String coachId,
    required String userId,
  }) {
    return _clients(coachId).doc(userId).snapshots().map(
          (doc) => doc.exists
              ? ClientDto.fromSnapshot(doc, coachId: coachId)
              : null,
        );
  }

  @override
  Future<Result<void>> updateClient(ClientEntity client) async {
    try {
      await _clients(client.coachId)
          .doc(client.userId)
          .set(ClientDto.toMap(client), SetOptions(merge: true));
      return const Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(_mapException(e));
    }
  }

  @override
  Stream<List<CoachNoteEntity>> watchNotes({
    required String coachId,
    required String userId,
  }) {
    return _clients(coachId)
        .doc(userId)
        .collection('notes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ClientDto.noteFromSnapshot).toList());
  }

  @override
  Future<Result<void>> addNote({
    required String coachId,
    required String userId,
    required String authorId,
    required String text,
  }) async {
    try {
      await _clients(coachId).doc(userId).collection('notes').add({
        'authorId': authorId,
        'text': text,
        'createdAt': Timestamp.now(),
      });
      return const Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(_mapException(e));
    }
  }

  String _normalizeCode(String raw) =>
      raw.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  Failure _mapException(FirebaseException e) {
    return switch (e.code) {
      'permission-denied' => const Failure.permissionDenied(),
      'not-found' => const Failure.notFound(),
      'unavailable' => const Failure.network(),
      _ => Failure.unexpected(e.message ?? e.code),
    };
  }
}
