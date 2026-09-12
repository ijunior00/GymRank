import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/core/error/failure.dart';
import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/core/l10n/labels_es.dart';
import 'package:gymrank/core/theme/app_colors.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';
import 'package:gymrank/features/friendship/domain/entities/friendship_entity.dart';
import 'package:gymrank/features/friendship/presentation/controllers/friendship_providers.dart';
import 'package:gymrank/features/profile/presentation/controllers/user_repository_provider.dart';

class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendships = ref.watch(myFriendshipsProvider);
    final uid = ref.watch(authStateProvider).valueOrNull ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Amigos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addFriend(context, ref),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Agregar'),
      ),
      body: friendships.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (all) {
          // `blocked` (pedido recusado ou bloqueio) não aparece na lista.
          final list = all
              .where((f) => f.status != FriendshipStatus.blocked)
              .toList()
            ..sort((a, b) {
              // Pedidos recebidos primeiro: são os que pedem uma ação.
              final aIn = a.status == FriendshipStatus.pending && a.addresseeId == uid;
              final bIn = b.status == FriendshipStatus.pending && b.addresseeId == uid;
              if (aIn != bIn) return aIn ? -1 : 1;
              return b.createdAt.compareTo(a.createdAt);
            });
          if (list.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Agrega amigos por su nombre de usuario para competir con '
                  'ellos en el ranking.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMuted,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: list.length,
            itemBuilder: (context, i) => _FriendshipTile(
              friendship: list[i],
              currentUserId: uid,
            ),
          );
        },
      ),
    );
  }

  Future<void> _addFriend(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final username = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar amigo'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            prefixText: '@',
            hintText: 'usuario',
          ),
          onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Enviar solicitud'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (username == null || username.isEmpty || !context.mounted) return;

    final uid = ref.read(authStateProvider).valueOrNull;
    if (uid == null) return;
    final result = await ref.read(friendshipRepositoryProvider).sendRequest(
          requesterId: uid,
          addresseeUsername: username.replaceFirst('@', ''),
        );
    if (!context.mounted) return;
    final failure = result.failureOrNull;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failure == null
              ? 'Solicitud enviada a @$username.'
              : failure is NotFoundFailure
                  ? 'No encontramos a @$username. Revisa el usuario.'
                  : 'No se pudo enviar: $failure',
        ),
      ),
    );
  }
}

class _FriendshipTile extends ConsumerWidget {
  const _FriendshipTile({required this.friendship, required this.currentUserId});

  final FriendshipEntity friendship;
  final String currentUserId;

  Future<void> _respond(BuildContext context, WidgetRef ref, bool accept) async {
    final result = await ref.read(friendshipRepositoryProvider).respond(
          friendshipId: friendship.id,
          accept: accept,
        );
    if (!context.mounted) return;
    final failure = result.failureOrNull;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failure != null
              ? 'No se pudo: $failure'
              : accept
                  ? '¡Ahora son amigos!'
                  : 'Solicitud rechazada.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otherUserId = friendship.requesterId == currentUserId
        ? friendship.addresseeId
        : friendship.requesterId;
    final other = ref.watch(userByIdProvider(otherUserId)).valueOrNull;
    final isIncomingPending = friendship.status == FriendshipStatus.pending &&
        friendship.addresseeId == currentUserId;
    final isOutgoingPending = friendship.status == FriendshipStatus.pending &&
        friendship.requesterId == currentUserId;

    final statusText = isIncomingPending
        ? 'Quiere ser tu amigo'
        : isOutgoingPending
            ? 'Solicitud enviada'
            : friendship.status.labelEs;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.surfaceElevated,
          backgroundImage:
              other?.photoUrl != null ? NetworkImage(other!.photoUrl!) : null,
          child: other?.photoUrl == null
              ? Text(
                  other == null ? '…' : _initials(other.name),
                  style: AppTextStyles.title.copyWith(color: AppColors.primary),
                )
              : null,
        ),
        title: Text(other?.name ?? 'Cargando…'),
        subtitle: Text(
          other == null
              ? statusText
              : '@${other.username} · nivel ${other.level} · $statusText',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: isIncomingPending
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Aceptar',
                    icon: const Icon(Icons.check, color: AppColors.success),
                    onPressed: () => _respond(context, ref, true),
                  ),
                  IconButton(
                    tooltip: 'Rechazar',
                    icon: const Icon(Icons.close, color: AppColors.warning),
                    onPressed: () => _respond(context, ref, false),
                  ),
                ],
              )
            : isOutgoingPending
                ? const Icon(Icons.hourglass_top,
                    size: 18, color: AppColors.textSecondary)
                : null,
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }
}
