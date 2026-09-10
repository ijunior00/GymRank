# Modelagem do Firestore

Todas as coleções abaixo têm um DTO correspondente em
`lib/features/<feature>/data/dtos/` (ou um `_fromSnapshot` no repositório)
e uma entidade de domínio em `lib/features/<feature>/domain/entities/`.
Campos calculados por Cloud Functions (marcados **[CF]**) nunca devem ser
escritos pelo cliente — isso é reforçado em `firestore.rules`.

> Contexto: o produto é o app do método de uma personal trainer no
> México. A "dona" da conta é a **treinadora** (`coaches/{coachId}`), não
> mais uma academia. Textos exibidos ao usuário estão em espanhol (es-MX);
> identificadores de enum permanecem os nomes históricos do código.

## `users/{uid}`

| Campo | Tipo | Notas |
|---|---|---|
| name | string | |
| username | string | único, ver `usernameLowercase` |
| usernameLowercase | string | espelho em minúsculas para busca case-insensitive |
| photoUrl | string? | |
| birthDate | timestamp | |
| sex | string | |
| heightCm | number | |
| city | string | |
| coachId | string? | referência a `coaches/{coachId}`. Aluno: quem o acompanha. Coach/nutrióloga: o próprio painel |
| goal | string | enum `UserGoal` |
| role | string | enum `UserRole`: `alumno` (padrão no cadastro), `coach`, `nutriologo`, `adminGlobal`. Só o backend/console altera |
| level | number | **[CF]** derivado de `xpTotal` |
| xpTotal | number | **[CF]** histórico, nunca resetado |
| xpCurrentSeason | number | **[CF]** resetado a cada temporada |
| gymScore | number | **[CF]** 0–1000, resetado a cada temporada |
| currentStreakDays / longestStreakDays | number | **[CF]** atualizado em `validateCheckIn` |
| lastCheckInAt | timestamp? | **[CF]** check-in presencial por QR |
| plan | string | free \| premium |
| referredBy | string? | `username` de quem indicou, digitado no cadastro. Imutável depois |
| referralCount | number | **[CF]** quantos alunos entraram por indicação deste usuário |
| createdAt | timestamp | |

Subcoleções: `achievements/{code}` (**[CF]** apenas), `fcmTokens/{token}`.

## `coaches/{coachId}`

A treinadora, sua marca e a configuração da comunidade dela.

| Campo | Tipo | Notas |
|---|---|---|
| ownerUserId | string | `users/{uid}` da treinadora |
| name | string | nome da marca/método exibido aos alunos |
| tagline | string? | |
| city, country | string | `country` default `MX` |
| logoUrl, brandColorHex, instagramHandle | string? | white-label |
| inviteCode | string | código curto que o aluno digita para se vincular |
| qrCodeSecret | string | HMAC do QR de check-in presencial (opcional no modelo online) |
| plan | string | free \| premium |
| studentCount | number | **[CF]** `onClientCreated` / `recalculateCoachDashboard` |
| activeChallengeCount | number | |
| createdAt | timestamp | |

Criado pela própria treinadora no primeiro acesso ao painel (tela
`CoachSetupScreen`), desde que o perfil dela já tenha `role: coach` —
atribuído fora do app. A criação grava também `users/{uid}.coachId`.

Subcoleções:
- `stats/current` **[CF]**: `CoachDashboardStats` (totalStudents,
  activeStudents, workoutsToday, workoutsThisWeek, newStudentsThisMonth,
  inactiveStudents7d, retentionRate, calculatedAt). Recalculado a cada
  hora por `recalculateCoachDashboard` a partir de `workouts` e
  `users.lastCheckInAt`.
- `clients/{userId}`: vínculo aluno <-> treinadora. userId, coachId,
  status (`activo` | `pausado` | `inactivo`), planName?, startedAt,
  nextPaymentAt?, tags[], lastWorkoutAt? (**[CF]** `onWorkoutCreated`),
  createdAt. O aluno cria o próprio vínculo ao entrar com o código
  (sempre `activo`); só a treinadora edita.
  - `notes/{noteId}`: anotações privadas da treinadora (authorId, text,
    createdAt). O aluno nunca lê.
