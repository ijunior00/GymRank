# Modelagem do Firestore

Todas as coleções abaixo têm um DTO correspondente em
`lib/features/<feature>/data/dtos/` e uma entidade de domínio em
`lib/features/<feature>/domain/entities/`. Campos calculados por Cloud
Functions (marcados **[CF]**) nunca devem ser escritos pelo cliente —
isso é reforçado em `firestore.rules`.

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
| gymId | string? | referência a `gyms/{gymId}` |
| goal | string | enum `UserGoal` |
| role | string | enum `UserRole`: aluno, personal, academia, adminGlobal |
| level | number | **[CF]** derivado de `xpTotal` |
| xpTotal | number | **[CF]** histórico, nunca resetado |
| xpCurrentSeason | number | **[CF]** resetado a cada temporada |
| gymScore | number | **[CF]** 0–1000, resetado a cada temporada |
| currentStreakDays / longestStreakDays | number | **[CF]** atualizado em `validateCheckIn` |
| lastCheckInAt | timestamp? | **[CF]** |
| plan | string | free \| premium |
| createdAt | timestamp | |

Subcoleções: `achievements/{code}` (**[CF]** apenas), `fcmTokens/{token}`.

## `gyms/{gymId}`

name, city, logoUrl, brandColorHex, qrCodeSecret (nunca exposto ao
cliente fora do payload assinado do QR), plan, studentCount,
activeChallengeCount, createdAt.

Subcoleções:
- `stats/current` **[CF]**: `GymDashboardStats` (totalStudents,
  checkInsToday/Week, newStudentsThisMonth, inactiveStudents30d,
  retentionRate, calculatedAt).
- `checkins/{checkInId}` **[CF only]**: userId, gymId, checkedInAt,
  xpGranted, countedForStreak. Criado exclusivamente pela function
  `validateCheckIn` a partir de um QR Code assinado (HMAC-SHA256 com
  `qrCodeSecret`, TTL de 30s) — o cliente nunca escreve aqui.

## `workouts/{workoutId}`

userId, date, durationMinutes, muscleGroup, intensity, source (manual |
hevy | strong | appleHealth | googleFit), note?, createdAt. Criado pelo
próprio usuário; dispara `onWorkoutCreated` (+50 XP, progresso de
desafios "diasTreinados").

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

## `posts/{postId}` (feed social)

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

gymId? (null = desafio global/plataforma), title, description, scope
(individual | equipe | academia | regional), period (semanal | mensal),
metric (diasTreinados | distanciaKm | pesoPerdidoKg |
massaMuscularGanhaKg | checkIns), targetValue, startsAt, endsAt,
xpReward, rewardId?, participantCount, isActive, createdAt.

Subcoleção `participants/{userId}`: currentValue, completed,
completedAt?. **O cliente só pode criar a inscrição inicial
(`currentValue: 0, completed: false`)** — todo progresso é calculado
por `incrementChallengeProgress` a partir de eventos de origem confiável
(check-in, treino), nunca auto-declarado, para evitar trapaça.

## `championships/{championshipId}`

gymId, name, description, startsAt, endsAt, criteria (maisXp |
maiorGymScore | maisCheckIns | maiorEvolucao), rewardIds[],
participantCount, isFinished, createdAt. Criado exclusivamente por
staff da academia.

## `rewards/{rewardId}`

gymId, name, imageUrl?, type (suplemento | vestuario | consultoria |
mensalidadeGratis | acessorio | valeCompras), stock.

Subcoleção `grants/{grantId}` **[CF only]**: rewardId, userId,
sourceType (challenge | championship | season), sourceId, status
(available | granted | redeemed | expired), grantedAt, redeemedAt?.
Concedido atomicamente por `grantReward` (decrementa `stock` em
transação).

## `rankings/{scope}_{criteria}_{scopeId}/entries/{userId}`

Documentos materializados por `recalculateRankings` (roda a cada hora).
`scope`: academia | amigos | cidade | nacional. `criteria`: xp |
gymScore | consistencia | evolucao. `scopeId` é o `gymId`/cidade ou
`global`. Cada entrada: userId, userName, userPhotoUrl, position, value,
calculatedAt. Leitura direta pelo cliente, sem agregação — essencial
para escalar a milhões de usuários.

## `gym_score_history/{entryId}`

userId, calculatedAt, frequencyScore, consistencyScore,
challengesScore, evolutionScore, totalScore, seasonId?. Gerado
diariamente por `recalculateGymScore`. Histórico imutável usado para
gráficos de evolução do Gym Score no perfil.

## `seasons/{seasonId}`

gymId? (null = temporada global), number, duration (mensal |
trimestral), startsAt, endsAt, isActive, rewardsDistributed. Fechada
automaticamente por `seasonReset` quando `endsAt` expira, que também
cria a temporada seguinte.

Subcoleção `results/{userId}`: finalPosition, xpEarned, finalGymScore,
badgeGranted (Top 10 = badge; Top 3 e Top 1 usam o mesmo mecanismo de
conquista permanente em `users/{uid}/achievements`).

## `notifications/{notificationId}`

userId, type (workoutReminder | newChallenge | friendOvertook | newLevel
| newAchievement | championshipEnded | rewardAvailable), title, body,
deepLink?, read, createdAt. Escrito por `dispatchNotification`, que
também envia push via FCM para os tokens em
`users/{uid}/fcmTokens/*`. O cliente só pode marcar como lida.

---

## Convenções gerais

- Nenhum documento de gamificação (`xpTotal`, `level`, `gymScore`,
  `currentStreakDays`, check-ins, conquistas, rankings, resultados de
  temporada, concessão de recompensa) é escrito diretamente pelo
  cliente — sempre via Cloud Functions com Admin SDK, que ignora as
  regras de segurança. Isso é o que torna o sistema resistente a
  fraude client-side.
- Histórico (`body_measurements`, `gym_score_history`,
  `seasons/*/results`) é sempre *append-only*.
- Documentos que precisam de leitura eficiente em escala (rankings,
  stats do painel da academia) são **materializados** por jobs
  agendados em vez de agregados em tempo real no cliente.
