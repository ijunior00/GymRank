import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:gymrank/core/error/failure.dart';
import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/features/plans/domain/entities/plan_entity.dart';
import 'package:gymrank/features/plans/domain/repositories/plan_repository.dart';

class FirebasePlanRepository implements PlanRepository {
  FirebasePlanRepository(this._firestore, this._storage);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _documents =>
      _firestore.collection('documents');

  CollectionReference<Map<String, dynamic>> get _plans =>
      _firestore.collection('plans');

  @override
  Future<Result<PlanDocumentEntity>> uploadDocument({
    required String coachId,
    required String userId,
    required String uploadedBy,
    required PlanKind kind,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
  }) async {
    try {
      final now = DateTime.now();
      final safeName = fileName.replaceAll(RegExp(r'[^\w.\-]+'), '_');
      final storagePath =
          'documents/$coachId/$userId/${now.millisecondsSinceEpoch}_$safeName';
      final ref = _storage.ref(storagePath);
      await ref.putData(bytes, SettableMetadata(contentType: contentType));
      final downloadUrl = await ref.getDownloadURL();

      final docRef = _documents.doc();
      final entity = PlanDocumentEntity(
        id: docRef.id,
        coachId: coachId,
        userId: userId,
        uploadedBy: uploadedBy,
        kind: kind,
        fileName: fileName,
        storagePath: storagePath,
        downloadUrl: downloadUrl,
        contentType: contentType,
        sizeBytes: bytes.length,
        status: PlanDocumentStatus.subido,
        errorMessage: null,
        parsedPlan: null,
        planId: null,
        createdAt: now,
        updatedAt: now,
      );
      await docRef.set(_documentToMap(entity));
      return Result.success(entity);
    } on FirebaseException catch (e) {
      return Result.failure(_mapException(e));
    }
  }

