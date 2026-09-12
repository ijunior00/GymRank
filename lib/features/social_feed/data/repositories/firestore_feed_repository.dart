import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymrank/core/error/failure.dart';
import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/features/social_feed/domain/entities/post_entity.dart';
import 'package:gymrank/features/social_feed/domain/repositories/feed_repository.dart';

class FirestoreFeedRepository implements FeedRepository {
  FirestoreFeedRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _firestore.collection('posts');

  @override
  Stream<List<PostEntity>> watchFeed({int limit = 15}) {
    return _posts
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(_postFromSnapshot).toList());
  }

  @override
  Future<Result<void>> toggleLike({
    required String postId,
    required String userId,
    required bool liked,
  }) async {
    try {
      final likeRef = _posts.doc(postId).collection('likes').doc(userId);
      if (liked) {
        await likeRef.set({'userId': userId, 'createdAt': Timestamp.now()});
        await _posts.doc(postId).update({'likeCount': FieldValue.increment(1)});
      } else {
        await likeRef.delete();
        await _posts.doc(postId).update({'likeCount': FieldValue.increment(-1)});
      }
      return const Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(Failure.unexpected(e.message ?? e.code));
    }
  }

  @override
  Stream<bool> watchLiked({required String postId, required String userId}) {
    return _posts
        .doc(postId)
        .collection('likes')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  @override
  Future<Result<void>> addComment(CommentEntity comment) async {
    try {
      await _posts.doc(comment.postId).collection('comments').add({
        'postId': comment.postId,
        'userId': comment.userId,
        'authorName': comment.authorName,
        'authorPhotoUrl': comment.authorPhotoUrl,
        'text': comment.text,
        'createdAt': Timestamp.fromDate(comment.createdAt),
      });
      await _posts.doc(comment.postId).update({
        'commentCount': FieldValue.increment(1),
      });
      return const Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(Failure.unexpected(e.message ?? e.code));
    }
  }

  @override
  Stream<List<CommentEntity>> watchComments(String postId) {
    return _posts
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt')
        .snapshots()
        .map((s) => s.docs.map((doc) {
              final data = doc.data();
              return CommentEntity(
                id: doc.id,
                postId: postId,
                userId: data['userId'] as String,
                authorName: data['authorName'] as String,
                authorPhotoUrl: data['authorPhotoUrl'] as String?,
                text: data['text'] as String,
                createdAt: (data['createdAt'] as Timestamp).toDate(),
              );
            }).toList());
  }

  PostEntity _postFromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return PostEntity(
      id: doc.id,
      userId: data['userId'] as String,
      authorName: data['authorName'] as String,
      authorPhotoUrl: data['authorPhotoUrl'] as String?,
      type: PostType.values.byName(data['type'] as String),
      text: data['text'] as String,
      imageUrl: data['imageUrl'] as String?,
      likeCount: data['likeCount'] as int? ?? 0,
      commentCount: data['commentCount'] as int? ?? 0,
      shareCount: data['shareCount'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
