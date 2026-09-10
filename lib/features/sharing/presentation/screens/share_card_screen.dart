import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/core/theme/app_colors.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';
import 'package:gymrank/features/sharing/domain/entities/share_card.dart';
import 'package:gymrank/features/sharing/presentation/controllers/share_providers.dart';
import 'package:gymrank/features/sharing/presentation/widgets/share_card_view.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Pré-visualização do card e botão de compartilhar. A imagem sai em
/// 1080×1920 (Stories) capturando o [RepaintBoundary] a `pixelRatio: 3`.
Future<void> showShareCard(BuildContext context, ShareCardData data) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(builder: (_) => ShareCardScreen(data: data)),
  );
}

class ShareCardScreen extends ConsumerStatefulWidget {
  const ShareCardScreen({required this.data, super.key});

  final ShareCardData data;

  @override
  ConsumerState<ShareCardScreen> createState() => _ShareCardScreenState();
}

class _ShareCardScreenState extends ConsumerState<ShareCardScreen> {
  final _cardKey = GlobalKey();
  bool _sharing = false;

  Future<Uint8List?> _capture() async {
    final boundary =
        _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data?.buffer.asUint8List();
  }

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      final bytes = await _capture();
      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo generar la imagen.')),
          );
        }
        return;
      }

      // No celular o share sheet quer un archivo; en web se comparte el
      // propio arreglo de bytes.
      final XFile file;
      if (kIsWeb) {
        file = XFile.fromData(
          bytes,
          mimeType: 'image/png',
          name: widget.data.fileName,
        );
      } else {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/${widget.data.fileName}';
        file = XFile(path);
        await XFile.fromData(bytes, mimeType: 'image/png').saveTo(path);
      }

      await SharePlus.instance.share(
        ShareParams(files: [file], text: widget.data.shareText),
      );
      await ref.read(shareRepositoryProvider).recordShare(widget.data.kind);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compartir')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: _sharing ? null : _share,
                icon: _sharing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.ios_share),
                label: Text(_sharing ? 'Preparando…' : 'Compartir'),
              ),
              const SizedBox(height: 6),
              Text(
                'Se comparte en formato de historia (9:16).',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: FittedBox(
            child: RepaintBoundary(
              key: _cardKey,
              child: ShareCardView(data: widget.data),
            ),
          ),
        ),
      ),
    );
  }
}
