// A treinadora só consegue ler os planos e documentos de uma aluna se a
// consulta filtrar também pelo `coachId`.
//
// Por que isso não é detalhe: a regra do Firestore libera esses documentos
// pelo `coachId` deles, e o Firestore não filtra resultados — se a consulta
// não prova que TODO resultado é permitido, ele recusa a consulta inteira.
// Sem o filtro, a treinadora leva `permission-denied` e a ficha da aluna
// aparece vazia.
//
// A aluna lendo os próprios dados passa `null`: ali quem libera é o
// `isOwner`, já provado pelo filtro de `userId`.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gymrank/demo/demo_data.dart';
import 'package:gymrank/demo/demo_overrides.dart';
import 'package:gymrank/demo/fake_repositories.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';
import 'package:gymrank/features/plans/domain/entities/plan_entity.dart';
import 'package:gymrank/features/plans/presentation/controllers/plan_providers.dart';

/// Anota com que `coachId` cada consulta foi feita.
class _RecordingPlanRepository extends FakePlanRepository {
  final List<String?> documentQueries = [];
  final List<String?> planQueries = [];

  @override
  Stream<List<PlanDocumentEntity>> watchDocuments(String userId,
      {String? coachId}) {
    documentQueries.add(coachId);
    return super.watchDocuments(userId, coachId: coachId);
  }

  @override
  Stream<List<PlanEntity>> watchPlans(String userId, {String? coachId}) {
    planQueries.add(coachId);
    return super.watchPlans(userId, coachId: coachId);
  }
}

void main() {
  late _RecordingPlanRepository repository;

  ProviderContainer containerFor(String signedInUid) {
    repository = _RecordingPlanRepository();
    final container = ProviderContainer(
      overrides: [
        ...demoOverrides(),
        planRepositoryProvider.overrideWithValue(repository),
        authStateProvider.overrideWith((ref) => Stream.value(signedInUid)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// Os provedores dependem do perfil carregado. Mantém uma assinatura viva
  /// (sem ela o provider é descartado ainda carregando) e espera o valor.
  Future<void> settle(ProviderContainer container) async {
    container.listen(currentUserProvider, (_, __) {});
    for (var i = 0; i < 20; i++) {
      if (container.read(currentUserProvider).valueOrNull != null) return;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    fail('o perfil do usuário não carregou no teste');
  }

  test('a treinadora consulta filtrando pelo coachId dela', () async {
    final container = containerFor(DemoData.uid);
    await settle(container);

    container.listen(studentDocumentsProvider('u0'), (_, __) {});
    container.listen(studentPlansProvider('u0'), (_, __) {});
    await Future<void>.delayed(Duration.zero);

    expect(repository.documentQueries, isNotEmpty);
    expect(repository.documentQueries.last, DemoData.coachId);
    expect(repository.planQueries.last, DemoData.coachId);
  });

  test('a aluna lendo os próprios dados não filtra por coachId', () async {
    final container = containerFor('u0');
    await settle(container);

    container.listen(studentDocumentsProvider('u0'), (_, __) {});
    container.listen(studentPlansProvider('u0'), (_, __) {});
    await Future<void>.delayed(Duration.zero);

    expect(repository.documentQueries, isNotEmpty);
    expect(repository.documentQueries.last, isNull);
    expect(repository.planQueries.last, isNull);
  });
}
