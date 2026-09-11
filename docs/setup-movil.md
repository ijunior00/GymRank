# Setup móvel: iOS e Android

Os projetos nativos `android/` e `ios/` estão versionados e configurados.
Este documento é o roteiro para sair do zero até um app instalado no
celular da treinadora e das alunas.

> **Identificador do app:** `com.anahifitness.app` nas duas lojas. Ele é a
> identidade do app na App Store, no Google Play e no Firebase. Mudar
> depois significa começar de novo em todos esses lugares — se for para
> trocar (por exemplo, para o domínio dela), troque **agora**, antes de
> criar o projeto Firebase.

## 1. Primeira rodada, comum às duas plataformas

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

Os arquivos gerados (`*.g.dart`, `*.freezed.dart`) não são versionados,
então esse segundo comando é obrigatório em qualquer máquina nova.

## 2. Firebase

`lib/firebase_options.dart`, `android/app/google-services.json` e
`ios/Runner/GoogleService-Info.plist` **não** estão no repositório (são
por projeto e um deles carrega chaves). Os três nascem de um comando só:

```bash
dart pub global activate flutterfire_cli
flutterfire configure \
  --project=gymrank-e1c0d \
  --platforms=android,ios \
  --android-package-name=com.anahifitness.app \
  --ios-bundle-id=com.anahifitness.app
```

Isso também adiciona o plugin `com.google.gms.google-services` ao Gradle.
Ele **não** está declarado em `android/app/build.gradle.kts` de
propósito: sem o `google-services.json` ao lado, o plugin quebra a
compilação. Deixe o `flutterfire` colocar os dois juntos.

No console do Firebase, ainda é preciso ligar à mão:

- **Authentication** → Correo/contraseña, Google e Apple.
- **Cloud Firestore** e **Storage** na região `nam5`
  (ou a mais próxima do México).
- **Cloud Messaging** → para iOS, subir a chave de APNs (ver §4).
- A chave do leitor de PDF/Word:
  `firebase functions:secrets:set ANTHROPIC_API_KEY`.

Depois:

```bash
firebase deploy --only firestore:rules,firestore:indexes,storage:rules,functions
```

## 3. Android

Já configurado no repositório:

| Item | Valor | Onde |
|---|---|---|
| `applicationId` / `namespace` | `com.anahifitness.app` | `android/app/build.gradle.kts` |
| `minSdk` | 24 (default do Flutter; o piso dos plugins é 23, do Firebase) | idem |
| `compileSdk` / `targetSdk` | 36 | idem |
| Nome na tela inicial | GymRank | `AndroidManifest.xml` |
| `INTERNET` | declarado no manifesto principal | idem |
| `POST_NOTIFICATIONS` | declarado (Android 13+) | idem |
| Orientação | só retrato | idem |
| Ícone de notificação | `ic_stat_notification` + cor violeta | idem + `res/drawable`, `res/values/colors.xml` |
| Splash | `#0B0710`, sem flash branco | `res/drawable/launch_background.xml`, `res/values*/styles.xml` |

A permissão de câmera (QR e fotos de progresso) vem do próprio
`mobile_scanner`/`image_picker` pela fusão de manifestos — não precisa
declarar aqui.

### Rodar

```bash
flutter run                       # debug, no celular conectado
flutter build apk --debug         # APK de teste
```

### Assinar o release

O `build.gradle.kts` procura `android/key.properties`. Se o arquivo não
existir, assina com as chaves de debug (para `flutter run --release`
funcionar em qualquer máquina). Para publicar na Play Store:

