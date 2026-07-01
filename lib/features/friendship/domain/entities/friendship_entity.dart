import 'package:freezed_annotation/freezed_annotation.dart';

part 'friendship_entity.freezed.dart';

enum FriendshipStatus { pending, accepted, blocked }

/// Documento canônico de `friendships/{friendshipId}`, onde
/// `friendshipId` é a concatenação ordenada `${uidA}_${uidB}` para evitar
/// pares duplicados.
@freezed
class FriendshipEntity with _$FriendshipEntity {
  const factory FriendshipEntity({
    required String id,
    required String requesterId,
    required String addresseeId,
    required FriendshipStatus status,
    required DateTime createdAt,
    DateTime? respondedAt,
  }) = _FriendshipEntity;
}
