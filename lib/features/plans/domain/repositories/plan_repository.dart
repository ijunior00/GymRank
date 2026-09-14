import 'dart:typed_data';

import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/features/plans/domain/entities/plan_entity.dart';

abstract interface class PlanRepository {
  /// Sobe o arquivo para `documents/{coachId}/{userId}/…` no Storage e cria
  /// `documents/{docId}` com status `subido`, o que dispara o parser.
  Future<Result<PlanDocumentEntity>> uploadDocument({
    required String coachId,
    required String userId,
    required String uploadedBy,
    required PlanKind kind,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
  });

  /// [coachId] é obrigatório quando quem lê é a treinadora: a regra do
  /// Firestore libera pelo `coachId` do documento, e uma consulta que não
  /// filtra por ele é recusada inteira (regras não filtram, recusam).
  Stream<List<PlanDocumentEntity>> watchDocuments(String userId, {String? coachId});

  Stream<PlanDocumentEntity?> watchDocument(String documentId);

  /// Volta o documento para `subido` para o parser tentar de novo.
  Future<Result<void>> retryDocument(String documentId);

  /// Publica o conteúdo revisado como nova versão do plano vigente do
  /// aluno para aquele tipo (cria o plano na primeira vez) e marca o
  /// documento de origem, se houver, como `publicado`.
  Future<Result<PlanEntity>> publish({
    required String coachId,
    required String userId,
    required PlanKind kind,
    required String title,
    required Map<String, dynamic> content,
    required String publishedBy,
    String? sourceDocumentId,
  });

  /// Ver [watchDocuments] sobre o [coachId].
  Stream<List<PlanEntity>> watchPlans(String userId, {String? coachId});

  Stream<PlanEntity?> watchPlan(String planId);

  Stream<List<PlanVersionEntity>> watchVersions(String planId);
}
