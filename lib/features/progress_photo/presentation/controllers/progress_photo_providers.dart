import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/core/di/firebase_providers.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';
import 'package:gymrank/features/progress_photo/data/repositories/firebase_progress_photo_repository.dart';
import 'package:gymrank/features/progress_photo/domain/entities/progress_photo_entity.dart';
import 'package:gymrank/features/progress_photo/domain/repositories/progress_photo_repository.dart';

final progressPhotoRepositoryProvider = Provider<ProgressPhotoRepository>((ref) {
  return FirebaseProgressPhotoRepository(
    ref.watch(firestoreProvider),
    ref.watch(firebaseStorageProvider),
  );
});

final progressPhotosProvider = StreamProvider<List<ProgressPhotoEntity>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull;
  if (uid == null) return Stream.value(const []);
  return ref.watch(progressPhotoRepositoryProvider).watchAll(uid);
});
