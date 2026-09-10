import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart' hide Result;
import 'package:gymrank/core/error/failure.dart';
import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/features/checkin/domain/entities/checkin_entity.dart';
import 'package:gymrank/features/checkin/domain/repositories/checkin_repository.dart';

class CloudFunctionsCheckInRepository implements CheckInRepository {
  CloudFunctionsCheckInRepository(this._functions, this._firestore);

  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  @override
  Future<Result<CheckInEntity>> submitQrPayload(String qrPayload) async {
    try {
      final callable = _functions.httpsCallable('validateCheckIn');
      final response = await callable.call<Map<String, dynamic>>({
        'qrPayload': qrPayload,
      });
      final data = response.data;
      return Result.success(
        CheckInEntity(
          id: data['checkInId'] as String,
          userId: data['userId'] as String,
          coachId: data['coachId'] as String,
          checkedInAt: DateTime.parse(data['checkedInAt'] as String),
          xpGranted: data['xpGranted'] as int,
          countedForStreak: data['countedForStreak'] as bool,
        ),
      );
    } on FirebaseFunctionsException catch (e) {
      return Result.failure(switch (e.code) {
        'already-exists' => const Failure.conflict(
            'Ya hiciste check-in hace poco.',
          ),
        'invalid-argument' =>
          const Failure.validation('Código QR inválido o vencido.'),
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
                xpGranted: data['xpGranted'] as int,
                countedForStreak: data['countedForStreak'] as bool,
              );
            }).toList());
  }
}
