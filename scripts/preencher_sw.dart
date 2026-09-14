// Preenche o web/firebase-messaging-sw.js com a configuração web do
// Firebase, copiada do lib/firebase_options.dart que o
// `flutterfire configure` gerou. Sem isso não existe push no navegador.
//
// Como rodar (no Terminal, na pasta do projeto):
//
//   dart run scripts/preencher_sw.dart
//
// Pode rodar quantas vezes quiser: se nada mudou, não mexe no arquivo.
// O `firebase deploy --only hosting` já roda isto sozinho (ver
// firebase.json → hosting → predeploy).
//
// Estes valores NÃO são segredo: a configuração web do Firebase é pública
// por natureza; quem protege os dados são as regras do Firestore/Storage.
import 'dart:io';

const optionsPath = 'lib/firebase_options.dart';
const serviceWorkerPath = 'web/firebase-messaging-sw.js';

/// Campos que o service worker precisa. `authDomain` e `measurementId`
/// não entram: o SW só recebe push, não autentica nem mede nada.
const requiredKeys = [
  'apiKey',
  'appId',
  'messagingSenderId',
  'projectId',
  'storageBucket',
];

void main() {
  final optionsFile = File(optionsPath);
  if (!optionsFile.existsSync()) {
    stderr.writeln(
      'Não achei $optionsPath.\n'
      'Ele é gerado pelo `flutterfire configure` — veja docs/setup-firebase.md.',
    );
    exit(1);
  }
  final swFile = File(serviceWorkerPath);
  if (!swFile.existsSync()) {
    stderr.writeln('Não achei $serviceWorkerPath.');
    exit(1);
  }

  final Map<String, String> config;
  try {
    config = extractWebOptions(optionsFile.readAsStringSync());
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    exit(1);
  }

  final before = swFile.readAsStringSync();
  final after = fillServiceWorker(before, config);
  if (after == before) {
    stdout.writeln('$serviceWorkerPath já estava preenchido. Nada a fazer.');
    return;
  }
  swFile.writeAsStringSync(after);
  stdout.writeln(
    'Pronto: $serviceWorkerPath preenchido com o projeto ${config['projectId']}.',
  );
}

/// Lê o bloco `static const FirebaseOptions web = FirebaseOptions(...)`
/// e devolve os campos exigidos pelo service worker.
Map<String, String> extractWebOptions(String firebaseOptionsSource) {
  final block = RegExp(
    r'static\s+const\s+FirebaseOptions\s+web\s*=\s*FirebaseOptions\(([\s\S]*?)\);',
  ).firstMatch(firebaseOptionsSource);
  if (block == null) {
    throw const FormatException(
      'O $optionsPath não tem a configuração web.\n'
      'Rode de novo: flutterfire configure --platforms=android,ios,web',
    );
  }
  final body = block.group(1)!;
  final field = RegExp(r"(\w+)\s*:\s*'([^']*)'");
  final found = {
    for (final m in field.allMatches(body)) m.group(1)!: m.group(2)!,
  };
  final missing = requiredKeys.where((k) => (found[k] ?? '').isEmpty).toList();
  if (missing.isNotEmpty) {
    throw FormatException(
      'Faltam campos na configuração web do $optionsPath: ${missing.join(', ')}',
    );
  }
  return {for (final k in requiredKeys) k: found[k]!};
}

/// Troca só o objeto `FIREBASE_CONFIG = { ... }` do service worker,
/// preservando todo o resto do arquivo (comentários e o código de clique).
String fillServiceWorker(String serviceWorkerSource, Map<String, String> config) {
  final target = RegExp(r'const FIREBASE_CONFIG = \{[\s\S]*?\};');
  if (!target.hasMatch(serviceWorkerSource)) {
    throw const FormatException(
      'Não achei `const FIREBASE_CONFIG = { ... };` em $serviceWorkerPath.',
    );
  }
  final lines = [
    for (final k in requiredKeys) "  $k: '${config[k]}',",
  ].join('\n');
  return serviceWorkerSource.replaceFirst(
    target,
    'const FIREBASE_CONFIG = {\n$lines\n};',
  );
}
