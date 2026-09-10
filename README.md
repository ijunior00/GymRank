# GymRank

App do método de uma personal trainer no México. A treinadora é a dona
da conta: gerencia seus alunos no painel, e os alunos treinam, registram
a evolução e competem dentro da comunidade dela. Interface 100% em
espanhol (es-MX).

Evoluiu do scaffold original de gamificação para academias (B2B2C); o
histórico e a direção de produto estão em
`docs/brainstorm-personal-trainer.md`.

## Stack

- **Front-end:** Flutter, Material 3, Riverpod, GoRouter, Freezed,
  flutter_localizations (locale fixo `es_MX`)
- **Backend:** Firebase (Auth, Firestore, Storage, Cloud Functions, Cloud
  Messaging, Analytics, Crashlytics, Remote Config)
- **Cloud Functions:** TypeScript (`functions/`)

## Arquitetura

Clean Architecture + Feature-First, com injeção de dependência via Riverpod.

```
lib/
  core/                     # infra transversal: tema, rotas, DI, erros, utils
    constants/              # AppConstants, enums globais (UserRole, UserGoal…)
    l10n/                   # rótulos es-MX dos enums compartilhados
    router/
    theme/
    utils/
  demo/                     # dados e repositórios fake do preview (Render)
  features/
    auth/
    profile/
    coach_panel/            # painel da treinadora: alunos, ficha, código de convite
    body_measurement/
    progress_photo/
    workout/
    checkin/                # QR presencial (opcional no modelo online)
    gamification/           # XP, níveis, conquistas, Gym Score, temporadas
    challenges/
    championships/          # torneios da comunidade
    rewards/
    rankings/
    social_feed/
    friendship/
    notifications/
  main.dart
  main_demo.dart
```

Cada feature segue três camadas:

```
features/<feature>/
  data/
    dtos/            # Firestore <-> Dart
    repositories/     # implementações concretas (Firestore/Storage/Functions)
  domain/
    entities/          # modelos imutáveis (Freezed), sem dependência de Firebase
    repositories/       # contratos abstratos
    usecases/            # regras de negócio isoladas
  presentation/
    controllers/          # Riverpod providers
    screens/
    widgets/
```

Regra de dependência: `presentation -> domain <- data`. O `domain` nunca
importa Firebase; `data` implementa os contratos do `domain`.

Veja `docs/architecture.md` para detalhes (papéis, fluxo da treinadora,
idioma) e `docs/firestore-schema.md` para a modelagem completa do banco.

## Papéis

| Papel | Como nasce | O que vê |
|---|---|---|
| `alumno` | cadastro no app | treino, progresso, retos, ranking da comunidade, comunidad |
| `coach` | promovido no console (`users/{uid}.role = "coach"`) | tudo acima + painel `/coach` |
| `nutriologo` | promovido no console e `coachId` da treinadora | leitura do painel (parte alimentar virá com o upload de PDF) |
| `adminGlobal` | console | tudo |

Para colocar a treinadora no ar: crie a conta dela pelo app, mude
`role` para `coach` no Firestore, e ela mesma configura a marca e gera o
código de convite na primeira abertura do painel.

## Setup

Os arquivos `.g.dart`/`.freezed.dart` **não** são versionados e os
projetos nativos (`android/`, `ios/`) ainda não existem. Para rodar:

```bash
flutter create --org com.gymrank --project-name gymrank --platforms android,ios .
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutterfire configure   # gera lib/firebase_options.dart
flutter run
```

Preview sem Firebase (dados fake, usuária demo é a treinadora):

```bash
flutter run -t lib/main_demo.dart
```

## Cloud Functions

```bash
cd functions
npm install
npm run build
firebase deploy --only functions
```

Funções: `validateCheckIn`, `onWorkoutCreated` (XP + `lastWorkoutAt` do
aluno), `onBodyMeasurementCreated`, `onProgressPhotoCreated`,
`onFriendshipUpdated`, `recalculateGymScore`, `recalculateRankings`,
`recalculateCoachDashboard`, `onClientCreated`, `seasonReset`.

## Firestore & Storage Rules

```bash
firebase deploy --only firestore:rules,firestore:indexes,storage:rules
```

## Direção do produto

`docs/brainstorm-personal-trainer.md` descreve a missão completa (painel
da treinadora, upload de PDF/Word da nutrióloga que vira dieta/macros e
do treino que vira rotina, execução do treino, marcos, competição por
consistência, cards compartilháveis) e a priorização MVP / Fase 2 /
Fase 3.

## Status do projeto

MVP em andamento. Feito nesta etapa: pivô `gyms -> coaches`, papéis
`alumno/coach/nutriologo`, painel da treinadora (código de convite,
indicadores, lista de alunos com busca e situação, ficha do aluno com
plano, cobro, progresso, treinos e notas privadas), vínculo por código
no cadastro e no perfil, regras/índices/Storage atualizados, functions
ajustadas e toda a interface em es-MX. Próximo: upload de PDF/Word com
revisão e publicação de planos.
