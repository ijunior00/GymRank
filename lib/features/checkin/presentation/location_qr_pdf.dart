import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Folha carta para imprimir e colar na recepção da academia: marca da
/// coach, QR grande, nome do ponto e os três passos para a aluna.
Future<Uint8List> buildLocationQrPdf({
  required String coachName,
  required String locationName,
  required String url,
}) async {
  final doc = pw.Document(title: 'Check-in · $locationName', author: coachName);
  final purple = PdfColor.fromHex('#A855F7');
  final ink = PdfColor.fromHex('#1B1220');
  final muted = PdfColor.fromHex('#6B6275');

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.all(48),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            coachName,
            style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, color: ink),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'CHECK-IN',
            style: pw.TextStyle(
              fontSize: 40,
              fontWeight: pw.FontWeight.bold,
              color: purple,
              letterSpacing: 4,
            ),
          ),
          pw.SizedBox(height: 28),
          pw.Container(
            padding: const pw.EdgeInsets.all(18),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: purple, width: 3),
              borderRadius: pw.BorderRadius.circular(24),
            ),
            child: pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(errorCorrectLevel: pw.BarcodeQRCorrectionLevel.medium),
              data: url,
              width: 300,
              height: 300,
              drawText: false,
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            locationName,
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: ink),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 28),
          _step(1, 'Abre la cámara de tu celular o la app.', ink),
          _step(2, 'Escanea este código.', ink),
          _step(3, 'Permite la ubicación y confirma tu check-in.', ink),
          pw.Spacer(),
          pw.Text(
            'Cada check-in suma XP y cuenta para tus retos.',
            style: pw.TextStyle(fontSize: 12, color: muted),
          ),
          pw.SizedBox(height: 4),
          pw.Text(url, style: pw.TextStyle(fontSize: 8, color: muted)),
        ],
      ),
    ),
  );
  return doc.save();
}

pw.Widget _step(int n, String text, PdfColor ink) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 4),
    child: pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(
          width: 24,
          height: 24,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#A855F7'),
            shape: pw.BoxShape.circle,
          ),
          child: pw.Text(
            '$n',
            style: const pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Text(text, style: pw.TextStyle(fontSize: 15, color: ink)),
      ],
    ),
  );
}
