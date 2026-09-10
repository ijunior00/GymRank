import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/core/di/firebase_providers.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';
import 'package:gymrank/features/plans/data/repositories/firebase_plan_repository.dart';
import 'package:gymrank/features/plans/domain/entities/plan_entity.dart';
import 'package:gymrank/features/plans/domain/repositories/plan_repository.dart';

final planRepositoryProvider = Provider<PlanRepository>((ref) {
  return FirebasePlanRepository(
    ref.watch(firestoreProvider),
    ref.watch(firebaseStorageProvider),
  );
});

/// Documentos enviados para um aluno (visão da treinadora).
final studentDocumentsProvider =
    StreamProvider.family<List<PlanDocumentEntity>, String>((ref, userId) {
  return ref.watch(planRepositoryProvider).watchDocuments(userId);
});

final planDocumentProvider =
    StreamProvider.family<PlanDocumentEntity?, String>((ref, documentId) {
  return ref.watch(planRepositoryProvider).watchDocument(documentId);
});

/// Planos vigentes de um aluno (um por tipo), mais recente primeiro.
final studentPlansProvider =
    StreamProvider.family<List<PlanEntity>, String>((ref, userId) {
  return ref.watch(planRepositoryProvider).watchPlans(userId);
});

/// Planos do usuário logado (visão do aluno).
final myPlansProvider = StreamProvider<List<PlanEntity>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull;
  if (uid == null) return Stream.value(const []);
  return ref.watch(planRepositoryProvider).watchPlans(uid);
});

final planByIdProvider =
    StreamProvider.family<PlanEntity?, String>((ref, planId) {
  return ref.watch(planRepositoryProvider).watchPlan(planId);
});

final planVersionsProvider =
    StreamProvider.family<List<PlanVersionEntity>, String>((ref, planId) {
  return ref.watch(planRepositoryProvider).watchVersions(planId);
});
