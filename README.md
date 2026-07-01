# GymRank

Plataforma de gamificação e competição para academias (modelo B2B2C). O app
mobile é gratuito para alunos; academias assinam planos para gerenciar
desafios, campeonatos, rankings e retenção.

## Stack

- **Front-end:** Flutter, Material 3, Riverpod, GoRouter, Freezed, json_serializable
- **Backend:** Firebase (Auth, Firestore, Storage, Cloud Functions, Cloud
  Messaging, Analytics, Crashlytics, Remote Config)
- **Cloud Functions:** TypeScript (`functions/`)

## Arquitetura

Clean Architecture + Feature-First, com injeção de dependência via Riverpod.

```
lib/
  core/                     # infra transversal: tema, rotas, DI, erros, utils
    di/
    error/
    router/
    theme/
    utils/
  shared/                   # widgets e modelos compartilhados entre features
    widgets/
  features/
    auth/
    profile/
    body_measurement/
    progress_photo/
    workout/
    checkin/
    gamification/           # XP, níveis, conquistas, Gym Score, temporadas
    challenges/
    championships/
    rewards/
    rankings/
    social_feed/
    friendship/
    notifications/
    gym_admin/              # painel da academia
    coach_ai/
  main.dart
```

Cada feature segue três camadas:

```
features/<feature>/
  data/
    dtos/            # Firestore <-> Dart (json_serializable)
    repositories/     # implementações concretas (Firestore/Storage/Functions)
  domain/
    entities/          # modelos imutáveis (Freezed), sem dependência de Firebase
    repositories/       # contratos abstratos
    usecases/            # regras de negócio isoladas
  presentation/
    controllers/          # Riverpod Notifiers/AsyncNotifiers
    screens/
    widgets/
```

Regra de dependência: `presentation -> domain <- data`. O `domain` nunca
importa Firebase; `data` implementa os contratos do `domain`.

Veja `docs/architecture.md` para detalhes e `docs/firestore-schema.md` para a
modelagem completa do banco.

## Setup

Este scaffold foi criado sem o Flutter SDK disponível no ambiente de geração,
então os arquivos `.g.dart`/`.freezed.dart` **não** estão gerados e os
projetos nativos (`android/`, `ios/`) ainda não existem. Para rodar:

```bash
flutter create --org com.gymrank --project-name gymrank --platforms android,ios .
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutterfire configure   # gera lib/firebase_options.dart
flutter run
```

## Cloud Functions

```bash
cd functions
npm install
npm run build
firebase deploy --only functions
```

## Firestore & Storage Rules

```bash
firebase deploy --only firestore:rules,storage:rules
```

## Status do projeto

Este é o scaffold inicial: arquitetura, modelagem de dados completa,
regras de segurança, Cloud Functions essenciais e as telas centrais dos
principais fluxos (auth, perfil, evolução corporal, check-in, rankings,
desafios, feed, painel da academia). Telas adicionais e polimento visual
devem ser construídos incrementalmente sobre esta base.
