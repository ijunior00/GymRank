import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/core/di/firebase_providers.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';
import 'package:gymrank/features/plans/data/repositories/firebase_plan_repository.dart';
import 'package:gymrank/features/plans/domain/entities/plan_entity.dart';
import 'package:gymrank/features/plans/domain/repositories/plan_repository.dart';

/// O `coachId` a usar ao ler os dados de OUTRA pessoa.
///
/// A regra do Firestore libera esses documentos pelo `coachId` deles, e uma
/// consulta que não filtra por esse campo é recusada por inteiro — regras
/// não filtram, recusam. Quem lê os próprios dados passa `null`: aí quem
/// libera é o `isOwner`, já provado pelo filtro de `userId`.
String? coachIdForReading(Ref ref, String userId) {
  final me = ref.watch(currentUserProvider).valueOrNull;
  if (me == null || me.id == userId || !me.isStaff) return null;
  return me.coachId;
}

final planRepositoryProvider = Provider<PlanRepository>((ref) {
  return FirebasePlanRepository(
    ref.watch(firestoreProvider),
    ref.watch(firebaseStorageProvider),
  );
});

/// Documentos enviados para um aluno (visão da treinadora).
final studentDocumentsProvider =
    StreamProvider.family<List<PlanDocumentEntity>, String>((ref, userId) {
  return ref.watch(planRepositoryProvider).watchDocuments(
        userId,
        coachId: coachIdForReading(ref, userId),
      );
});

final planDocumentProvider =
    StreamProvider.family<PlanDocumentEntity?, String>((ref, documentId) {
  return ref.watch(planRepositoryProvider).watchDocument(documentId);
});

/// Planos vigentes de um aluno (um por tipo), mais recente primeiro.
final studentPlansProvider =
    StreamProvider.family<List<PlanEntity>, String>((ref, userId) {
  return ref.watch(planRepositoryProvider).watchPlans(
        userId,
        coachId: coachIdForReading(ref, userId),
      );
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
