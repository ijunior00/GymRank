import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/core/theme/app_colors.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';
import 'package:gymrank/core/utils/date_formatter.dart';
import 'package:gymrank/core/utils/share_text.dart';
import 'package:gymrank/core/widgets/entrance.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';
import 'package:gymrank/features/coach_panel/presentation/controllers/coach_panel_providers.dart';
import 'package:gymrank/features/social_feed/domain/entities/post_entity.dart';
import 'package:gymrank/features/social_feed/presentation/controllers/feed_providers.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(feedPostsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Comunidad')),
      body: posts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('Aún no hay novedades.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => Entrance(
              delay: Duration(milliseconds: 70 * i),
              child: _PostCard(post: list[i]),
            ),
          );
        },
      ),
    );
  }
}

class _PostCard extends ConsumerWidget {
  const _PostCard({required this.post});

  final PostEntity post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authStateProvider).valueOrNull;
    final liked = ref.watch(postLikedProvider(post.id)).valueOrNull ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: AppColors.streakGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.background,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.surfaceElevated,
                      backgroundImage: post.authorPhotoUrl != null
                          ? NetworkImage(post.authorPhotoUrl!)
                          : null,
                      child: post.authorPhotoUrl == null
                          ? const Icon(Icons.person,
                              size: 18, color: AppColors.textSecondary)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.authorName, style: AppTextStyles.title),
                      Text(
                        DateFormatter.relative(post.createdAt),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                _PostTypeBadge(type: post.type),
              ],
            ),
            const SizedBox(height: 12),
            Text(post.text, style: AppTextStyles.body),
            const SizedBox(height: 14),
            Row(
              children: [
                _PostAction(
                  icon: liked ? Icons.favorite : Icons.favorite_border,
                  color: liked ? AppColors.secondary : null,
                  count: post.likeCount,
                  tooltip: liked ? 'Quitar me gusta' : 'Me gusta',
                  onTap: uid == null
                      ? null
                      : () async {
                          final result =
                              await ref.read(feedRepositoryProvider).toggleLike(
                                    postId: post.id,
                                    userId: uid,
                                    liked: !liked,
                                  );
                          final failure = result.failureOrNull;
                          if (failure != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('No se pudo: $failure')),
                            );
                          }
                        },
                ),
                const SizedBox(width: 20),
                _PostAction(
                  icon: Icons.mode_comment_outlined,
                  count: post.commentCount,
                  tooltip: 'Comentarios',
                  onTap: () => _showComments(context, post),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Compartir',
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    final coach = ref.read(currentCoachProvider).valueOrNull;
                    final invite = coach == null
                        ? ''
                        : '\n\nEntrenamos con ${coach.name}. Únete con el '
                            'código ${coach.inviteCode}.';
                    shareText(context, '${post.text}$invite');
                  },
                  icon: const Icon(Icons.share_outlined,
                      size: 20, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showComments(BuildContext context, PostEntity post) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _CommentsSheet(post: post),
    );
  }
}

/// Comentários do post com campo para escrever. Cabe na metade de baixo
/// da tela e sobe junto com o teclado.
class _CommentsSheet extends ConsumerStatefulWidget {
  const _CommentsSheet({required this.post});

  final PostEntity post;

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final _controller = TextEditingController();
  bool _sending = false;

  /// Erro mostrado dentro da folha: um SnackBar ficaria escondido atrás.
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    final user = ref.read(currentUserProvider).valueOrNull;
    if (text.isEmpty || user == null) return;

    setState(() => _sending = true);
    final result = await ref.read(feedRepositoryProvider).addComment(
          CommentEntity(
            id: '',
            postId: widget.post.id,
            userId: user.id,
            authorName: user.name,
            authorPhotoUrl: user.photoUrl,
            text: text,
            createdAt: DateTime.now(),
          ),
        );
    if (!mounted) return;
    final failure = result.failureOrNull;
    setState(() {
      _sending = false;
      _error = failure == null ? null : 'No se pudo comentar: $failure';
    });
    if (failure == null) _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final comments = ref.watch(postCommentsProvider(widget.post.id));
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final height = MediaQuery.sizeOf(context).height * 0.65;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Comentarios', style: AppTextStyles.headline),
                  ),
                  Text(
                    widget.post.authorName,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),
            Expanded(
              child: comments.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (list) {
                  if (list.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Sé la primera en comentar.',
                          style: AppTextStyles.bodyMuted,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final c = list[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.surfaceElevated,
                              backgroundImage: c.authorPhotoUrl != null
                                  ? NetworkImage(c.authorPhotoUrl!)
                                  : null,
                              child: c.authorPhotoUrl == null
                                  ? const Icon(Icons.person,
                                      size: 16,
                                      color: AppColors.textSecondary)
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(c.authorName,
                                          style: AppTextStyles.title),
                                      const SizedBox(width: 8),
                                      Text(
                                        DateFormatter.relative(c.createdAt),
                                        style: AppTextStyles.caption,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(c.text, style: AppTextStyles.body),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Text(
                  _error!,
                  style: AppTextStyles.caption.copyWith(color: AppColors.danger),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Escribe un comentario…',
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _sending
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          tooltip: 'Enviar',
                          onPressed: _send,
                          icon: const Icon(Icons.send, color: AppColors.primary),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostAction extends StatelessWidget {
  const _PostAction({
    required this.icon,
    required this.count,
    required this.tooltip,
    this.color,
    this.onTap,
  });

  final IconData icon;
  final int count;
  final String tooltip;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color ?? AppColors.textSecondary),
              const SizedBox(width: 6),
              Text('$count', style: AppTextStyles.caption),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostTypeBadge extends StatelessWidget {
  const _PostTypeBadge({required this.type});

  final PostType type;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, String label) = switch (type) {
      PostType.levelUp => (Icons.military_tech, 'Nivel'),
      PostType.streakMilestone => (Icons.local_fire_department, 'Racha'),
      PostType.personalRecord => (Icons.bolt, 'Récord'),
      PostType.challengeCompleted => (Icons.flag, 'Reto'),
      PostType.xpMilestone => (Icons.star, 'XP'),
      PostType.custom => (Icons.chat_bubble_outline, ''),
    };
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
