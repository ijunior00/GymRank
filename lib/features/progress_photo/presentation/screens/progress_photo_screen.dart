import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gymrank/core/constants/app_constants.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';
import 'package:gymrank/features/progress_photo/domain/entities/progress_photo_entity.dart';
import 'package:gymrank/features/progress_photo/presentation/controllers/progress_photo_providers.dart';

/// Galeria de fotos de evolução com timeline por categoria (frente,
/// costas, perfil). Comparação lado a lado é feita selecionando duas
/// fotos da mesma categoria em datas diferentes.
class ProgressPhotoScreen extends ConsumerWidget {
  const ProgressPhotoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = ref.watch(progressPhotosProvider);

    return DefaultTabController(
      length: ProgressPhotoCategory.values.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Fotos de progreso'),
          bottom: TabBar(
            tabs: ProgressPhotoCategory.values
                .map((c) => Tab(text: c.label))
                .toList(),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _pickAndUpload(context, ref),
          child: const Icon(Icons.add_a_photo_outlined),
        ),
        body: photos.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (all) => TabBarView(
            children: ProgressPhotoCategory.values.map((category) {
              final items =
                  all.where((p) => p.category == category).toList();
              if (items.isEmpty) {
                return const Center(child: Text('Aún no hay fotos.'));
              }
              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: items.length,
                itemBuilder: (context, i) => _PhotoTile(photo: items[i]),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUpload(BuildContext context, WidgetRef ref) async {
    final uid = ref.read(authStateProvider).valueOrNull;
    if (uid == null) return;
    final picked = await ImagePicker().pickImage(source: ImageSource.camera);
    if (picked == null) return;
    if (!context.mounted) return;

    final category = await showModalBottomSheet<ProgressPhotoCategory>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ProgressPhotoCategory.values
              .map(
                (c) => ListTile(
                  title: Text(c.label),
                  onTap: () => Navigator.of(context).pop(c),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (category == null) return;

    await ref.read(progressPhotoRepositoryProvider).upload(
          userId: uid,
          file: File(picked.path),
          category: category,
        );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.photo});

  final ProgressPhotoEntity photo;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: photo.thumbnailUrl,
        fit: BoxFit.cover,
      ),
    );
  }
}

extension on ProgressPhotoCategory {
  String get label => switch (this) {
    ProgressPhotoCategory.frente => 'Frente',
    ProgressPhotoCategory.costas => 'Espalda',
    ProgressPhotoCategory.perfil => 'Perfil',
  };
}
