import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/core/di/firebase_providers.dart';
import 'package:gymrank/features/checkin/data/repositories/cloud_functions_checkin_repository.dart';
import 'package:gymrank/features/checkin/domain/repositories/checkin_repository.dart';

final checkInRepositoryProvider = Provider<CheckInRepository>((ref) {
  return CloudFunctionsCheckInRepository(
    ref.watch(firebaseFunctionsProvider),
    ref.watch(firestoreProvider),
  );
});
