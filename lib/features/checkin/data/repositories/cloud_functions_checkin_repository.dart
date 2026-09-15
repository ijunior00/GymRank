import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart' hide Result;
import 'package:gymrank/core/error/failure.dart';
import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/features/checkin/domain/checkin_qr.dart';
import 'package:gymrank/features/checkin/domain/entities/checkin_entity.dart';
import 'package:gymrank/features/checkin/domain/entities/checkin_location.dart';
import 'package:gymrank/features/checkin/domain/repositories/checkin_repository.dart';

class CloudFunctionsCheckInRepository implements CheckInRepository {
  CloudFunctionsCheckInRepository(this._functions, this._firestore);

  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _locations(String coachId) =>
      _firestore.collection('coaches').doc(coachId).collection('locations');

  @override
  Future<Result<CheckInEntity>> submitQrPayload(
    String qrPayload, {
    CheckInPosition? position,
  }) async {
    try {
      final callable = _functions.httpsCallable('validateCheckIn');
      final response = await callable.call<Map<String, dynamic>>({
        // Do QR de academia só a query interessa; o rotativo vai inteiro.
        'qrPayload': CheckInQr.isLocationPayload(qrPayload)
            ? CheckInQr.queryOf(qrPayload)
            : qrPayload,
        if (position != null) 'position': position.toJson(),
      });
      final data = response.data;
      return Result.success(
        CheckInEntity(
          id: data['checkInId'] as String,
          userId: data['userId'] as String,
          coachId: data['coachId'] as String,
          checkedInAt: DateTime.parse(data['checkedInAt'] as String),
          xpGranted: (data['xpGranted'] as num).toInt(),
          countedForStreak: data['countedForStreak'] as bool,
          locationName: data['locationName'] as String?,
        ),
      );
    } on FirebaseFunctionsException catch (e) {
      return Result.failure(switch (e.code) {
        'already-exists' => const Failure.conflict(
            'Ya hiciste check-in hace poco.',
          ),
        'invalid-argument' => Failure.validation(
            e.message ?? 'Código QR inválido o vencido.',
          ),
        // A function explica o que faltou (GPS desligado, longe demais…).
        'failed-precondition' => Failure.validation(
            e.message ?? 'No pudimos confirmar tu ubicación.',
          ),
        'not-found' => const Failure.notFound(),
        'unauthenticated' => const Failure.unauthenticated(),
        _ => Failure.unexpected(e.message ?? e.code),
      });
    }
  }

  @override
  Stream<List<CheckInEntity>> watchRecent(String userId, {int limit = 10}) {
    return _firestore
        .collectionGroup('checkins')
        .where('userId', isEqualTo: userId)
        .orderBy('checkedInAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((doc) {
              final data = doc.data();
              return CheckInEntity(
                id: doc.id,
                userId: data['userId'] as String,
                coachId: data['coachId'] as String,
                checkedInAt: (data['checkedInAt'] as Timestamp).toDate(),
                xpGranted: (data['xpGranted'] as num?)?.toInt() ?? 0,
                countedForStreak: data['countedForStreak'] as bool? ?? false,
                locationName: data['locationName'] as String?,
              );
            }).toList());
  }

  @override
  Stream<List<CheckInLocation>> watchLocations(String coachId) {
    return _locations(coachId).orderBy('createdAt').snapshots().map(
          (s) => s.docs.map((d) => _locationFrom(coachId, d.id, d.data())).toList(),
        );
  }

  @override
  Future<Result<CheckInLocation>> saveLocation(CheckInLocation location) async {
    try {
      final col = _locations(location.coachId);
      final ref = location.id.isEmpty ? col.doc() : col.doc(location.id);
      final data = {
        'name': location.name.trim(),
        'address': (location.address ?? '').trim().isEmpty ? null : location.address!.trim(),
        'lat': location.lat,
        'lng': location.lng,
        'radiusM': location.radiusM,
        'qrVersion': location.qrVersion,
        'active': location.active,
        'updatedAt': Timestamp.now(),
      };
      if (location.id.isEmpty) {
        await ref.set({...data, 'createdAt': Timestamp.now()});
      } else {
        await ref.update(data);
      }
      return Result.success(location.copyWith(id: ref.id));
    } on FirebaseException catch (e) {
      return Result.failure(_mapException(e));
    }
  }

  @override
  Future<Result<void>> deleteLocation({
    required String coachId,
    required String locationId,
  }) async {
    try {
      await _locations(coachId).doc(locationId).delete();
      return const Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(_mapException(e));
    }
  }

  @override
  Future<Result<String>> issueLocationQr(String locationId) async {
    try {
      final response = await _functions
          .httpsCallable('issueLocationQr')
          .call<Map<String, dynamic>>({'locationId': locationId});
      return Result.success(response.data['url'] as String);
    } on FirebaseFunctionsException catch (e) {
      return Result.failure(switch (e.code) {
        'permission-denied' => const Failure.permissionDenied(),
        'not-found' => const Failure.notFound(),
        'unauthenticated' => const Failure.unauthenticated(),
        _ => Failure.unexpected(e.message ?? e.code),
      });
    }
  }

  CheckInLocation _locationFrom(String coachId, String id, Map<String, dynamic> d) {
    return CheckInLocation(
      id: id,
      coachId: coachId,
      name: d['name'] as String? ?? '',
      address: d['address'] as String?,
      lat: (d['lat'] as num?)?.toDouble() ?? 0,
      lng: (d['lng'] as num?)?.toDouble() ?? 0,
      radiusM: (d['radiusM'] as num?)?.toDouble() ?? CheckInLocation.defaultRadiusM,
      qrVersion: (d['qrVersion'] as num?)?.toInt() ?? 1,
      active: d['active'] as bool? ?? true,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
