import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymrank/core/utils/load_error_text.dart';

/// O que a treinadora lê quando uma lista não carrega. Cada caso aqui é um
/// erro que já apareceu de verdade na tela dela como texto técnico cru.
void main() {
  FirebaseException firestore(String code, [String? message]) =>
      FirebaseException(plugin: 'cloud_firestore', code: code, message: message);

  test('índice em construção vira "espera uns minutos"', () {
    final text = describeLoadError(firestore(
      'failed-precondition',
      'The query requires an index. That index is currently building and '
          'cannot be used yet. See its status here: https://console...',
    ));
    expect(text, contains('índice en construcción'));
    expect(text, isNot(contains('https://')));
  });

  test('permissão negada explica e dá a pista da causa mais comum', () {
    final text = describeLoadError(firestore('permission-denied', 'Missing or insufficient permissions.'));
    expect(text, contains('no tiene permiso'));
    expect(text, contains('vinculado a la comunidad'));
  });

  test('sem conexão fala de internet, não de gRPC', () {
    expect(describeLoadError(firestore('unavailable')), contains('internet'));
    expect(describeLoadError(firestore('deadline-exceeded')), contains('internet'));
  });

  test('erro que não é do Firebase ganha uma frase genérica, nunca o toString', () {
    final text = describeLoadError(StateError('boom'));
    expect(text, 'No pudimos cargar esta información.');
  });
}
