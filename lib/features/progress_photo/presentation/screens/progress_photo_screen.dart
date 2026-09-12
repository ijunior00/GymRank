import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gymrank/core/constants/app_constants.dart';
import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/core/theme/app_colors.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';
import 'package:gymrank/core/utils/date_formatter.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';
import 'package:gymrank/features/progress_photo/domain/entities/progress_photo_entity.dart';
import 'package:gymrank/features/progress_photo/presentation/controllers/progress_photo_providers.dart';

/// Galeria de fotos de evolução por categoria (frente, espalda, perfil).
/// Toque abre em tela cheia com a data; o botão deixa escolher câmera ou
/// galeria e funciona também no navegador (bytes, não `File`).
class ProgressPhotoScreen extends ConsumerStatefulWidget {
  const ProgressPhotoScreen({super.key});

  @override
  ConsumerState<ProgressPhotoScreen> createState() =>
      _ProgressPhotoScreenState();
}

class _ProgressPhotoScreenState extends ConsumerState<ProgressPhotoScreen> {
  bool _uploading = false;

  @override
  Widget build(BuildContext context) {
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
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _uploading ? null : _pickAndUpload,
          icon: _uploading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add_a_photo_outlined),
          label: Text(_uploading ? 'Subiendo…' : 'Nueva foto'),
        ),
        body: photos.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (all) => TabBarView(
            children: ProgressPhotoCategory.values.map((category) {
              final items = all.where((p) => p.category == category).toList()
                ..sort((a, b) => b.takenAt.compareTo(a.takenAt));
              if (items.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Aún no hay fotos de ${category.label.toLowerCase()}. '
                      'Tómalas siempre con la misma luz y a la misma hora '
                      'para comparar bien.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMuted,
                    ),
                  ),
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: items.length,
                itemBuilder: (context, i) => _PhotoTile(
                  photo: items[i],
                  onTap: () => _openFullScreen(context, items, i),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUpload() async {
    final uid = ref.read(authStateProvider).valueOrNull;
    if (uid == null) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    final category = await showModalBottomSheet<ProgressPhotoCategory>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text('¿Qué ángulo es?', style: AppTextStyles.headline),
            ),
            for (final c in ProgressPhotoCategory.values)
              ListTile(
                leading: Icon(c.icon),
                title: Text(c.label),
                onTap: () => Navigator.of(context).pop(c),
              ),
          ],
        ),
      ),
    );
    if (category == null || !mounted) return;

    setState(() => _uploading = true);
    final bytes = await picked.readAsBytes();
    final result = await ref.read(progressPhotoRepositoryProvider).upload(
          userId: uid,
          bytes: bytes,
          category: category,
        );
    if (!mounted) return;
    setState(() => _uploading = false);
    final failure = result.failureOrNull;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failure == null
              ? 'Foto guardada en ${category.label}.'
              : 'No se pudo subir: $failure',
        ),
      ),
    );
  }

  void _openFullScreen(
    BuildContext context,
    List<ProgressPhotoEntity> items,
    int index,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _PhotoViewer(items: items, initialIndex: index),
      ),
    );
  }
}

/// Uma foto por página, com deslize para comparar datas da mesma
/// categoria. É a "comparação lado a lado" na prática, sem tela extra.
class _PhotoViewer extends StatefulWidget {
  const _PhotoViewer({required this.items, required this.initialIndex});

  final List<ProgressPhotoEntity> items;
  final int initialIndex;

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late final PageController _controller =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.items[_index];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(DateFormatter.shortDate(photo.takenAt)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_index + 1} / ${widget.items.length}',
                style: AppTextStyles.caption,
              ),
            ),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.items.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) => InteractiveViewer(
          child: Center(child: _PhotoImage(url: widget.items[i].storageUrl)),
        ),
      ),
      bottomNavigationBar: photo.weightAtTimeKg == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  '${photo.weightAtTimeKg!.toStringAsFixed(1)} kg ese día',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMuted,
                ),
              ),
            ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.photo, required this.onTap});

  final ProgressPhotoEntity photo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _PhotoImage(url: photo.thumbnailUrl),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                color: Colors.black.withValues(alpha: 0.45),
                child: Text(
                  DateFormatter.shortDate(photo.takenAt),
                  style: AppTextStyles.caption.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Desenha a foto venha ela do Storage (URL https) ou do preview sem
/// Firebase (data URI com os bytes embutidos).
class _PhotoImage extends StatelessWidget {
  const _PhotoImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.startsWith('data:')) {
      final data = Uri.tryParse(url)?.data;
      if (data == null) return const _Broken();
      return Image.memory(data.contentAsBytes(), fit: BoxFit.cover);
    }
    if (url.isEmpty) return const _Broken();
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => const ColoredBox(color: AppColors.surfaceElevated),
      errorWidget: (_, __, ___) => const _Broken(),
    );
  }
}

class _Broken extends StatelessWidget {
  const _Broken();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.surfaceElevated,
      child: Icon(Icons.broken_image_outlined, color: AppColors.textSecondary),
    );
  }
}

extension on ProgressPhotoCategory {
  String get label => switch (this) {
        ProgressPhotoCategory.frente => 'Frente',
        ProgressPhotoCategory.costas => 'Espalda',
        ProgressPhotoCategory.perfil => 'Perfil',
      };

  IconData get icon => switch (this) {
        ProgressPhotoCategory.frente => Icons.accessibility_new,
        ProgressPhotoCategory.costas => Icons.flip,
        ProgressPhotoCategory.perfil => Icons.rotate_90_degrees_ccw,
      };
}
