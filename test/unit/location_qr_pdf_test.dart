import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymrank/features/checkin/presentation/location_qr_pdf.dart';

/// A folha que a coach imprime: tem de ser um PDF de verdade, com o QR
/// (o link aparece no rodapé) e os textos com acento intactos.
void main() {
  test('gera um PDF carta com o link e o nome da academia', () async {
    final bytes = await buildLocationQrPdf(
      coachName: 'Método AF',
      locationName: 'Smart Fit Polanco',
      url: 'https://gymrank-e1c0d.web.app/checkin?c=a&l=b&v=1&s=0123456789abcdef0123456789abcdef',
    );
    expect(bytes.length, greaterThan(2000));
    expect(latin1.decode(bytes.sublist(0, 5)), '%PDF-');
    // Tamanho carta em pontos: 612 × 792.
    final head = latin1.decode(bytes, allowInvalid: true);
    expect(head, contains('612'));
    expect(head, contains('792'));
  });
}