- `checkins/{checkInId}` **[CF only]**: userId, coachId, checkedInAt,
  xpGranted, countedForStreak. Criado exclusivamente pela function
  `validateCheckIn` a partir de um QR Code assinado (HMAC-SHA256 com
  `qrCodeSecret`, TTL de 30s) — o cliente nunca escreve aqui.

## `documents/{docId}` (arquivos de plano)

PDF, Word (.docx) ou foto enviados pela treinadora ou pela nutrióloga
para um aluno.

| Campo | Tipo | Notas |
|---|---|---|
| coachId, userId, uploadedBy | string | comunidade, aluno destino, quem enviou |
| kind | string | `entrenamiento` \| `dieta` \| `macros` \| `evaluacion` \| `otro` |
| fileName, storagePath, downloadUrl, contentType, sizeBytes | | arquivo em `Storage:documents/{coachId}/{userId}/…` |
| status | string | `subido` → `procesando` → `listo` → `publicado`, ou `error` |
| errorMessage | string? | preenchido em `error` |
| parsedPlan | map? | **[CF]** saída estruturada do Claude no esquema do `kind` (functions/src/plans/planSchemas.ts) |
| parsedAt, parserModel | | **[CF]** |
| planId | string? | preenchido ao publicar |
| createdAt, updatedAt | timestamp | |

Fluxo: o app cria o documento com `subido`; `parseDocument` (trigger em
`documents/{docId}`) baixa o arquivo, envia ao Claude (`claude-opus-5`,
saída estruturada) e grava `listo` + `parsedPlan` ou `error`. A
treinadora revisa e edita no app e publica; voltar o status para
`subido` reprocessa. Requer o secret `ANTHROPIC_API_KEY` nas functions.

## `plans/{planId}` (plano vigente por aluno e tipo)

coachId, userId, kind, title, currentVersion, content (mapa no mesmo
esquema de `parsedPlan`, já revisado), sourceDocumentId?, publishedAt,
publishedBy, createdAt. **Um documento por (userId, kind)**: republicar
incrementa `currentVersion` e sobrescreve `content`.

Subcoleção `versions/{n}` (append-only): number, title, content,
sourceDocumentId?, publishedAt, publishedBy, coachId, userId. Toda
publicação grava uma cópia aqui; a treinadora vê o histórico. A Cloud
Function `onPlanPublished` notifica o aluno (`planPublished`).

## `workout_sessions/{sessionId}` (treino do dia executado)

Execução de uma sessão do plano de treino publicado. É o "check-in" do
aluno online.

| Campo | Tipo | Notas |
|---|---|---|
| userId, coachId | string | dono e comunidade |
| planId, planVersion | | plano de origem e versão vigente ao começar |
| dayIndex, dayName | | qual sessão do plano (rodízio cíclico) |
| status | string | `enCurso` → `completada` ou `cancelada` |
| startedAt, finishedAt, durationSec | | cronometragem |
| exercises[] | array | nome, prescrição copiada do plano e `sets[]` com reps, load, rpe e `done` |
| totalVolumeKg | number | soma de reps × carga das séries feitas |
| validated | bool? | **[CF]** `false` quando a sessão não cumpre o mínimo |
| validationReason | string? | **[CF]** motivo em espanhol quando inválida |
| countedForStreak, xpGranted | | **[CF]** |
| prs[] | array | **[CF]** recordes: exercício, carga, reps, 1RM estimado |

O aluno cria e edita enquanto está `enCurso`; os campos **[CF]** são
bloqueados nas regras. Ao virar `completada`, a function
`onWorkoutSessionCompleted` valida (mínimo de 10 min e ao menos uma série
marcada), registra o dia na sequência, cria o resumo em `workouts` (que
concede XP e avança desafios) e compara o 1RM estimado (Epley) com as 60
sessões válidas anteriores para detectar recordes, gerando post e
notificação.

