# Arquitetura

## Camadas

Cada feature em `lib/features/<nome>/` segue Clean Architecture:

```
data/
  dtos/            Mapeiam Firestore (Map<String, dynamic> / DocumentSnapshot) <-> entidade de domínio.
                    Mapeamento manual (não json_serializable) por causa de Timestamp/enum do Firestore.
  repositories/     Implementações concretas dos contratos do domínio (Firestore, Storage, Cloud Functions).
domain/
  entities/         Modelos imutáveis (Freezed). Nunca importam Firebase.
  repositories/     Contratos abstratos (`abstract interface class`) que `data/` implementa.
  usecases/         Regras de negócio puras e testáveis isoladamente (ex.: LevelCalculator, GymScoreCalculator).
presentation/
  controllers/      Providers Riverpod (Provider/StreamProvider/AsyncNotifier) que expõem estado à UI.
  screens/          Telas completas, roteadas via GoRouter.
  widgets/          Componentes reutilizáveis dentro da feature.
```

Regra de dependência: `presentation -> domain <- data`. Isso permite
trocar a implementação de um repositório (ex.: Firestore por um fake em
testes) sem tocar em `domain` ou `presentation`.

## Por que os modelos de dados não usam `json_serializable`

O Firestore usa `Timestamp`, `DocumentReference` e `GeoPoint` — tipos
que não mapeiam diretamente para JSON. Em vez de escrever
`JsonConverter`s para cada um, os DTOs implementam `fromSnapshot` /
`toMap` manualmente. As entidades de domínio continuam usando Freezed
para imutabilidade, `copyWith` e igualdade estrutural.

## Injeção de dependência

Riverpod é o único mecanismo de DI. Cada repositório tem um
`Provider<T>` (ex.: `userRepositoryProvider`) que constrói a
implementação concreta a partir dos providers de infraestrutura em
`lib/core/di/firebase_providers.dart`. Isso deixa a troca por mocks em
testes de widget trivial via `ProviderScope(overrides: [...])`.

## Autenticação e roteamento

`lib/features/auth/presentation/controllers/auth_providers.dart` expõe:

- `authStateProvider`: stream do uid autenticado (ou `null`).
- `currentUserProvider`: stream do documento `users/{uid}` completo.

`lib/core/router/app_router.dart` é um provider Riverpod
(`appRouterProvider`) que observa `authStateProvider` e reconstrói o
`GoRouter` inteiro quando o estado de auth muda, aplicando o redirect
entre o fluxo de autenticação (`/login`, `/signup`) e o fluxo
autenticado (shell com bottom navigation). Reconstruir o router inteiro
é uma simplificação aceitável neste estágio; se a perda de pilha de
navegação em cada mudança de auth se tornar perceptível, migrar para um
`Listenable` que só dispara no evento de login/logout.

## Papéis e o painel da treinadora

`UserRole` tem quatro valores: `alumno` (único papel que o cadastro
cria), `coach` (a treinadora dona de `coaches/{coachId}`), `nutriologo`
(nutrióloga parceira, leitura da comunidade e, futuramente, escrita da
parte alimentar) e `adminGlobal`. A promoção para `coach`/`nutriologo`
é feita fora do app (console do Firebase ou script com Admin SDK) — o
cliente nunca grava `role`.

Fluxo da treinadora: com `role: coach` e `coachId == null`, o painel
(`/coach`) mostra a tela de configuração, que cria `coaches/{id}` e
aponta `users/{uid}.coachId` para ele na mesma batch. A partir daí ela
tem o código de convite, a lista de alunos (`users where coachId == …`
combinada com `coaches/{id}/clients`) e a ficha de cada aluno.

Fluxo do aluno: digita o código no cadastro ou em Perfil → "Unirme a mi
coach". O `CoachPanelRepository.joinCoach` grava `coachId` no perfil e
cria `clients/{uid}` com status `activo` — as duas únicas escritas que
as regras permitem ao aluno nesse caminho.

A feature vive em `lib/features/coach_panel/` e segue as mesmas três
camadas das demais.

## Idioma

O app é lançado para o México e toda a interface está em espanhol
(es-MX), com strings inline nas telas e rótulos de enums centralizados
em `lib/core/l10n/labels_es.dart`. `MaterialApp` fixa `Locale('es',
'MX')` com os delegates de `flutter_localizations`, e `main.dart`
inicializa os dados de data do `intl` para `es_MX`. Comentários de
código continuam em português (idioma do time).

## Anti-fraude na gamificação

Nenhum valor de gamificação (XP, nível, Gym Score, sequência,
conquistas, progresso de desafio, ranking) é gravável diretamente pelo
cliente — ver `firestore.rules` e `docs/firestore-schema.md`. Toda
escrita nesses campos passa por uma Cloud Function que deriva o valor
de um evento de origem confiável:

- Check-in: só existe via `validateCheckIn` (QR assinado com
  HMAC-SHA256, TTL de 30s, mais cooldown de 6h).
- Progresso de desafio: só avança via `incrementChallengeProgress`,
  chamada a partir de check-ins e treinos — nunca de um valor enviado
  pelo cliente.
- Gym Score, rankings, stats do painel da treinadora: recalculados
  periodicamente por jobs agendados (`recalculateGymScore`,
  `recalculateRankings`, `recalculateCoachDashboard`) e apenas lidos pelo
  cliente.

## Offline-first (próximos passos)

O `pubspec.yaml` já inclui `hive`/`hive_flutter` e `connectivity_plus`
para cache local, mas a camada de cache ainda não está implementada
nos repositórios desta primeira versão. Ao adicioná-la, o padrão
recomendado é: repositório tenta Firestore (`GetOptions(source:
Source.serverAndCache)` já ajuda) e cai para Hive quando
`connectivity_plus` reportar offline, sem expor esse detalhe a
`domain`/`presentation`.
