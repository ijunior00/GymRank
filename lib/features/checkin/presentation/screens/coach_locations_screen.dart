import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/core/l10n/labels_es.dart';
import 'package:gymrank/core/theme/app_colors.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';
import 'package:gymrank/core/utils/load_error_text.dart';
import 'package:gymrank/features/checkin/domain/entities/checkin_location.dart';
import 'package:gymrank/features/checkin/presentation/controllers/checkin_providers.dart';
import 'package:gymrank/features/checkin/presentation/location_qr_pdf.dart';
import 'package:gymrank/features/checkin/presentation/widgets/location_form_sheet.dart';
import 'package:gymrank/features/coach_panel/presentation/controllers/coach_panel_providers.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Academias onde a coach atende, cada uma com seu QR para imprimir.
class CoachLocationsScreen extends ConsumerWidget {
  const CoachLocationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locations = ref.watch(coachLocationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('QR de check-in')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showLocationFormSheet(context),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Nueva academia'),
      ),
      body: locations.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(describeLoadError(e))),
        data: (list) {
          if (list.isEmpty) return const _EmptyState();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              const Text(
                'Imprime el QR de cada academia y pégalo en la recepción. La '
                'alumna lo escanea, el app confirma que está ahí por la '
                'ubicación del celular y suma el check-in.',
                style: AppTextStyles.bodyMuted,
              ),
              const SizedBox(height: 12),
              for (final l in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _LocationTile(location: l),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.qr_code_2, size: 56, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            const Text('Ninguna academia todavía', style: AppTextStyles.title),
            const SizedBox(height: 8),
            const Text(
              'Registra la academia estando ahí (usamos la ubicación de tu '
              'celular), imprime el QR y pégalo en la recepción.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMuted,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => showLocationFormSheet(context),
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Registrar academia'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationTile extends ConsumerWidget {
  const _LocationTile({required this.location});

  final CheckInLocation location;

  Future<void> _rotate(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Generar un QR nuevo?'),
        content: const Text(
          'El QR impreso que está en la academia deja de funcionar. Úsalo si '
          'sospechas que alguien lo fotografió para hacer check-in desde casa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Generar nuevo'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final result = await ref
        .read(checkInRepositoryProvider)
        .saveLocation(location.copyWith(qrVersion: location.qrVersion + 1));
    if (!context.mounted) return;
    final failure = result.failureOrNull;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failure == null
              ? 'Listo. Imprime el QR nuevo y cambia el de la recepción.'
              : 'No se pudo: ${failure.labelEs}',
        ),
      ),
    );
  }

  Future<void> _toggleActive(BuildContext context, WidgetRef ref) async {
    final result = await ref
        .read(checkInRepositoryProvider)
        .saveLocation(location.copyWith(active: !location.active));
    if (!context.mounted) return;
    final failure = result.failureOrNull;
    if (failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo: ${failure.labelEs}')),
      );
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Eliminar ${location.name}?'),
        content: const Text('El QR impreso deja de funcionar de inmediato.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final result = await ref.read(checkInRepositoryProvider).deleteLocation(
          coachId: location.coachId,
          locationId: location.id,
        );
    if (!context.mounted) return;
    final failure = result.failureOrNull;
    if (failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo: ${failure.labelEs}')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = location;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(l.name,
                      style: AppTextStyles.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                if (!l.active)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text('Desactivada',
                        style: AppTextStyles.caption.copyWith(color: AppColors.warning)),
                  ),
                PopupMenuButton<String>(
                  tooltip: 'Más',
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        showLocationFormSheet(context, initial: l);
                      case 'rotate':
                        _rotate(context, ref);
                      case 'toggle':
                        _toggleActive(context, ref);
                      case 'delete':
                        _delete(context, ref);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Editar')),
                    const PopupMenuItem(value: 'rotate', child: Text('Generar QR nuevo')),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(l.active ? 'Desactivar' : 'Activar'),
                    ),
                    const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                  ],
                ),
              ],
            ),
            if ((l.address ?? '').isNotEmpty)
              Text(l.address!, style: AppTextStyles.bodyMuted, maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(
              'Radio ${l.radiusM.round()} m · QR versión ${l.qrVersion}',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: () => showLocationQrDialog(context, l),
                icon: const Icon(Icons.qr_code_2),
                label: const Text('Ver e imprimir QR'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mostra o QR da academia com os botões de imprimir e baixar o PDF.
Future<void> showLocationQrDialog(BuildContext context, CheckInLocation location) {
  return showDialog<void>(
    context: context,
    builder: (_) => _LocationQrDialog(location: location),
  );
}

class _LocationQrDialog extends ConsumerWidget {
  const _LocationQrDialog({required this.location});

  final CheckInLocation location;

  Future<void> _print(BuildContext context, WidgetRef ref, String url) async {
    final coachName = ref.read(currentCoachProvider).valueOrNull?.name ?? 'AnahiFitness';
    final bytes = await buildLocationQrPdf(
      coachName: coachName,
      locationName: location.name,
      url: url,
    );
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'checkin-${location.name}.pdf',
    );
  }

  Future<void> _download(BuildContext context, WidgetRef ref, String url) async {
    final coachName = ref.read(currentCoachProvider).valueOrNull?.name ?? 'AnahiFitness';
    final bytes = await buildLocationQrPdf(
      coachName: coachName,
      locationName: location.name,
      url: url,
    );
    await Printing.sharePdf(bytes: bytes, filename: 'checkin-${_slug(location.name)}.pdf');
  }

  static String _slug(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: Text(location.name),
      content: FutureBuilder(
        future: ref.read(checkInRepositoryProvider).issueLocationQr(location.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final result = snapshot.data!;
          final failure = result.failureOrNull;
          if (failure != null) {
            return Text('No se pudo generar el QR: ${failure.labelEs}');
          }
          final url = result.dataOrNull!;
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(data: url, size: 220),
                ),
                const SizedBox(height: 12),
                const Text(
                  'En pantalla sirve para probar. Para la recepción, '
                  'imprime el PDF: sale en tamaño carta con las instrucciones.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: () => _print(context, ref, url),
                      icon: const Icon(Icons.print),
                      label: const Text('Imprimir'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _download(context, ref, url),
                      icon: const Icon(Icons.download),
                      label: const Text('Descargar PDF'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
