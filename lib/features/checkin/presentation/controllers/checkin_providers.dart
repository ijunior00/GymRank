import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/core/di/firebase_providers.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';
import 'package:gymrank/features/checkin/data/geolocator_position_source.dart';
import 'package:gymrank/features/checkin/data/repositories/cloud_functions_checkin_repository.dart';
import 'package:gymrank/features/checkin/domain/entities/checkin_location.dart';
import 'package:gymrank/features/checkin/domain/repositories/checkin_repository.dart';

final checkInRepositoryProvider = Provider<CheckInRepository>((ref) {
  return CloudFunctionsCheckInRepository(
    ref.watch(firebaseFunctionsProvider),
    ref.watch(firestoreProvider),
  );
});

/// GPS do aparelho. O preview e os testes trocam por uma posição fixa.
final positionSourceProvider = Provider<PositionSource>((ref) {
  return const GeolocatorPositionSource();
});

/// Academias com QR da comunidade da treinadora logada.
final coachLocationsProvider = StreamProvider<List<CheckInLocation>>((ref) {
  final coachId = ref.watch(currentUserProvider).valueOrNull?.coachId;
  if (coachId == null) return Stream.value(const []);
  return ref.watch(checkInRepositoryProvider).watchLocations(coachId);
});
