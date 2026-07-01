import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:gymrank/core/theme/app_colors.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';
import 'package:gymrank/features/checkin/presentation/controllers/checkin_providers.dart';

/// Escaneia o QR Code exclusivo da academia e envia para validação no
/// backend (evita fraude via token rotativo, ver
/// functions/src/checkin/validateCheckIn.ts).
class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({super.key});

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  bool _processing = false;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null) return;

    setState(() => _processing = true);
    final result = await ref.read(checkInRepositoryProvider).submitQrPayload(code);
    if (!mounted) return;

    result.when(
      success: (checkIn) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Check-in confirmado! +${checkIn.xpGranted} XP')),
        );
        Navigator.of(context).pop();
      },
      failure: (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.toString())),
        );
        setState(() => _processing = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    ? 'Validando check-in...'
                    : 'Aponte a câmera para o QR Code da academia',
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
