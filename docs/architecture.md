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
- Gym Score, rankings, stats do painel da academia: recalculados
  periodicamente por jobs agendados (`recalculateGymScore`,
  `recalculateRankings`, `recalculateGymDashboard`) e apenas lidos pelo
  cliente.

## Offline-first (próximos passos)

O `pubspec.yaml` já inclui `hive`/`hive_flutter` e `connectivity_plus`
para cache local, mas a camada de cache ainda não está implementada
nos repositórios desta primeira versão. Ao adicioná-la, o padrão
recomendado é: repositório tenta Firestore (`GetOptions(source:
Source.serverAndCache)` já ajuda) e cai para Hive quando
`connectivity_plus` reportar offline, sem expor esse detalhe a
`domain`/`presentation`.