## `meal_logs/{userId_yyyy-MM-dd_mealIndex}`

Refeição do plano marcada pelo aluno: userId, coachId, planId, date
(`yyyy-MM-dd`), mealIndex, mealName, status (`hecha` | `cambiada` |
`saltada`), createdAt. O id determinístico faz remarcar substituir em vez
de duplicar. A adesão dos últimos 7 dias é calculada no cliente
(`hecha` = 1, `cambiada` = 0,5, `saltada` = 0) e aparece na ficha do
aluno no painel.

## `share_cards/{cardId}`

Um card que o aluno compartilhou: userId, userName, coachId, type
(`record` | `racha` | `nivel` | `entrenamiento` | `ranking`), sharedAt.
Criado pelo próprio autor logo após abrir o compartilhamento; ninguém
edita depois. Alimenta o bloco "Difusión" do painel da treinadora, que
mostra o que está circulando e quem são os embaixadores (por
`users.referralCount`).

A imagem em si não é armazenada: é gerada no aparelho a 1080×1920 e
entregue ao sistema de compartilhamento, o que evita custo de Storage e
qualquer moderação de conteúdo do nosso lado.

## `workouts/{workoutId}`

userId, date, durationMinutes, muscleGroup, intensity, source (manual |
plan | hevy | strong | appleHealth | googleFit), note?, sessionId?,
createdAt. Criado pelo próprio usuário (registro manual) ou pela function
ao concluir uma sessão do plano (`source: plan`); dispara
`onWorkoutCreated` (+50 XP, progresso de desafios "diasTreinados",
`clients/{uid}.lastWorkoutAt`). É a atividade que conta para o painel da
treinadora no atendimento online.

## `body_measurements/{measurementId}`

userId, recordedAt, pesoKg, percentualGordura, massaMuscularKg, imc,
bracoCm, peitoralCm, cinturaCm, abdomenCm, quadrilCm, coxaCm,
panturrilhaCm (todos opcionais, exceto userId/recordedAt). **Histórico
imutável**: apenas `create`, nunca `update`/`delete` (ver
firestore.rules). Dispara `onBodyMeasurementCreated` (+30 XP).

## `progress_photos/{photoId}`

userId, storageUrl, thumbnailUrl, category (frente | costas | perfil),
takenAt, weightAtTimeKg?. Arquivo físico em
`Storage:progress_photos/{userId}/{timestamp}.jpg`. Dispara
`onProgressPhotoCreated` (+25 XP).

## `posts/{postId}` (comunidade)

userId, authorName, authorPhotoUrl, type (streakMilestone | xpMilestone
| levelUp | personalRecord | challengeCompleted | custom), text,
imageUrl?, likeCount, commentCount, shareCount, createdAt. A maioria é
gerada por Cloud Functions (`generateAutoPost`); posts customizados são
permitidos ao próprio usuário.

Subcoleções: `likes/{userId}` (id = uid do curtidor, evita curtida
duplicada), `comments/{commentId}`.

## `friendships/{requesterId_addresseeId}`

Id determinístico (`[uidA, uidB].sort().join('_')`) para impedir pares
duplicados. requesterId, addresseeId, status (pending | accepted |
blocked), createdAt, respondedAt?. Transição para `accepted` dispara
`onFriendshipUpdated` (+150 XP para quem convidou).

## `challenges/{challengeId}`

coachId? (null = desafio global/plataforma), title, description, scope
(individual | equipo | comunidad | regional), period (semanal | mensal),
metric (diasTreinados | distanciaKm | pesoPerdidoKg |
massaMuscularGanhaKg | checkIns), targetValue, startsAt, endsAt,
xpReward, rewardId?, participantCount, isActive, createdAt. Criado pela
treinadora dona do `coachId` (ou admin).

Subcoleção `participants/{userId}`: currentValue, completed,
completedAt?. **O cliente só pode criar a inscrição inicial
(`currentValue: 0, completed: false`)** — todo progresso é calculado
por `incrementChallengeProgress` a partir de eventos de origem confiável
(check-in, treino), nunca auto-declarado, para evitar trapaça.

