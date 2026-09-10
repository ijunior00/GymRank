import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/features/sharing/domain/entities/share_card.dart';

/// Um card compartilhado, como a treinadora vê no painel.
class ShareEventEntity {
  const ShareEventEntity({
    required this.id,
    required this.userId,
    required this.userName,
    required this.kind,
    required this.sharedAt,
  });

  final String id;
  final String userId;
  final String userName;
  final ShareCardKind kind;
  final DateTime sharedAt;
}

abstract interface class ShareRepository {
  /// Registra que o usuário logado compartilhou um card. Falha aqui nunca
  /// deve atrapalhar o compartilhamento em si.
  Future<Result<void>> recordShare(ShareCardKind kind);

  /// Cards compartilhados na comunidade da treinadora, recentes primeiro.
  Stream<List<ShareEventEntity>> watchRecent(String coachId, {int limit});
}
