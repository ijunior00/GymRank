# AnahiFitness

App do método de uma personal trainer no México. A treinadora é a dona
da conta: gerencia seus alunos no painel, e os alunos treinam, registram
a evolução e competem dentro da comunidade dela. Interface 100% em
espanhol (es-MX) e **mobile first**: cerca de 80% do uso é no celular,
inclusive o painel da treinadora.

Evoluiu do scaffold original de gamificação para academias (B2B2C); o
histórico e a direção de produto estão em
`docs/brainstorm-personal-trainer.md`.

> O repositório e o pacote Dart ainda se chamam `gymrank` — é o nome de
> origem e não aparece para ninguém (os imports são `package:gymrank/…`).
> O que a aluna vê é **AnahiFitness**, e o app nas lojas é
> `com.anahifitness.app`.

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
    plans/                  # upload PDF/Word → leitura por IA → revisão → publicação
    workout_session/        # treino do dia executado série a série
    meal_log/               # refeições marcadas e adesão à dieta
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

Os projetos nativos `android/` e `ios/` estão versionados e configurados
(app id `com.anahifitness.app`, es-MX, só retrato, splash violeta, permissões
de câmera/galeria em espanhol). Os arquivos `.g.dart`/`.freezed.dart` e
os de configuração do Firebase **não** são versionados:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutterfire configure    # firebase_options.dart + google-services.json + GoogleService-Info.plist
flutter run
```

Preview sem Firebase (dados fake, usuária demo é a treinadora):

```bash
flutter run -t lib/main_demo.dart
```

Testes das regras puras (níveis, 1RM, treino do dia, leitura dos planos):

```bash
flutter test
```

Dois roteiros passo a passo:

- `docs/setup-firebase.md` — criar o projeto Firebase e ligar o app real
  (é o que faz os 2 erros do `flutter analyze` sumirem).
- `docs/setup-movil.md` — daí até a Play Store e a App Store: assinatura,
  chave APNs, capacidades do `Runner.entitlements`, ícones.

## Planos: PDF/Word → revisão → publicação

1. Na ficha do aluno, a treinadora (ou a nutrióloga) toca em **Subir**,
   escolhe o tipo (entrenamiento, dieta, macros, evaluación, otro) e o
   arquivo (PDF, .docx ou foto, até 20 MB). Também dá para capturar à
   mão.
2. O arquivo vai para `Storage:documents/{coachId}/{userId}/…` e nasce
   `documents/{docId}` com status `subido`.
3. A Cloud Function `parseDocument` envia o arquivo ao Claude
   (`claude-opus-5`, saída estruturada no esquema do tipo, ver
   `functions/src/plans/planSchemas.ts`) e grava `listo` + `parsedPlan`,
   com grau de confiança e avisos. Erros ficam em `error` com botão
   "Reintentar".
4. A treinadora abre **Revisar**: edita título, sessões/exercícios (ou
   comidas/alimentos, metas de macros…), vê os avisos do leitor, alterna
   para a "vista del alumno" e toca em **Publicar**.
5. `plans/{planId}` recebe a nova versão (histórico em `versions/`), o
   documento vira `publicado` e `onPlanPublished` notifica o aluno, que
   vê tudo em **Mis planes**.

Configuração necessária: `firebase functions:secrets:set ANTHROPIC_API_KEY`.

## O dia a dia do aluno

- **Entrenamiento de hoy** na home: o app escolhe a próxima sessão do
  plano (rodízio pelos dias, seguindo a última concluída), estima a
  duração e pré-preenche carga e repetições com o que o aluno fez da
  última vez naquele exercício.
- **Execução**: um exercício por página, séries com reps e kg, toque
  grande para marcar a série (que dispara o descanso com +15 s e pular),
  cronômetro da sessão, adicionar ou remover séries. Sai e retoma sem
  perder nada.
- **Conclusão = check-in**: `onWorkoutSessionCompleted` valida (mínimo de
  10 min e ao menos uma série), soma XP, registra o dia na sequência,
  cria o resumo em `workouts` e detecta recordes pelo 1RM estimado
  (Epley). O resumo mostra duração, séries, volume, XP e os recordes.
- **Comidas de hoy**: as refeições do plano de alimentação com um toque
  para marcar "la hice", "la cambié" ou "me la salté". A adesão dos
  últimos 7 dias aparece na ficha do aluno no painel da treinadora.

## Difusão: cards, indicação e marca

- **Cards compartilháveis** em 9:16 (1080×1920), gerados no aparelho:
  recorde, racha, nível, treino concluído e posição no ranking. Saem do
  resumo da sessão, do perfil e do ranking. O card leva a marca da
  treinadora (nome, @ e cor), o código de convite dela e o @ de quem
  compartilhou, para o programa de indicação.
- **Indicação**: no cadastro o novo aluno diz quem o convidou; a function
  `onClientCreated` credita o embaixador com XP, soma no `referralCount`
  e o avisa. O painel lista os embaixadores e os cards recentes em
  "Difusión".
- **Cor da marca**: escolhida no primeiro acesso da treinadora e aplicada
  às imagens compartilhadas. A interface do app segue a paleta violeta do
  sistema; a cor dela vale onde importa para o marketing, que é o que
  circula fora do app.

## Cloud Functions

```bash
cd functions
npm install
npm run build
firebase deploy --only functions
```

Todas rodam em `us-central1`, fixado em `functions/src/constants.ts`.
`AppConstants.functionsRegion` (Dart) tem de acompanhar: se as duas
divergirem, a callable existe mas o app chama outra região e recebe
`NOT_FOUND`.

Funções: `validateCheckIn`, `onWorkoutCreated` (XP + `lastWorkoutAt` do
aluno), `onBodyMeasurementCreated`, `onProgressPhotoCreated`,
`onFriendshipUpdated`, `recalculateGymScore`, `recalculateRankings`,
`recalculateCoachDashboard`, `onClientCreated`, `seasonReset`,
`parseDocument`, `onPlanPublished`, `onWorkoutSessionCompleted`.

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
ajustadas e toda a interface em es-MX. Também pronto: upload de
PDF/Word/foto com leitura por IA, revisão editável no celular,
publicação versionada e a tela "Mis planes"; e o dia a dia do aluno
(treino do dia executável, conclusão valendo como check-in com recordes
automáticos, e marcação das refeições com adesão). A identidade visual é
violeta escura (ver "Paleta" em `docs/architecture.md`). E a difusão:
cards compartilháveis com a marca dela, programa de indicação com
embaixadores e cor da marca escolhida por ela.

Do Pilar 6 ficaram de fora, por dependerem de decisões dela e de
hospedagem: página pública com lista de espera, turmas com vagas
limitadas e depoimentos aprovados.

Os projetos nativos iOS e Android estão criados e configurados
(`com.anahifitness.app`), com o push finalmente ligado de ponta a ponta:
permissão, registro do token em `users/{uid}/fcmTokens`, renovação,
remoção no logout e abertura da tela pelo `deepLink` da notificação.
Compilação e verificação de cada plataforma: `docs/setup-movil.md`.