## `championships/{championshipId}` (torneios)

coachId, name, description, startsAt, endsAt, criteria (maisXp |
maiorGymScore | maisCheckIns | maiorEvolucao), rewardIds[],
participantCount, isFinished, createdAt. Criado exclusivamente pela
treinadora.

## `rewards/{rewardId}`

coachId, name, imageUrl?, type (suplemento | vestuario | consultoria |
mensalidadeGratis | acessorio | valeCompras), stock.

Subcoleção `grants/{grantId}` **[CF only]**: rewardId, userId,
sourceType (challenge | championship | season), sourceId, status
(available | granted | redeemed | expired), grantedAt, redeemedAt?.
Concedido atomicamente por `grantReward` (decrementa `stock` em
transação).

## `rankings/{scope}_{criteria}_{scopeId}/entries/{userId}`

Documentos materializados por `recalculateRankings` (roda a cada hora).
`scope`: comunidad | amigos | ciudad | nacional. `criteria`: xp |
gymScore | consistencia | evolucao. `scopeId` é o `coachId` (comunidad),
a cidade, ou `global` (nacional). Cada entrada: userId, userName,
userPhotoUrl, position, value, calculatedAt. Leitura direta pelo
cliente, sem agregação.

## `gym_score_history/{entryId}`

userId, calculatedAt, frequencyScore, consistencyScore,
challengesScore, evolutionScore, totalScore, seasonId?. Gerado
diariamente por `recalculateGymScore`. Histórico imutável usado para
gráficos de evolução do Gym Score no perfil.

## `seasons/{seasonId}`

coachId? (null = temporada global), number, duration (mensal |
trimestral), startsAt, endsAt, isActive, rewardsDistributed. Fechada
automaticamente por `seasonReset` quando `endsAt` expira, que também
cria a temporada seguinte.

Subcoleção `results/{userId}`: finalPosition, xpEarned, finalGymScore,
badgeGranted (Top 10 = badge; Top 3 e Top 1 usam o mesmo mecanismo de
conquista permanente em `users/{uid}/achievements`).

## `notifications/{notificationId}`

userId, type (workoutReminder | newChallenge | friendOvertook | newLevel
| newAchievement | championshipEnded | rewardAvailable | newStudent |
planPublished), title, body, deepLink?, read, createdAt. Escrito por
`dispatchNotification`, que também envia push via FCM para os tokens em
`users/{uid}/fcmTokens/*`. O cliente só pode marcar como lida.
`newStudent` é enviada à treinadora por `onClientCreated`;
`planPublished` ao aluno por `onPlanPublished`.

---

## Storage

- `progress_photos/{userId}/…`, `profile_photos/{userId}/…`: imagens do
  próprio usuário.
- `coach_assets/{coachId}/…`: logo e imagens da marca (escrita só pela
  treinadora).
- `documents/{coachId}/{userId}/…`: PDF/Word/imagem de dieta, macros e
  treino por aluno. Leitura pelo aluno dono e pela treinadora; escrita
  pela treinadora (a nutrióloga entra quando o fluxo de upload existir).

## Convenções gerais

- Nenhum documento de gamificação (`xpTotal`, `level`, `gymScore`,
  `currentStreakDays`, check-ins, conquistas, rankings, resultados de
  temporada, concessão de recompensa) é escrito diretamente pelo
  cliente — sempre via Cloud Functions com Admin SDK, que ignora as
  regras de segurança. Isso é o que torna o sistema resistente a
  fraude client-side.
- `role` também nunca é gravado pelo cliente: todo cadastro nasce
  `alumno`; a treinadora e a nutrióloga são promovidas no console do
  Firebase (ou por script com Admin SDK).
- Histórico (`body_measurements`, `gym_score_history`,
  `seasons/*/results`) é sempre *append-only*.
- Documentos que precisam de leitura eficiente em escala (rankings,
  stats do painel da treinadora) são **materializados** por jobs
  agendados em vez de agregados em tempo real no cliente.