  @override
  Stream<List<PlanDocumentEntity>> watchDocuments(String userId) {
    return _documents
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs.map(_documentFromSnapshot).toList());
  }

  @override
  Stream<PlanDocumentEntity?> watchDocument(String documentId) {
    return _documents.doc(documentId).snapshots().map(
          (doc) => doc.exists ? _documentFromSnapshot(doc) : null,
        );
  }

  @override
  Future<Result<void>> retryDocument(String documentId) async {
    try {
      await _documents.doc(documentId).update({
        'status': PlanDocumentStatus.subido.name,
        'errorMessage': null,
        'updatedAt': Timestamp.now(),
      });
      return const Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(_mapException(e));
    }
  }

  @override
  Future<Result<PlanEntity>> publish({
    required String coachId,
    required String userId,
    required PlanKind kind,
    required String title,
    required Map<String, dynamic> content,
    required String publishedBy,
    String? sourceDocumentId,
  }) async {
    try {
      // Um plano vigente por (aluno, tipo): republicar cria nova versão.
      final existing = await _plans
          .where('userId', isEqualTo: userId)
          .where('kind', isEqualTo: kind.name)
          .limit(1)
          .get();
      final planRef =
          existing.docs.isEmpty ? _plans.doc() : existing.docs.first.reference;

      final published = await _firestore.runTransaction((tx) async {
        final snap = await tx.get(planRef);
        final version = ((snap.data()?['currentVersion'] as int?) ?? 0) + 1;
        final now = Timestamp.now();
        final versionData = {
          'number': version,
          'title': title,
          'content': content,
          'sourceDocumentId': sourceDocumentId,
          'publishedAt': now,
          'publishedBy': publishedBy,
          'coachId': coachId,
          'userId': userId,
        };
        tx.set(planRef, {
          'coachId': coachId,
          'userId': userId,
          'kind': kind.name,
          'title': title,
          'currentVersion': version,
          'content': content,
          'sourceDocumentId': sourceDocumentId,
          'publishedAt': now,
          'publishedBy': publishedBy,
          if (!snap.exists) 'createdAt': now,
        });
        tx.set(planRef.collection('versions').doc('$version'), versionData);
        if (sourceDocumentId != null) {
          tx.update(_documents.doc(sourceDocumentId), {
            'status': PlanDocumentStatus.publicado.name,
            'planId': planRef.id,
            'parsedPlan': content,
            'updatedAt': now,
          });
        }
        return PlanEntity(
          id: planRef.id,
          coachId: coachId,
          userId: userId,
          kind: kind,
          title: title,
          currentVersion: version,
          content: content,
          sourceDocumentId: sourceDocumentId,
          publishedAt: now.toDate(),
          publishedBy: publishedBy,
        );
      });
      return Result.success(published);
    } on FirebaseException catch (e) {
      return Result.failure(_mapException(e));
    }
  }

  @override
  Stream<List<PlanEntity>> watchPlans(String userId) {
    return _plans
        .where('userId', isEqualTo: userId)
        .orderBy('publishedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(_planFromSnapshot).toList());
  }

  @override
  Stream<PlanEntity?> watchPlan(String planId) {
    return _plans.doc(planId).snapshots().map(
          (doc) => doc.exists ? _planFromSnapshot(doc) : null,
        );
  }

  @override
  Stream<List<PlanVersionEntity>> watchVersions(String planId) {
    return _plans
        .doc(planId)
        .collection('versions')
        .orderBy('number', descending: true)
        .snapshots()
        .map((s) => s.docs.map((doc) {
              final d = doc.data();
              return PlanVersionEntity(
                number: d['number'] as int,
                title: d['title'] as String? ?? '',
                content: Map<String, dynamic>.from(d['content'] as Map? ?? {}),
                sourceDocumentId: d['sourceDocumentId'] as String?,
                publishedAt: (d['publishedAt'] as Timestamp).toDate(),
                publishedBy: d['publishedBy'] as String? ?? '',
              );
            }).toList());
  }

  // --- mapeamento -----------------------------------------------------------

  Map<String, dynamic> _documentToMap(PlanDocumentEntity d) => {
        'coachId': d.coachId,
        'userId': d.userId,
        'uploadedBy': d.uploadedBy,
        'kind': d.kind.name,
        'fileName': d.fileName,
        'storagePath': d.storagePath,
        'downloadUrl': d.downloadUrl,
        'contentType': d.contentType,
        'sizeBytes': d.sizeBytes,
        'status': d.status.name,
        'errorMessage': d.errorMessage,
        'parsedPlan': d.parsedPlan,
        'planId': d.planId,
        'createdAt': Timestamp.fromDate(d.createdAt),
        'updatedAt': Timestamp.fromDate(d.updatedAt),
      };

  PlanDocumentEntity _documentFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    return PlanDocumentEntity(
      id: doc.id,
      coachId: d['coachId'] as String,
      userId: d['userId'] as String,
      uploadedBy: d['uploadedBy'] as String? ?? '',
      kind: PlanKind.values.byName(d['kind'] as String? ?? 'otro'),
      fileName: d['fileName'] as String? ?? 'documento',
      storagePath: d['storagePath'] as String? ?? '',
      downloadUrl: d['downloadUrl'] as String?,
      contentType: d['contentType'] as String? ?? '',
      sizeBytes: d['sizeBytes'] as int? ?? 0,
      status: PlanDocumentStatus.values
          .byName(d['status'] as String? ?? 'subido'),
      errorMessage: d['errorMessage'] as String?,
      parsedPlan: d['parsedPlan'] == null
          ? null
          : Map<String, dynamic>.from(d['parsedPlan'] as Map),
      planId: d['planId'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  PlanEntity _planFromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return PlanEntity(
      id: doc.id,
      coachId: d['coachId'] as String,
      userId: d['userId'] as String,
      kind: PlanKind.values.byName(d['kind'] as String? ?? 'otro'),
      title: d['title'] as String? ?? '',
      currentVersion: d['currentVersion'] as int? ?? 1,
      content: Map<String, dynamic>.from(d['content'] as Map? ?? {}),
      sourceDocumentId: d['sourceDocumentId'] as String?,
      publishedAt: (d['publishedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      publishedBy: d['publishedBy'] as String? ?? '',
    );
  }

  Failure _mapException(FirebaseException e) {
    return switch (e.code) {
      'permission-denied' => const Failure.permissionDenied(),
      'not-found' => const Failure.notFound(),
      'unavailable' => const Failure.network(),
      'canceled' => const Failure.validation('Subida cancelada.'),
      _ => Failure.unexpected(e.message ?? e.code),
    };
  }
}
