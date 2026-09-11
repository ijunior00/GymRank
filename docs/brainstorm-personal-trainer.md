# Brainstorm: do GymRank ao app do método da treinadora

> Documento de produto. Objetivo: transformar a base atual do GymRank
> (gamificação para academias) no app oficial do método de uma personal
> trainer que quer ser referência regional e, depois, nacional, com
> atendimento 100% online possível.

## Decisões já tomadas

- **Mercado: México.** Toda a interface em espanhol do México (es-MX),
  locale fixo `es_MX`, unidades métricas, Pix e afins saem do radar e
  entram os meios de pagamento locais (ver 4.3).
- **Nutrição: já existe nutrióloga parceira.** É ela quem produz os
  PDFs de dieta e macros; o app organiza, versiona e acompanha, com um
  papel próprio (`nutriologo`) para ela subir e revisar os planos. Isso
  resolve também a questão regulatória do item 4.8.
- **Mobile first: ~80% do uso será no celular**, inclusive o painel da
  treinadora. Toda tela nasce para 360 px de largura e uma mão; web e
  desktop são bônus, não alvo de layout.
- **MVP começou** pelo pivô `gyms → coaches`, pelos papéis
  `alumno / coach / nutriologo` e pelo painel da treinadora (código de
  convite, indicadores, lista de alunos com situação, ficha com plano,
  cobro, progresso, treinos e notas privadas). **Pilar 2 também está
  feito**: upload de PDF/Word/foto, leitura por IA com esquema por tipo,
  revisão editável, publicação versionada e "Mis planes" para o aluno.
  **Pilar 3 idem**: treino do dia gerado do plano, execução série a série
  com descanso, conclusão valendo como check-in (com validação, XP,
  sequência e recordes no backend) e marcação das refeições com adesão
  semanal. **Do Pilar 6 está feito o núcleo**: cards compartilháveis
  (recorde, racha, nível, treino, ranking) com a marca e o código dela,
  programa de indicação com embaixadores no painel, e a cor da marca.
  Continuam abertos, porque dependem de decisão dela e de hospedagem: a
  página pública com lista de espera, as turmas com vagas limitadas e os
  depoimentos aprovados.
