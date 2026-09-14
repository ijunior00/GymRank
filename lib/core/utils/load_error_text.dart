import 'package:firebase_core/firebase_core.dart';

/// Frase curta, em espanhol, para um erro de leitura do Firebase — o que
/// a treinadora ou a aluna consegue entender e, quando dá, resolver.
///
/// O texto técnico original continua útil para quem cuida do app; a tela
/// mostra os dois: esta frase em destaque e o original em letra miúda.
String describeLoadError(Object error) {
  if (error is FirebaseException) {
    final message = error.message ?? '';
    switch (error.code) {
      case 'failed-precondition':
        if (message.toLowerCase().contains('index')) {
          return 'El servidor todavía está preparando esta lista (índice en '
              'construcción). Suele tardar unos minutos; vuelve a entrar '
              'después.';
        }
        return 'El servidor no pudo atender esta consulta todavía. Intenta '
            'de nuevo en un momento.';
      case 'permission-denied':
        return 'Tu cuenta no tiene permiso para ver esto. Si eres la coach, '
            'revisa que tu perfil esté vinculado a la comunidad.';
      case 'unavailable':
      case 'deadline-exceeded':
        return 'Sin conexión con el servidor. Revisa tu internet e intenta '
            'de nuevo.';
      case 'unauthenticated':
        return 'Tu sesión expiró. Cierra sesión y vuelve a entrar.';
      case 'resource-exhausted':
        return 'El servidor está saturado. Intenta de nuevo en unos minutos.';
    }
  }
  return 'No pudimos cargar esta información.';
}
