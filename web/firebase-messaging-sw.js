// Service worker das notificações no web. O plugin firebase_messaging o
// procura neste caminho exato (/firebase-messaging-sw.js) e o registra
// sozinho — sem este arquivo NÃO existe push no navegador, e no iPhone
// nem instalado na tela de início.
//
// COMO ATIVAR (uma vez, depois do `flutterfire configure`):
//
//   1. Abra o lib/firebase_options.dart gerado e copie o bloco
//      `static const FirebaseOptions web = ...`.
//   2. Preencha FIREBASE_CONFIG abaixo com esses mesmos valores.
//   3. No console do Firebase → Configurações do projeto → Cloud
//      Messaging → "Certificados push da Web" → gere o par de chaves e
//      passe a chave pública no build:
//        flutter build web --release --dart-define=FCM_VAPID_KEY=<chave>
//
// Estes valores NÃO são segredo: a config web do Firebase é pública por
// natureza (quem protege os dados são as regras do Firestore/Storage).
// Pode versionar sem medo.
//
// Enquanto os campos estiverem com os placeholders, o service worker não
// inicializa nada e o app segue funcionando, só sem push no navegador.

importScripts('https://www.gstatic.com/firebasejs/11.9.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/11.9.1/firebase-messaging-compat.js');

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

if (isConfigured) {
  firebase.initializeApp(FIREBASE_CONFIG);
  const messaging = firebase.messaging();

  // Mensagem recebida com o app fechado ou em segundo plano. A Cloud
  // Function `dispatchNotification` manda `notification` + `data.deepLink`;
  // o navegador já desenha a notificação sozinho a partir de
  // `notification`, então aqui só cuidamos do toque.
  self.addEventListener('notificationclick', (event) => {
    event.notification.close();

    const deepLink = event.notification?.data?.FCM_MSG?.data?.deepLink
      || event.notification?.data?.deepLink;
    const target = typeof deepLink === 'string' && deepLink.startsWith('/')
      ? deepLink
      : '/';

    event.waitUntil(
      self.clients
        .matchAll({ type: 'window', includeUncontrolled: true })
        .then((clients) => {
          for (const client of clients) {
            if ('focus' in client) {
              client.navigate(new URL(target, self.location.origin).href);
              return client.focus();
            }
          }
          return self.clients.openWindow(target);
        }),
    );
  });

  // Silencia o aviso do SDK de que não há handler; a notificação em si o
  // navegador já mostra a partir do bloco `notification` da mensagem.
  messaging.onBackgroundMessage(() => {});
} else {
  console.info(
    'AnahiFitness: firebase-messaging-sw.js sin configurar, las notificaciones web están apagadas.',
  );
}
