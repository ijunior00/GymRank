import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/core/l10n/labels_es.dart';
import 'package:gymrank/core/theme/app_colors.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';
import 'package:gymrank/features/checkin/domain/checkin_qr.dart';
import 'package:gymrank/features/checkin/domain/entities/checkin_location.dart';
import 'package:gymrank/features/checkin/presentation/controllers/checkin_providers.dart';

/// Check-in presencial. Dois caminhos:
///
/// - **Escanear** com a câmera do app: o QR rotativo da tela da coach ou
///   o QR impresso da academia.
/// - **Chegar por link** ([initialPayload]): a aluna escaneou o QR impresso
///   com a câmera do celular e o site abriu em `/checkin?c=…`. Aqui ela só
///   confirma.
///
/// O QR impresso exige a localização do celular; o servidor confere a
/// distância até a academia (ver functions/src/checkin/validateCheckIn.ts).
class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({super.key, this.initialPayload});

  final String? initialPayload;

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  bool _processing = false;
  String _status = '';

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null) return;
    await _submit(code);
  }

  Future<void> _submit(String code) async {
    setState(() {
      _processing = true;
      _status = 'Validando check-in...';
    });

    final needsPosition = CheckInQr.isLocationPayload(code);
    CheckInPosition? position;
    if (needsPosition) {
      setState(() => _status = 'Confirmando tu ubicación...');
      final located = await ref.read(positionSourceProvider).current();
      if (!mounted) return;
      final failure = located.failureOrNull;
      if (failure != null) {
        _fail(failure.labelEs);
        return;
      }
      position = located.dataOrNull;
    }

    final result = await ref
        .read(checkInRepositoryProvider)
        .submitQrPayload(code, position: position);
    if (!mounted) return;

    result.when(
      success: (checkIn) {
        final where = checkIn.locationName == null ? '' : ' en ${checkIn.locationName}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              checkIn.xpGranted > 0
                  ? '¡Check-in listo$where! +${checkIn.xpGranted} XP'
                  : '¡Check-in listo$where! (hoy ya sumaste el XP de check-in)',
            ),
          ),
        );
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      },
      failure: (failure) => _fail(failure.labelEs),
    );
  }

  void _fail(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 6)),
    );
    setState(() {
      _processing = false;
      _status = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final payload = widget.initialPayload;
    if (payload != null && CheckInQr.isLocationPayload(payload)) {
      return _ConfirmScreen(
        processing: _processing,
        status: _status,
        onConfirm: () => _submit(payload),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Check-in')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(onDetect: _onDetect),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _processing
                    ? _status
                    : 'Apunta la cámara al código QR de tu coach o de la academia',
                textAlign: TextAlign.center,
                style: AppTextStyles.body,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chegou pelo link do QR impresso: nada de câmera, só confirmar (o toque
/// também é o momento certo de pedir a permissão de localização).
class _ConfirmScreen extends StatelessWidget {
  const _ConfirmScreen({
    required this.processing,
    required this.status,
    required this.onConfirm,
  });

  final bool processing;
  final String status;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check-in')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.place_outlined,
                    size: 44, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              const Text('Check-in en la academia', style: AppTextStyles.headline),
              const SizedBox(height: 8),
              const Text(
                'Vamos a confirmar que estás ahí con la ubicación de tu '
                'celular. Acepta el permiso cuando te lo pida.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMuted,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: processing ? null : onConfirm,
                  icon: processing
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(processing ? status : 'Confirmar check-in'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: processing ? null : () => context.go('/home'),
                child: const Text('Ahora no'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
