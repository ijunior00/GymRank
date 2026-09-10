import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/core/di/firebase_providers.dart';
import 'package:gymrank/core/router/app_router.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';
import 'package:gymrank/features/notifications/presentation/controllers/notification_providers.dart';

/// Liga o push de verdade: pede permissão, registra o token do aparelho
/// em `users/{uid}/fcmTokens/{token}` (de onde a Cloud Function
/// `dispatchNotification` lê) e abre a tela certa quando o aluno toca na
/// notificação.
///
/// Sem isto o app compila e roda, mas nunca recebe uma notificação: no
/// iOS porque ninguém pediu permissão, no Android 13+ pelo mesmo motivo,
/// e nos dois porque não haveria token registrado.
///
/// O ciclo de vida acompanha a sessão: entra alguém, registra; sai,
/// apaga o token para o aparelho não continuar recebendo os pushes de
/// quem saiu.
class PushRegistration {
  PushRegistration(this._ref) {
    _authSubscription =
        _ref.listen<AsyncValue<String?>>(authStateProvider, (previous, next) {
      final previousUid = previous?.valueOrNull;
      final uid = next.valueOrNull;
      if (previousUid == uid) return;
      if (previousUid != null) unawaited(_unregister(previousUid));
      if (uid != null) unawaited(_register(uid));
    }, fireImmediately: true);
  }

  /// Sem nenhuma chamada ao Firebase: é o que o preview do Render usa,
  /// porque lá o app roda sem Firebase inicializado.
  PushRegistration.disabled(this._ref);

  final Ref _ref;
  ProviderSubscription<AsyncValue<String?>>? _authSubscription;

  StreamSubscription<String>? _tokenRefresh;
  StreamSubscription<RemoteMessage>? _opened;
  String? _currentToken;
  String? _currentUserId;

  FirebaseMessaging get _messaging => _ref.read(firebaseMessagingProvider);

  Future<void> _register(String userId) async {
    _currentUserId = userId;

    final settings = await _messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      // A pessoa pode ligar depois nos ajustes do sistema; nada a fazer
      // aqui além de não insistir.
      return;
    }

    // No iOS o token do FCM só existe depois que o APNs devolve o dele.
    if (defaultTargetPlatform == TargetPlatform.iOS && !kIsWeb) {
      if (await _waitForApnsToken() == null) return;
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    final token = await _messaging.getToken();
    if (token != null) await _save(userId, token);

    unawaited(_tokenRefresh?.cancel());
    _tokenRefresh = _messaging.onTokenRefresh.listen((refreshed) async {
      final uid = _currentUserId;
      if (uid == null) return;
      final old = _currentToken;
      if (old != null && old != refreshed) {
        await _ref
            .read(notificationRepositoryProvider)
            .removeDeviceToken(userId: uid, token: old);
      }
      await _save(uid, refreshed);
    });

    unawaited(_opened?.cancel());
    _opened = FirebaseMessaging.onMessageOpenedApp.listen(_openDeepLink);

    // App aberto a partir de uma notificação com o processo morto.
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _openDeepLink(initial);
  }

  Future<void> _save(String userId, String token) async {
    _currentToken = token;
    await _ref
        .read(notificationRepositoryProvider)
        .registerDeviceToken(userId: userId, token: token);
  }

  /// O APNs pode demorar alguns segundos a responder logo depois de
  /// conceder a permissão. Sem esperar, `getToken()` lança.
  Future<String?> _waitForApnsToken() async {
    for (var attempt = 0; attempt < 5; attempt++) {
      final apns = await _messaging.getAPNSToken();
      if (apns != null) return apns;
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    return null;
  }

  void _openDeepLink(RemoteMessage message) {
    final target = message.data['deepLink'];
    if (target is! String || target.isEmpty || !target.startsWith('/')) return;
    _ref.read(appRouterProvider).go(target);
  }

  /// Apaga o token **antes** do `signOut` — as regras do Firestore só
  /// deixam o dono escrever em `users/{uid}/fcmTokens`, então depois de
  /// sair já não dá. Chamado por `AuthController.signOut`.
  Future<void> releaseToken() async {
    final userId = _currentUserId;
    if (userId != null) await _unregister(userId);
  }

  Future<void> _unregister(String userId) async {
    await _tokenRefresh?.cancel();
    await _opened?.cancel();
    _tokenRefresh = null;
    _opened = null;

    final token = _currentToken;
    _currentToken = null;
    if (_currentUserId == userId) _currentUserId = null;
    if (token == null) return;

    // Best-effort: se chegou aqui já deslogado (sessão expirada, conta
    // removida), a regra recusa a escrita e o repositório devolve
    // Failure — o token some sozinho quando o FCM o invalidar.
    await _ref
        .read(notificationRepositoryProvider)
        .removeDeviceToken(userId: userId, token: token);
  }

  void dispose() {
    _authSubscription?.close();
    unawaited(_tokenRefresh?.cancel());
    unawaited(_opened?.cancel());
  }
}

/// Mantido vivo pelo app inteiro (ver `lib/main.dart`). Não existe no
/// preview do Render, que roda sem Firebase.
final pushRegistrationProvider = Provider<PushRegistration>((ref) {
  final registration = PushRegistration(ref);
  ref.onDispose(registration.dispose);
  return registration;
});
