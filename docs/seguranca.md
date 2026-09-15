# Segurança: o que protege o app e o que você liga no console

Este é o mapa do que impede alguém de ver dados de outra aluna, inflar o
ranking ou gerar conta de Firebase para a gente. Está em duas partes: o
que já vem no código (basta fazer o deploy) e o que só existe se você
ligar no console do Firebase.

## Por que não existe "rate limit por IP"

No Firebase não há uma tela de limite por IP para Firestore, Storage ou
Hosting. O que existe em vez disso, e é o que este projeto usa:

| Ameaça | O que segura |
|---|---|
| Ataque de volume (DDoS) no site | A infraestrutura do Google, na frente do Hosting. Nada a configurar. |
| Tentar senha em massa | O Firebase Auth bloqueia sozinho por IP e por conta (`too-many-requests`). |
| Script ou bot falando direto com o banco | **App Check** (seção abaixo): só o app de verdade recebe resposta. |
| Uma conta tentando ler o que não é dela | Regras do Firestore e do Storage (`firestore.rules`, `storage.rules`). |
| Inflar XP / ranking | Só Cloud Functions escrevem XP, com teto por dia/semana (`XP_LIMITS` em `functions/src/constants.ts`). |
| Conta de Functions estourar | `maxInstances: 10` em `functions/src/index.ts` + alerta de orçamento (abaixo). |

## O que já está no código

**Quem lê o quê**

- Perfil completo (`users/{uid}`: nascimento, sexo, altura, cidade, quem
  indicou): só a própria pessoa e o staff da comunidade dela. O resto do
  app usa o cartão público `public_profiles/{uid}` (nome, @, foto,
  nível), espelhado pela function `onUserWritten`.
- Treinos, medidas e fotos de evolução: só a dona e o staff da
  comunidade dela — no Firestore e nos arquivos do Storage.
- Documentos, planos, refeições, notas privadas, notificações: dona e/ou
  staff, como antes.
- Segredo do QR de check-in: `coaches/{id}/private/qr`, que ninguém lê
  pelo app. A coach gera o QR pela function `issueCheckInToken`.

**O que o app não consegue escrever**

- XP, nível, sequência, Gym Score, papel, plano, `referralCount`,
  contadores de curtidas/comentários, check-ins, `xp_ledger`.
- Treino com data de mais de 2 dias atrás, com mais de 600 minutos, ou
  com `sessionId` (carimbo do servidor). Medida com mais de 7 dias ou
  peso fora de 20–400 kg. Foto apontando para fora da pasta da própria
  aluna. Sessão de treino cujo início/fim não seja "agora".
- Texto de post acima de 1000 caracteres; comentário acima de 500.
- Imagem de prêmio (só a coach dona do prêmio, até 5 MB).

**Teto de XP** (por pessoa, fuso da Cidade do México)

| Fonte | Vale XP até |
|---|---|
| Treino registrado ou sessão concluída | 1 por dia |
| Check-in por QR | 2 por dia (e nunca duas vezes em 6 h) |
| Medida corporal | 1 por semana |
| Foto de evolução | 1 por dia |
| Amizade aceita + indicação | 3 por semana, somadas |

O que passa do teto continua registrado; só não pontua.

**Testado**: `firestore.rules` tem uma bateria de mais de 70 casos rodada
contra o emulador (leituras cruzadas, datas, tamanhos, segredo do QR,
perfil x cartão público). Está em `test_rules/` com o passo a passo para
rodar; rode sempre que mexer nas regras. As regras do Storage foram
revisadas à mão: o emulador daqui não consegue fazer a consulta cruzada
ao Firestore que elas usam, mas é a mesma consulta que já protege o
upload de documentos em produção.

## Deploy do que mudou

No PowerShell, na pasta do projeto:

```powershell
firebase deploy --only firestore:rules,storage,functions
```

As functions novas: `issueCheckInToken`, `onLikeWritten`,
`onCommentCreated`, `onUserWritten`. Se alguma falhar na primeira vez
(Eventarc), espere 5 minutos e repita o mesmo comando.

Depois do deploy, o cartão público das contas que já existem aparece na
próxima rodada de `recalculateRankings` (roda a cada hora). Até lá a
busca por @ e a lista de amigas dessas contas ficam vazias.

## O que você liga no console (uma vez)

### 1. App Check — o mais importante

É o que impede um script com a chave pública do app de falar com o banco.

1. Console do Firebase → **App Check** → aba **Apps** → no app **Web**,
   clique em **Registrar** → escolha **reCAPTCHA v3** → **Salvar**. Ele
   mostra uma **chave do site** (site key), um texto longo.
2. Abra `dart_defines.json` no VS Code e cole essa chave em
   `APP_CHECK_RECAPTCHA_SITE_KEY`. Salve.
3. Publique de novo: `firebase deploy --only hosting`.
4. Use o app normalmente por um ou dois dias. Em App Check → aba
   **APIs**, cada serviço mostra a porcentagem de pedidos **verificados**.
5. Quando Firestore, Storage e Functions mostrarem perto de 100 %
   verificados, clique em **Aplicar** (Enforce) em cada um. A partir daí
   pedidos sem comprovante são recusados.

Não aplique antes de ver as métricas: quem estiver com uma versão antiga
do app aberta seria bloqueado. E antes de publicar nas lojas, registre
também os apps Android (Play Integrity) e iOS (App Attest) na mesma
aba — o código já ativa os dois provedores.

Para rodar `flutter run` com App Check aplicado, o provedor de debug
imprime um token no console; registre-o em App Check → Apps → menu ⋮ →
**Gerenciar tokens de depuração**.

### 2. Authentication → Settings

- **Proteção contra enumeração de e-mail**: ligada.
- **Política de senha**: mínimo 8 caracteres (o app já recusa menos de 6
  pela mensagem do Firebase; aqui você aperta).
- **Domínios autorizados**: só `localhost`, `gymrank-e1c0d.web.app`,
  `gymrank-e1c0d.firebaseapp.com` e o domínio próprio quando existir.
- Em **Sign-in method**, deixe **Telefone desativado**: o app não usa, e
  SMS aberto é alvo de fraude que gera conta de celular alta.

### 3. Alerta de orçamento (Google Cloud)

Blaze não tem teto de gasto; o alerta é o aviso.

1. [console.cloud.google.com](https://console.cloud.google.com) → projeto
   `gymrank-e1c0d` → **Faturamento** → **Orçamentos e alertas** → **Criar
   orçamento**.
2. Valor mensal que faz sentido (por exemplo 20 USD), alertas em 50 %,
   90 % e 100 %, e-mail para você. Salvar.

### 4. Opcional: restringir a chave de API web

Console do Google Cloud → **APIs e serviços** → **Credenciais** → a chave
"Browser key (auto created by Firebase)" → **Restrições de aplicativo** →
**Sites** → adicione `gymrank-e1c0d.web.app/*`,
`gymrank-e1c0d.firebaseapp.com/*` e `localhost/*`. Só faça depois de o
App Check estar aplicado e o app estável; se algo parar de logar, é aqui
que se desfaz.

## Como conferir que está fechado

1. Entre com uma conta de aluna e abra o feed, o ranking e a busca de
   amigas: tudo continua funcionando.
2. Com a mesma conta, no console do Firestore, tente abrir
   `progress_photos` de outra pessoa pelo app não dá; pelo console você
   é admin e vê tudo, isso é esperado.
3. Registre dois treinos no mesmo dia: o segundo aparece na lista, mas o
   XP só sobe uma vez.
4. Em App Check → APIs, a porcentagem de verificados sobe conforme as
   pessoas atualizam o app.