```bash
keytool -genkey -v -keystore ~/gymrank-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

E `android/key.properties` (já ignorado pelo git — **nunca** versione
isso nem o `.jks`):

```properties
storePassword=…
keyPassword=…
keyAlias=upload
storeFile=/caminho/absoluto/gymrank-upload.jks
```

Depois:

```bash
flutter build appbundle --release   # o .aab que a Play Store aceita
```

Guarde o `.jks` e as senhas fora do computador dela. Perder a chave de
upload significa não conseguir mais atualizar o app publicado.

## 4. iOS

Precisa de um Mac com Xcode e de uma conta paga do Apple Developer
Program (99 USD/ano). Não dá para compilar iOS no Linux nem no Windows.

Já configurado no repositório:

| Item | Valor | Onde |
|---|---|---|
| Bundle ID | `com.anahifitness.app` | `ios/Runner.xcodeproj/project.pbxproj` |
| Nome na tela inicial | GymRank | `Info.plist` (`CFBundleDisplayName`) |
| iOS mínimo | 13.0 (piso do SDK do Firebase) | pbxproj |
| Orientação | só retrato | `Info.plist` |
| Idioma | es-MX | `Info.plist` (`CFBundleLocalizations`) |
| Textos de permissão | câmera e galeria, em espanhol | `Info.plist` |
| Export compliance | `ITSAppUsesNonExemptEncryption = false` | `Info.plist` |
| Splash | `#0B0710` | `Base.lproj/LaunchScreen.storyboard` |
| Capacidades | push + Sign in with Apple | `Runner/Runner.entitlements` |

### As duas capacidades do `Runner.entitlements`

`ios/Runner/Runner.entitlements` já está ligado ao target nas três
configurações (Debug, Profile, Release). As duas capacidades que ele
declara **precisam estar ativas no App ID** ou a assinatura falha:

1. No [Apple Developer](https://developer.apple.com/account/resources/identifiers),
   no identificador `com.anahifitness.app`, marque **Push Notifications** e
   **Sign in with Apple**. Com assinatura automática e uma conta paga, o
   Xcode faz isso sozinho ao abrir o projeto.
2. Em Push Notifications, gere uma **chave APNs (.p8)** e suba no
   Firebase → Project settings → Cloud Messaging → Apple app configuration.
   Sem isso o app compila mas nunca recebe notificação.

O lado Dart já está feito: `PushRegistration`
(`lib/features/notifications/presentation/controllers/push_registration.dart`)
pede a permissão ao entrar na conta, espera o token do APNs no iOS,
grava o token em `users/{uid}/fcmTokens/{token}` — de onde a Cloud
Function `dispatchNotification` lê —, acompanha a renovação, apaga o
token no logout e navega para o `deepLink` quando alguém toca na
notificação. Não é preciso chamar nada disso à mão.

Se quiser só rodar num iPhone com uma conta gratuita (personal team),
Sign in with Apple não está disponível: comente a chave
`com.apple.developer.applesignin` no `Runner.entitlements` enquanto
testa. Não suba assim para a App Store — a Apple exige Sign in with
Apple quando o app oferece login com Google.

### Rodar e publicar

```bash
flutter run                      # com o iPhone conectado
open ios/Runner.xcworkspace      # sempre o .xcworkspace, nunca o .xcodeproj
flutter build ipa --release
```

O projeto usa Swift Package Manager para os plugins que suportam, e o
Flutter gera o `Podfile` sozinho na primeira compilação para os que
ainda dependem de CocoaPods. Não crie o `Podfile` à mão.

## 5. Ícones do app

Os ícones ainda são os padrão do Flutter. Quando a treinadora tiver o
logo (PNG quadrado, 1024×1024, sem cantos arredondados nem
transparência):

```bash
# dev_dependencies: flutter_launcher_icons
dart run flutter_launcher_icons
```

Fundo sugerido: `#0B0710`; marca em `#A855F7` (a paleta do app está em
`lib/core/theme/app_colors.dart`).

## 6. Testes

```bash
flutter test
```

Cobre as regras puras: curva de níveis, 1RM estimado (Epley), o
planejador do "Entrenamiento de hoy" e a leitura do conteúdo dos planos
(que recebe a saída do parser de PDF/Word, ou seja, entrada não
confiável).

## 7. O que fica fora do repositório

Nunca versionar, tudo já no `.gitignore`:

```
lib/firebase_options.dart
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
android/key.properties
*.jks / *.keystore
.firebaserc
```
