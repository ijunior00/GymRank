# Setup do Firebase, do zero

Sem isto o app real não sobe: `lib/main.dart` só inicia com um projeto
Firebase configurado. (O preview do Render é `lib/main_demo.dart`, que
roda com dados falsos justamente para não depender disto.)

Tempo: ~40 min na primeira vez. Faça na sua máquina, não no celular dela.

---

## 0. Antes de começar: o plano Blaze

**O plano gratuito (Spark) não serve para este app.** Cloud Functions v2 e
Storage exigem faturamento ativo. Você precisa de um cartão no projeto —
mas o consumo real, com 50 alunas, fica dentro da cota gratuita: na
prática **US$ 0 a 5 por mês**.

O que sai do bolso de verdade é a API da Anthropic, que lê os PDFs da
nutrióloga. É por uso e cobrada à parte, fora do Firebase.

Coloque um **orçamento com alerta** (Google Cloud Console → Billing →
Budgets & alerts) em, digamos, US$ 20/mês. Não trava nada, mas te avisa
por e-mail se algo disparar.

---

## 1. Criar o projeto

1. [console.firebase.google.com](https://console.firebase.google.com) →
   **Adicionar projeto**.
2. Nome: `gymrank` (o nosso é `gymrank-e1c0d`). O ID gerado é permanente.
3. **Google Analytics: ative.** O app já depende de `firebase_analytics`.
4. Criado o projeto: engrenagem → **Uso e faturamento** → mudar para
   **Blaze**.

## 2. Ligar os serviços no console

Nesta ordem:

**Authentication** → Começar → aba *Sign-in method*, ative os três:
- Email/senha
- Google
- Apple *(obrigatório na App Store porque oferecemos Google; no Android
  não atrapalha)*

**Firestore Database** → Criar banco → **modo de produção** → localização
**`nam5` (United States)`**.

> ⚠️ **A localização do Firestore não pode ser mudada depois.** Mudar
> significa projeto novo e migrar tudo. `nam5` é multi-região nos EUA: é
> onde as Cloud Functions rodam (`us-central1`) e a melhor latência para
> o México entre as opções com todos os recursos.

**Storage** → Começar → **"Ubicación sin costo"** → **`US-CENTRAL1`**.

> ⚠️ O Storage **não oferece `nam5`** — Firestore e Cloud Storage usam
> listas de localização diferentes, então não tente casar os nomes.
> Escolha `US-CENTRAL1` por dois motivos:
>
> - as opções "sin costo" (US-CENTRAL1/EAST1/WEST1) entram na cota
>   gratuita de 5 GB; as multi-regionais (`US`, `NAM4`) não;
> - `us-central1` é onde as Cloud Functions rodam, e a `parseDocument`
>   baixa do Storage o PDF que vai para o Claude. Mesma região = leitura
>   local, sem tráfego (nem custo) entre regiões.
>
> Como a do Firestore, esta localização é permanente.

**Cloud Messaging** — já vem ligado, nada a clicar aqui. (O iOS ainda
precisa da chave APNs, no passo 7.)

## 3. Instalar as ferramentas

```bash
npm install -g firebase-tools
firebase login

dart pub global activate flutterfire_cli
# se o comando `flutterfire` não for encontrado, adicione ao PATH:
export PATH="$PATH:$HOME/.pub-cache/bin"
```

## 4. Conectar o repo ao projeto

O projeto já está apontado no `.firebaserc` versionado:

```json
{ "projects": { "default": "gymrank-e1c0d" } }
```

Ou seja, `firebase use --add` não é necessário, e nenhum `firebase deploy`
vai parar no projeto errado por engano. (O ID do projeto é público — o que
tem chave é o `firebase_options.dart`, esse sim fora do git.)

Na raiz do repositório:

```bash
flutterfire configure \
  --project=gymrank-e1c0d \
  --platforms=android,ios \
  --android-package-name=com.anahifitness.app \
  --ios-bundle-id=com.anahifitness.app
```

Acrescente `,web` à lista quando for ligar o PWA (ver
`docs/setup-web-pwa.md`).

Isto gera de uma vez os três arquivos que **não** estão no git (são por
projeto e um deles carrega chaves):

- `lib/firebase_options.dart` — some os 2 erros que o `flutter analyze`
  mostra hoje
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

E adiciona o plugin `com.google.gms.google-services` ao Gradle. É por
isso que ele **não** está declarado à mão em
`android/app/build.gradle.kts`: sem o JSON ao lado, ele quebra a
compilação. Deixe o `flutterfire` colocar os dois juntos.

## 5. Subir regras, índices e functions

```bash
firebase deploy --only firestore:rules,firestore:indexes,storage:rules

cd functions
npm install
firebase functions:secrets:set ANTHROPIC_API_KEY   # cola a chave quando pedir
firebase deploy --only functions
cd ..
```

O primeiro `deploy --only functions` demora (5–10 min) e pede para
ativar algumas APIs do Google Cloud — aceite.

As 13 functions vão todas para `us-central1`, fixado em
`functions/src/constants.ts`. **Se algum dia mudar de região, mude também
`AppConstants.functionsRegion`** em `lib/core/constants/app_constants.dart`:
se as duas divergirem, o check-in por QR volta `NOT_FOUND` — a função
existe, mas o app procura no lugar errado.

## 6. Google Sign-In no Android precisa do SHA-1

Esse é o passo que todo mundo esquece e depois passa a tarde achando que
o login com Google está quebrado. Ele **não funciona** sem as impressões
digitais registradas.

```bash
cd android && ./gradlew signingReport
```

Pegue o **SHA-1** e o **SHA-256** da variante `debug` e cole em:
Console → engrenagem → Configurações do projeto → seu app Android →
**Adicionar impressão digital**.

Quando for publicar, repita com a chave de release (a do
`android/key.properties`, ver `docs/setup-movil.md`) **e** com a chave que
o Google Play gera se você usar Play App Signing — são diferentes.

Depois de adicionar, baixe o `google-services.json` de novo (ou rode
`flutterfire configure` outra vez).

## 7. Push no iPhone precisa da chave APNs

Só se aplica ao iOS, e exige a conta paga da Apple.

1. [developer.apple.com](https://developer.apple.com/account/resources/authkeys)
   → Keys → **+** → marque **Apple Push Notifications service (APNs)** →
   baixe o `.p8` (só dá para baixar **uma vez**, guarde bem).
2. Console do Firebase → Configurações do projeto → **Cloud Messaging** →
   *Apple app configuration* → suba o `.p8`, com o **Key ID** e o
   **Team ID**.

Sem isso o app iOS compila e roda, mas nunca recebe notificação.

## 8. Transformar a conta dela em coach

O app não deixa ninguém virar coach sozinho (a regra do Firestore só
aceita `role: 'alumno'` no cadastro). É de propósito.

1. Ela cria a conta normalmente pelo app.
2. Console → Firestore → coleção `users` → documento dela (o ID é o uid;
   confira pelo e-mail) → campo `role`: troque `alumno` por `coach`.
3. Ela fecha e reabre o app: cai na tela de configurar a marca, escolhe
   nome do método, cor e gera o código de convite.
4. As alunas usam esse código no cadastro.

Para a nutrióloga é igual, com `role: 'nutriologo'` **mais** o campo
`coachId` apontando para o id da coach (o mesmo que aparece em
`users/{uid-dela}.coachId` depois do passo 3).

## 9. Conferir se ficou de pé

```bash
flutter analyze     # tem de ficar limpo agora — os 2 erros somem
flutter run         # o app real, com Firebase
```

Roteiro rápido de teste:

1. Criar conta de aluna → entra e vê a home.
2. Login com Google → se falhar, é o SHA-1 do passo 6.
3. Com a conta coach: subir um PDF na ficha de uma aluna → o documento
   deve sair de `subido` para `listo` em ~30 s. Se ficar em `error`, veja
   `firebase functions:log --only parseDocument` (quase sempre é a chave
   da Anthropic).
4. Publicar o plano → a aluna vê em "Mis planes" e recebe notificação.
5. Concluir um treino → confere XP, sequência e recorde no resumo.

## 10. O que nunca vai para o git

Já está tudo no `.gitignore`, mas para você saber o que faz backup à
parte:

```
lib/firebase_options.dart
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
android/key.properties  +  o .jks  (ver docs/setup-movil.md)
a chave .p8 do APNs
```

(O `.firebaserc` **é** versionado — só tem o ID do projeto, que é
público, e mantê-lo no repo evita um `firebase deploy` no projeto
errado.)

Perder o `.jks` ou o `.p8` dá trabalho de verdade: o `.jks` significa não
conseguir mais atualizar o app na Play Store. Guarde fora do computador.
