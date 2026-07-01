import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/features/friendship/domain/entities/friendship_entity.dart';

abstract interface class FriendshipRepository {
  Future<Result<void>> sendRequest({
    required String requesterId,
    required String addresseeUsername,
  });

  Future<Result<void>> respond({
    required String friendshipId,
    required bool accept,
  });

  Future<Result<void>> block({
    required String userId,
    required String otherUserId,
  });

  Stream<List<FriendshipEntity>> watchFriendships(String userId);
}