- **Identidade visual roxa**: acento violeta (#A855F7) sobre preto-ameixa,
  com gradientes violeta→índigo e fúcsia→violeta.
- **iOS e Android são o alvo, e os projetos nativos existem.** App id
  `com.anahifitness.app` nas duas lojas, só retrato, es-MX, splash na cor do
  app e textos de permissão em espanhol. O que ainda depende de contas e
  de um Mac está no roteiro `docs/setup-movil.md`: projeto Firebase
  (`flutterfire configure`), chave de assinatura da Play Store, chave
  APNs e as capacidades de push e Sign in with Apple no App ID.

---

## 1. A missão em uma frase

**Um app com a marca dela onde cada aluno recebe treino, dieta e metas,
registra a evolução, compete com a comunidade e, ao evoluir, faz
propaganda do método sem perceber.**

Três coisas precisam ser verdade ao mesmo tempo:

1. **Operação** — ela consegue gerenciar dezenas (depois centenas) de
   alunos sem virar refém do WhatsApp: sobe um PDF/Word, o app organiza.
2. **Retenção** — o aluno abre o app todo dia porque tem treino do dia,
   ranking, streak, desafio e feedback dela.
3. **Marketing** — cada marco atingido vira um conteúdo compartilhável com
   a marca dela; a comunidade cresce por indicação e por desejo de
   pertencer.

---

## 2. O que muda em relação ao GymRank de hoje

Hoje o "dono" da conta é a **academia** (`gyms/{gymId}`). No novo modelo
o dono é a **treinadora / o método**. Quase tudo que existe se
reaproveita, só muda o centro de gravidade.

| Existe hoje | Vira |
|---|---|
| `gyms/{gymId}` (academia) | `coaches/{coachId}` — a treinadora, sua marca, cores, logo, nome do método |
| `UserRole.academia` | `UserRole.coach` (a dona) + `UserRole.nutricionista` (parceira, opcional) + `UserRole.aluno` |
| Painel da academia (`gym_admin`) | **Painel da treinadora**: CRM de alunos, prescrição, uploads, alertas |
| Check-in por QR Code na recepção | **Treino do dia concluído** (com registro de séries) é o "check-in". QR fica opcional para alunos presenciais |
| `workouts` = resumo (duração, grupo muscular) | `workout_sessions` = execução do treino prescrito, exercício a exercício, com carga/reps/RPE |
| Desafios e campeonatos por academia | Desafios e campeonatos **da comunidade dela** (todos os alunos, online ou presencial) |
| Rankings por XP / Gym Score | Rankings por **consistência e adesão** (para não punir quem treina em casa) + XP |
| Recompensas da academia (suplemento, mensalidade) | Recompensas **da marca dela**: camiseta do método, sessão presencial, avaliação gratuita, destaque no perfil público |
| Feed social interno | Feed interno **+ cards compartilháveis** para Instagram/WhatsApp com a marca |
| Modelo B2B2C (academias assinam) | **B2C**: o aluno assina o acompanhamento dela pelo app (mensal/trimestral) |

O que **não muda**: Flutter + Firebase, Clean Architecture, anti-fraude
via Cloud Functions, XP/níveis/streaks/conquistas, medidas corporais,
fotos de progresso, temporadas, notificações.

---

## 3. Os seis pilares do produto

### Pilar 1 — Painel da treinadora (o "cérebro")

É a tela que ela vai usar todo dia. Precisa ser web + mobile.

- **Lista de alunos** com status visual: em dia / sem treinar há X dias /
  sem check-in semanal / vencendo mensalidade / pediu ajuda no chat.
- **Ficha do aluno**: anamnese, objetivo, restrições/lesões, PAR-Q,
  histórico de medidas, fotos, PRs, planos ativos, documentos enviados,
  anotações privadas dela.
- **Prescrição**: atribuir plano de treino (por upload ou montado no app),
  dieta (ver nota jurídica no item 3.14), metas de macros, hábitos.
- **Alertas automáticos**: "Ana não treina há 5 dias", "Bruno bateu PR",
  "3 alunos terminam o ciclo de 8 semanas esta semana", "Carla venceu
  há 3 dias".
- **Ações em massa**: mandar aviso para todos, criar desafio, abrir
  temporada, aplicar o mesmo treino base a uma turma.
- **Resumo semanal por aluno** (gerado por IA): adesão ao treino, adesão
  à dieta, peso, humor, dor relatada, o que revisar. Ela lê 20 resumos em
  10 minutos em vez de abrir 20 conversas.
- **Métricas do negócio**: alunos ativos, churn, receita mensal
  recorrente, ticket médio, indicações no mês, alunos em risco.

### Pilar 2 — Upload de PDF/Word que vira dado estruturado

O fluxo central pedido: ela sobe o arquivo, o app extrai e organiza.

**Fluxo proposto**

1. Ela escolhe o aluno, o tipo (treino / dieta / macros / avaliação /
   outro) e envia o `.pdf` ou `.docx` (também foto de folha ou texto
   colado).
2. Uma Cloud Function extrai o texto:
   - PDF com texto: `pdf-parse`.
   - PDF escaneado / foto: OCR (Google Cloud Vision) ou enviar o PDF
     direto ao modelo, que lê imagem e texto.
   - Word: `mammoth` (`.docx` → texto/HTML).
3. O texto (ou o PDF em base64) vai para o Claude (`claude-opus-5`, SDK
   `@anthropic-ai/sdk`, já em TypeScript como as functions atuais) com
   **structured outputs** (`output_config.format`), pedindo um JSON num
   esquema fixo:
   - **Treino**: dias → exercícios → séries, repetições, carga sugerida,
     descanso, técnica (drop-set, rest-pause), observações, vídeo de
     referência (por nome do exercício).
   - **Dieta**: refeições → alimentos, quantidade, unidade, substituições,
     horários, observações.
   - **Macros**: kcal, proteína, carboidrato, gordura, fibra, água, por
     dia ou por tipo de dia (treino/descanso).
   - **Avaliação física**: peso, % gordura, perímetros, dobras, protocolo.
   - Cada campo vem com `confidence`; campos incertos são marcados.
4. **Tela de revisão**: ela vê o resultado lado a lado com o arquivo
   original, corrige o que quiser, e só então **publica** para o aluno.
   Nada chega ao aluno sem ela aprovar.
5. O plano é salvo **versionado** (`plans/{planId}/versions/{n}`) com o
   arquivo original anexado. O aluno vê a versão atual; o histórico
   permanece para comparar ciclos.
6. Notificação para o aluno: "Seu novo treino chegou 🔥".

**Detalhes que fazem diferença**

- Biblioteca de exercícios dela (nome, grupo muscular, vídeo curto dela
  executando, dicas). O parser tenta casar o nome do exercício do PDF com
  a biblioteca; o que não casar ela vincula uma vez e o app aprende
  (tabela de sinônimos).
- Templates: um PDF já revisado pode virar template para aplicar a
  outros alunos com ajuste de cargas.
- Importar também planilhas (`.xlsx`/`.csv`) e texto colado do WhatsApp.
- Exportar de volta em PDF com a marca dela (o aluno recebe um documento
  bonito, e ela deixa de fazer isso à mão).

### Pilar 3 — O dia a dia do aluno (treino + nutrição)

**Treino**

- **Treino do dia** na home: qual ficha, quantos exercícios, tempo
  estimado, botão grande "Começar".
- Modo execução: um exercício por vez, séries com carga/reps/RPE
  editáveis, timer de descanso com vibração, vídeo do exercício, campo
  "trocar exercício" (lista de substitutos aprovada por ela).
- Registro de treino = check-in automático (conta para streak, XP,
  desafios). Anti-fraude: treino com menos de X minutos ou sem nenhuma
  série registrada não pontua.
- **PRs automáticos** (1RM estimado por Epley) → post no feed + card
  compartilhável.
- Progressão sugerida: "Semana passada você fez 3x10 com 40 kg com
  RPE 7. Tente 42,5 kg hoje". Ela liga/desliga por aluno.
- Treino em casa / viagem: versão sem equipamento gerada a partir do
  plano (com aprovação dela).
- Modo offline: o treino do dia fica em cache (Hive já está no projeto).
- Histórico por exercício com gráfico de carga × tempo.

**Nutrição**

- Dieta por refeição, com horário e lembrete opcional.
- Marcar refeição como feita / trocada / pulada → **adesão à dieta**
  (percentual semanal, entra no ranking de consistência).
- Diário por foto (o aluno fotografa o prato; ela vê no painel; opcional
  IA estimar macros com aviso de que é estimativa).
- Metas de macros do dia com anel de progresso; entrada rápida de
  alimentos (tabela TACO, base brasileira).
- Água: meta diária, lembretes, contador no widget.
- Lista de substituições dela ("pode trocar arroz por batata-doce
  nas quantidades X").
- Lista de compras semanal gerada a partir da dieta.

### Pilar 4 — Marcos e evolução (o que ela quer "ir atualizando")

- **Linha do tempo do aluno**: cada medida, foto, PR, conquista, troca de
  plano e recado dela vira um ponto na jornada.
- **Metas com marcos**: meta principal (ex.: -8 kg, ou agachar 100 kg)
  quebrada em marcos; cada marco batido gera celebração + card.
- **Avaliação física periódica** com protocolo escolhido (perímetros,
  dobras Pollock 3/7, bioimpedância digitada), agendada a cada N semanas,
  com lembrete para os dois.
- **Comparador de fotos** antes/depois com slider, mesma pose, mesma luz
  (guia de enquadramento na câmera).
- **Relatório mensal em PDF** com a marca dela (peso, medidas, adesão,
  PRs, ranking) — o aluno mostra para os amigos; isso é marketing.
- **Recap de temporada** estilo "retrospectiva": treinos feitos, kg
  levantados no total, streak máximo, posição final. Altamente
  compartilhável.
- Ela pode **lançar dados pelo aluno** (avaliação presencial) e o app
  registra como "medido pela treinadora" (peso maior no cálculo de
  evolução do que autodeclarado).

### Pilar 5 — Competição adaptada à comunidade dela

O que já existe (rankings, desafios, campeonatos, temporadas, XP,
níveis, conquistas, recompensas) continua. Ajustes:

- **Ranking por consistência** como principal (treinos feitos ÷ treinos
  prescritos, adesão à dieta, check-ins semanais). Isso é justo entre
  quem treina 3× e quem treina 6× por semana.
- **Ligas** (Bronze / Prata / Ouro / Elite) por faixa de pontuação, com
  promoção e rebaixamento por temporada. Iniciantes competem entre si e
  não desanimam.
- **Desafios de equipe**: ela divide a comunidade em times (ou por
  cidade), pontuação coletiva; gera pertencimento e cobrança positiva.
- **Desafios abertos ao público** (não alunos podem entrar em versão
  limitada) como isca; alunos pagantes têm bônus e prêmios.
- **Campeonato do método** (ex.: "Copa [Nome]") trimestral com prêmios
  físicos e um "Hall da Fama" público.
- **Duelos 1×1**: desafiar um amigo por uma semana (quem treina mais dias).
- **Conquistas com a identidade dela**: nomes de badges que só existem no
  método, evolução visual do avatar/anel por nível.
- **Transformação do mês**: votação da comunidade entre fotos (com
  consentimento), prêmio + destaque no perfil público.

### Pilar 6 — Máquina de marketing e desejo

O ponto que diferencia este app de um "app de treino".

**Marca em tudo (white-label)**

- Nome do método, logo, paleta, tipografia, splash, ícone, e-mails e
  PDFs com a marca dela. O aluno nunca vê "GymRank".
- Tom de voz configurável nas notificações (ela grava frases).

**Cada marco vira conteúdo**

- **Cards compartilháveis** em formato Stories (9:16) e feed (1:1):
  PR batido, streak de 30 dias, subiu de liga, top 3 da semana,
  antes/depois, recap mensal. Sempre com logo + @ dela + link/QR para a
  página de captação.
- Botão "compartilhar no Instagram" direto (share sheet) com a imagem
  já renderizada.
- Ela recebe no painel a lista de cards compartilhados na semana para
  repostar.

**Programa de indicação**

- Cada aluno tem link/código. Indicado que assina gera recompensa para
  os dois (semana grátis, camiseta, pontos de ranking).
- Ranking de embaixadores; top embaixadores ganham bônus/comissão ou
  vaga em evento presencial.

**Página pública da treinadora (landing)**

- Galeria de transformações (consentidas), contador ao vivo ("1.240
  treinos concluídos essa semana"), depoimentos coletados no app,
  método explicado, planos e preços, **lista de espera com posição
  visível** e formulário de aplicação ("me conte seu objetivo").
- Perfil público opcional do aluno (nível, liga, conquistas) — status
  social dentro da comunidade.

**Exclusividade e escassez (desejo)**

- Entrada por **turmas/cohorts** ("Turma de Novembro", vagas limitadas),
  com data de abertura e fechamento anunciada no app e na landing.
- Tier **Elite** com vagas contadas: acompanhamento mais próximo,
  chamada mensal, kit físico. Visível para os demais como objetivo.
- Recompensas físicas só para quem atinge (camiseta que ninguém compra,
  só ganha) → gente usa na academia e pergunta de onde é.

**Conteúdo e comunidade aberta (funil)**

- Área gratuita: vídeos curtos dela, dica da semana, desafio aberto,
  calculadoras (TMB, macros). Quem entra grátis vê o que os alunos
  têm e é convidado para a lista de espera.
- Notícias/anúncios dela dentro do app (substitui o "lista de
  transmissão" do WhatsApp).

**Depoimentos automáticos**

- Ao bater um marco relevante, o app pergunta: "Quer deixar um
  depoimento?" (texto ou vídeo de 30 s). Vai para a fila de aprovação
  dela e depois para a landing.

---

## 4. Brainstorm por área (lista extensa)

### 4.1 Comunicação e relacionamento

- Chat 1:1 aluno ↔ treinadora, com áudio, foto, vídeo; respostas rápidas
  salvas; horário de atendimento visível (protege o tempo dela).
- **Check-in semanal** (formulário curto configurável): peso, sono,
  estresse, dores, adesão, humor, foto opcional. Sem responder = alerta.
- **Feedback de execução**: aluno grava vídeo do exercício, ela comenta
  com marcação de tempo ("aos 0:12 o joelho entra").
- Avisos em massa segmentados (só alunas do time X, só quem tem treino
  de perna hoje).
- Push inteligente: lembrete de treino no horário que o aluno costuma
  treinar; "seu amigo te ultrapassou"; "faltam 2 treinos para o marco".
- Mensagens automáticas de aniversário, 30 dias de aluno, fim de ciclo.

### 4.2 Comunidade

- Feed (já existe) com reações, comentários, shoutout dela (destaque
  amarelo no post).
- Grupos/turmas com feed próprio.
- Agenda de aulas ao vivo (link Zoom/Meet/YouTube), lembrete e presença
  contabilizada.
- Eventos presenciais (treinão, corrida) com inscrição e check-in por
  QR (o QR já existe no projeto).
- Mural de dúvidas com respostas dela fixadas (FAQ vivo).

### 4.3 Financeiro e negócio

- Planos: mensal, trimestral, semestral; online / presencial / híbrido;
  add-ons (avaliação extra, consulta).
- Pagamento (México): cartão recorrente, SPEI, OXXO Pay e Mercado Pago
  — via Stripe MX, Conekta ou Mercado Pago. Cupons, período de teste,
  cobrança automática, aviso de inadimplência, bloqueio suave (vê o app,
  não recebe treino novo). Preços em MXN.
- Contratos e termos aceitos no app (com registro de data/IP).
- Nota fiscal (integração futura).
- Relatório financeiro no painel.

### 4.4 Saúde, hábitos e wearables

- Health Connect (Android) / HealthKit (iOS): passos, sono, frequência
  cardíaca, calorias, treinos de relógio (Garmin/Apple Watch/Samsung).
  Passos e sono entram em desafios ("10 mil passos por 7 dias").
- **Habit tracker** configurável por ela: água, sono 7 h, 10 mil passos,
  alongamento, sem álcool na semana. Cada hábito soma pontos.
- Humor e energia diários (1 toque) → gráfico correlacionado com treino.
- Ciclo menstrual (opt-in) para ajustar expectativa de carga e explicar
  variações de peso.
- Diário de dor/lesão com mapa corporal → alerta para ela.
- Lembrete de mobilidade/alongamento com vídeos curtos.

### 4.5 IA (a pasta `coach_ai` do README, ainda não implementada)

- Parser de documentos (Pilar 2).
- Resumo semanal por aluno para a treinadora.
- **Assistente do aluno com limites**: responde dúvidas sobre o próprio
  plano ("posso trocar frango por ovo?") usando só as regras de
  substituição que ela cadastrou; fora disso, encaminha para ela.
- Detecção de risco de abandono (queda de adesão, sem abrir o app,
  humor baixo) → sugestão de ação ("mande um áudio para Ana").
- Geração de legenda para os cards compartilháveis e para os posts dela.
- Sugestão de progressão de carga (com aprovação).
- Transcrição dos áudios do chat para ela ler rápido.

### 4.6 Avaliações e protocolos

- Anamnese e PAR-Q digitais na entrada.
- Protocolos de dobras (Pollock 3/7, Guedes), perímetros, bioimpedância,
  testes de força (1RM estimado), flexibilidade, postura por foto com
  grade.
- Reavaliação agendada com comparativo automático e gráfico.

### 4.7 Escala: de região a país

- **Multi-coach sob a mesma marca**: quando ela quiser licenciar o
  método, outros treinadores entram como `coach` dentro da organização
  dela (`orgs/{orgId}/coaches/{coachId}`), cada um com seus alunos.
  Rankings e campeonatos nacionais cruzam todos; ela vê tudo.
- Regiões/cidades como escopo de ranking (já existe `cidade`).
- Conteúdo em vídeo escalável (biblioteca dela substitui presença).
- Fuso horário por aluno.
- Web app completo (Flutter Web já compila; o preview no Render prova).
- Internacionalização preparada (pt-BR primeiro).

### 4.8 Jurídico, privacidade e segurança

- **LGPD**: consentimento explícito para fotos, para uso em marketing
  (separado!), exportação e exclusão de dados, política de privacidade.
- **Prescrição de dieta é ato de nutrióloga(o)** também no México
  (cédula profissional; a Ley General de Salud e as NOMs de nutrição
  tratam o tema). Como já existe nutrióloga parceira, o app **organiza e
  acompanha** a dieta que ela envia (perfil `nutriologo` com acesso à
  parte alimentar) e a treinadora orienta hábitos e metas gerais. Vale
  confirmar o enquadramento com a própria nutrióloga, mas o papel já
  está modelado.
- Fotos de progresso privadas por padrão; público só com opt-in por
  foto.
- Regras do Storage para PDFs/Word: leitura só pela treinadora e pelo
  aluno dono; limite de tamanho; verificação de tipo MIME.
- Termos de uso com aviso de que treino tem risco e exige liberação
  médica quando indicado (PAR-Q).

### 4.9 Pequenos detalhes que encantam

- Widget de tela inicial com treino do dia e streak.
- Modo "não perturbe" de ranking para quem não quer competir (mas
  continua com metas pessoais).
- Sons e vibração ao concluir série/treino (desligáveis).
- Contagem regressiva para o próximo campeonato na home.
- Apple Watch / Wear OS: iniciar treino e marcar séries pelo pulso.
- Exportar dados (CSV) e importar histórico de Hevy/Strong (enums já
  existem).
- Tema com a paleta dela; modo claro/escuro.

---

## 5. Priorização sugerida

### MVP (8–10 semanas de foco): o que ela precisa para operar amanhã

1. Papel `coach` + painel web/mobile com lista de alunos e ficha.
2. Convite de aluno por link/código; vínculo aluno ↔ treinadora.
3. **Upload PDF/Word → revisão → publicação** de treino, dieta e macros
   (Pilar 2), com arquivo original sempre acessível.
4. Treino do dia com execução série a série; conclusão = check-in.
5. Dieta por refeição + macros do dia + marcar refeição feita.
6. Medidas, fotos e PRs (já existem) + linha do tempo do aluno.
7. Rankings por consistência + XP, ligas simples, streak, desafios
   (reaproveitar) restritos à comunidade dela.
8. Chat 1:1 + check-in semanal.
9. Marca dela em todo o app (white-label básico) + **cards
   compartilháveis** de PR, streak e ranking.
10. Pagamento recorrente (um provedor) e status de mensalidade no painel.

### Fase 2: crescimento

- Programa de indicação, landing pública com lista de espera e
  depoimentos, turmas/cohorts, campeonato do método com prêmios,
  desafios de equipe, relatório mensal em PDF, recap de temporada,
  hábitos, Health Connect/HealthKit, resumo semanal por IA, feedback de
  vídeo, biblioteca de vídeos dela, perfil de nutricionista.

### Fase 3: escala

- Multi-coach / licenciamento do método, ranking nacional, assistente
  IA do aluno, detecção de churn, aulas ao vivo, eventos, watch apps,
  marketplace de recompensas, internacionalização.

---

## 6. Impacto técnico no código atual

**Reaproveita como está**: auth, perfil, medidas corporais, fotos de
progresso, XP/nível/streak/conquistas, rankings materializados,
desafios, campeonatos, temporadas, recompensas, feed, amizades,
notificações, tema, router, DI, demo mode, deploy no Render.

**Renomeia/generaliza**: `gyms` → `coaches` (ou `orgs`), `gym_admin` →
`coach_panel`, `isGymStaffOf` → `isCoachOf`, `GymDashboardStats` →
`CoachDashboardStats` (troca check-ins por treinos concluídos e adesão).

**Cria**:

| Coleção | Para quê |
|---|---|
| `coaches/{coachId}` | marca, método, cores, links, planos de preço, configurações |
| `coaches/{coachId}/clients/{userId}` | vínculo, status, plano contratado, datas, notas privadas, tags |
| `documents/{docId}` | arquivo enviado (Storage path), tipo, status do parse, resultado bruto, versão de plano gerada |
| `plans/{planId}` + `versions/{n}` | treino / dieta / macros estruturados, versionados, com `sourceDocumentId` |
| `exercises/{exerciseId}` | biblioteca da treinadora (nome, grupo, vídeo, sinônimos) |
| `workout_sessions/{sessionId}` | execução: exercícios, séries, cargas, reps, RPE, duração, `planVersionId` |
| `meal_logs/{logId}` | refeição feita/trocada/pulada, foto, macros estimados |
| `checkin_forms/{formId}` | respostas do check-in semanal |
| `conversations/{id}/messages/{id}` | chat |
| `habits/{habitId}` + `habit_logs` | hábitos configuráveis |
| `subscriptions/{id}` + `payments/{id}` | assinatura e cobranças (espelho do provedor) |
| `referrals/{code}` | indicações e recompensas |
| `share_cards/{cardId}` | cards gerados (imagem no Storage) para métricas de compartilhamento |
| `testimonials/{id}` | depoimentos com status de aprovação |
| `leagues/{seasonId}/{tier}` | ligas por temporada |

**Cloud Functions novas**: `parseDocument` (extração + Claude + JSON
validado), `publishPlanVersion`, `onWorkoutSessionCompleted` (XP,
streak, desafios, PR, card), `computeAdherence` (diário),
`weeklyCoachDigest` (IA), `renderShareCard` (imagem 9:16 e 1:1 via
canvas no Node), `paymentWebhook`, `churnRiskScore`, `leaguePromotion`
(fim de temporada).

**Storage rules novas**: `documents/{coachId}/{userId}/{file}` com
leitura apenas para o aluno dono e para a treinadora, tipos permitidos
`application/pdf`, `.docx`, imagens; limite 20 MB.

**Firestore rules**: `isCoachOf(userId)` consulta o vínculo em
`coaches/{coachId}/clients/{userId}`; planos e documentos legíveis só
por aluno dono, treinadora e nutricionista vinculada.

---

## 7. Perguntas para decidir com ela

1. **Nome do método e da marca** (define domínio, ícone, paleta).
2. Ela atende **só online, só presencial ou híbrido** hoje? Quantos
   alunos ativos? Como envia treino hoje (PDF pelo WhatsApp?).
3. Quem faz a **dieta**: ela, uma nutricionista parceira, ou o aluno traz
   a dele? (Define o perfil `nutricionista` e o texto legal.)
4. **Modelo de preço**: mensal? trimestral com desconto? tiers
   (Básico / Elite)? Presencial como add-on?
5. Qual **métrica ela quer no topo do ranking**: consistência, evolução
   corporal, força, ou uma pontuação mista (o Gym Score já é misto)?
6. Prêmios que ela consegue entregar de verdade no primeiro campeonato
   (camiseta, sessão presencial, kit).
7. Ela topa uma **lista de espera / turmas** desde o início, ou quer
   entrada aberta?
8. ~~Plataforma prioritária~~ **Respondido: celular (~80% do uso).**
   Android + iOS primeiro; o painel dela também é pensado para o
   celular. Web fica como bônus para o dia em que ela quiser uma tela
   grande.
9. Quais **cards** ela mais quer ver circulando: antes/depois, PR,
   streak, ranking?
10. Que dados dos alunos ela já tem em PDF/Word para servir de amostra
    para calibrar o parser.

---

## 8. Próximos passos sugeridos

1. Fechar as respostas do item 7 (30 min de conversa com ela).
2. Coletar 5 a 10 PDFs/Word reais de treino e dieta dela para montar o
   esquema JSON e testar o parser antes de qualquer tela.
3. Renomear o núcleo (`gyms` → `coaches`) e criar o papel `coach` com o
   painel básico.
4. Implementar o pipeline de upload → revisão → publicação.
5. Treino do dia com execução e conclusão como check-in.
6. Cards compartilháveis com a marca (primeira alavanca de marketing).
7. Pagamento recorrente.
