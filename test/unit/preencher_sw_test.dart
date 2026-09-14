import 'package:flutter_test/flutter_test.dart';

import '../../scripts/preencher_sw.dart';

/// O script que copia a configuração web do Firebase para o service worker
/// do push. O formato de entrada é o que o `flutterfire configure` gera;
/// o de saída, o que o `web/firebase-messaging-sw.js` do repo espera.
void main() {
  const firebaseOptions = '''
class DefaultFirebaseOptions {
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyWEBKEY',
    appId: '1:123456:web:abc',
    messagingSenderId: '123456',
    projectId: 'gymrank-e1c0d',
    authDomain: 'gymrank-e1c0d.firebaseapp.com',
    storageBucket: 'gymrank-e1c0d.firebasestorage.app',
    measurementId: 'G-ABC',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyANDROIDKEY',
    appId: '1:123456:android:def',
    messagingSenderId: '123456',
    projectId: 'gymrank-e1c0d',
    storageBucket: 'gymrank-e1c0d.firebasestorage.app',
  );
}
''';

  const serviceWorker = '''
// comentário de cima
importScripts('https://www.gstatic.com/firebasejs/11.9.1/firebase-app-compat.js');

const FIREBASE_CONFIG = {
  apiKey: 'PENDIENTE',
  appId: 'PENDIENTE',
  messagingSenderId: 'PENDIENTE',
  projectId: 'PENDIENTE',
  storageBucket: 'PENDIENTE',
};

const isConfigured = Object.values(FIREBASE_CONFIG).every(
  (value) => value && value !== 'PENDIENTE',
);
''';

  test('pega o bloco web, não o do Android', () {
    final config = extractWebOptions(firebaseOptions);
    expect(config, {
      'apiKey': 'AIzaSyWEBKEY',
      'appId': '1:123456:web:abc',
      'messagingSenderId': '123456',
      'projectId': 'gymrank-e1c0d',
      'storageBucket': 'gymrank-e1c0d.firebasestorage.app',
    });
  });

  test('sem bloco web, explica que falta rodar o flutterfire com web', () {
    const soAndroid = '''
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'x', appId: 'y', messagingSenderId: 'z', projectId: 'p',
  );
''';
    expect(
      () => extractWebOptions(soAndroid),
      throwsA(isA<FormatException>().having(
        (e) => e.message,
        'message',
        contains('--platforms=android,ios,web'),
      )),
    );
  });

  test('troca só o FIREBASE_CONFIG e preserva o resto do arquivo', () {
    final out = fillServiceWorker(serviceWorker, extractWebOptions(firebaseOptions));
    final configBlock = RegExp(r'const FIREBASE_CONFIG = \{[\s\S]*?\};')
        .firstMatch(out)!
        .group(0)!;
    expect(configBlock, contains("projectId: 'gymrank-e1c0d',"));
    expect(configBlock, contains("apiKey: 'AIzaSyWEBKEY',"));
    expect(configBlock, isNot(contains('PENDIENTE')));
    expect(configBlock, isNot(contains('authDomain'))); // o SW não precisa
    expect(out, contains('// comentário de cima'));
    expect(out, contains("value !== 'PENDIENTE'")); // a checagem continua lá
  });

  test('rodar duas vezes não muda nada', () {
    final config = extractWebOptions(firebaseOptions);
    final once = fillServiceWorker(serviceWorker, config);
    expect(fillServiceWorker(once, config), once);
  });
}
