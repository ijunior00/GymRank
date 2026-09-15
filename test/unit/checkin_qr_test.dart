import 'package:flutter_test/flutter_test.dart';
import 'package:gymrank/features/checkin/domain/checkin_qr.dart';

/// O app precisa distinguir o QR impresso da academia (pede GPS) do QR
/// rotativo da tela da coach (não pede), venha de onde vier: câmera do
/// app, câmera do celular (link) ou o roteador (`/checkin?...`).
void main() {
  const sig = '0123456789abcdef0123456789abcdef';
  const url = 'https://gymrank-e1c0d.web.app/checkin?c=coach1&l=gym1&v=2&s=$sig';

  test('URL completa do QR impresso é de academia', () {
    expect(CheckInQr.isLocationPayload(url), isTrue);
    expect(CheckInQr.queryOf(url), 'c=coach1&l=gym1&v=2&s=$sig');
  });

  test('caminho /checkin?… e só a query também são', () {
    expect(CheckInQr.isLocationPayload('/checkin?c=coach1&l=gym1&v=2&s=$sig'), isTrue);
    expect(CheckInQr.isLocationPayload('c=coach1&l=gym1&v=2&s=$sig'), isTrue);
  });

  test('QR rotativo da coach NÃO é de academia', () {
    expect(CheckInQr.isLocationPayload('coach1.1757900000000.abcdef0123'), isFalse);
  });

  test('lixo não derruba o app', () {
    expect(CheckInQr.isLocationPayload(''), isFalse);
    expect(CheckInQr.isLocationPayload('%%%'), isFalse);
    expect(CheckInQr.isLocationPayload('https://outro.site/x?c=1'), isFalse);
  });
}
