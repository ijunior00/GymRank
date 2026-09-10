# Web e PWA

O mesmo código Flutter que vira app na Play Store e na App Store roda no
navegador — e, com o manifesto que está em `web/`, instala na tela de
início como um app de verdade (ícone próprio, tela cheia, sem barra do
Safari/Chrome).

**Por que começar por aqui:** distribuição é um link. O marketing dela é
Instagram e WhatsApp; link na bio funciona hoje, sem revisão da Apple,
sem os 99 USD/ano e sem Mac.

---

## O que já está pronto

| | |
|---|---|
| `web/manifest.json` | nome, es-MX, `display: standalone`, retrato, cores `#0B0710`, ícones 192/512 + maskable |
| `web/index.html` | fundo escuro no primeiro paint (sem flash branco), tela de carregamento com a marca, `theme-color`, convite de instalação no iPhone |
| `web/firebase-messaging-sw.js` | service worker do push — **precisa ser preenchido**, ver abaixo |
| `scripts/render_build.sh` | build com `--no-web-resources-cdn` |

Verificado num Chromium real (iPhone 13 e Pixel 7 emulados): fundo escuro
imediato, o carregador some quando o app pinta, o convite de instalação
aparece só no iPhone e some de vez quando dispensado.

## O que falta, e é obrigatório

### 1. Buildar com `--no-web-resources-cdn`

```bash
flutter build web --release --no-web-resources-cdn -t lib/main.dart
```

Sem esta flag o CanvasKit (~5 MB, o motor que desenha a interface) é
buscado em `gstatic.com` **em tempo de execução**. Se esse CDN estiver
lento ou bloqueado, o app não renderiza — tela preta e nada mais. Com a
flag ele sai da mesma origem. Já está no `render_build.sh`.

### 2. Push no navegador

Três coisas, nesta ordem:

1. **Preencher `web/firebase-messaging-sw.js`.** Copie os valores do
   bloco `static const FirebaseOptions web` do `lib/firebase_options.dart`
   que o `flutterfire configure` gerou. Enquanto estiver com
   `PENDIENTE`, o service worker não inicializa nada e o app funciona
   normalmente, só sem push no navegador. (Esses valores não são
   segredo: a config web do Firebase é pública por natureza — quem
   protege os dados são as regras do Firestore.)

2. **Gerar a chave VAPID.** Console do Firebase → Configurações do
   projeto → Cloud Messaging → *Certificados push da Web* → gerar par de
   chaves.

3. **Passar a chave no build:**
   ```bash
   flutter build web --release --no-web-resources-cdn \
     --dart-define=FCM_VAPID_KEY=<a-chave-publica> \
     -t lib/main.dart
   ```
   Sem ela, `PushRegistration` sai fora sem tentar nada — no navegador
   `getToken()` lança sem a chave VAPID. O app roda igual, só sem push.

### 3. HTTPS

PWA, service worker e notificação só funcionam em HTTPS (ou
`localhost`). O Render já serve HTTPS.

---

## O iPhone é o caso chato

No iOS, **notificação web só chega para quem adicionou o app à tela de
início**. Quem abre o link e fica no Safari nunca recebe nada — e todo o
desenho de retenção (racha em risco, plano novo, recorde) depende disso.

Por isso o `index.html` mostra, só no iPhone e só fora do modo instalado,
um convite em espanhol: *"Agrega GymRank a tu pantalla de inicio…"*. Some
para sempre se a pessoa dispensar.

No Android o Chrome manda push sem instalar nada, e ainda oferece
instalar sozinho.

---

## Fonte: a decisão que ficou em aberto

No navegador o Flutter desenha o texto com a **Roboto buscada em
`fonts.gstatic.com`**. O `index.html` já faz `preconnect` para adiantar
DNS e TLS (~200–400 ms a menos de tela sem texto em rede móvel), mas a
dependência continua: **se essa requisição falhar, aparecem os ícones e
os cartões, e nenhum texto.**

Para independência total, dá para embutir a Roboto:

```yaml
# pubspec.yaml
  fonts:
    - family: Roboto
      fonts:
        - asset: assets/fonts/Roboto-Regular.ttf
        - asset: assets/fonts/Roboto-Medium.ttf
          weight: 500
        - asset: assets/fonts/Roboto-Bold.ttf
          weight: 700
        - asset: assets/fonts/Roboto-Black.ttf
          weight: 900
```

Os arquivos estão no próprio SDK
(`$FLUTTER_HOME/bin/cache/artifacts/material_fonts/`, Apache-2.0), e o
tema precisaria de `fontFamily: 'Roboto'`.

**Por que não foi feito:** são ~685 KB que entrariam **também no APK e no
IPA**, onde não servem para nada — Android e iOS já resolvem a fonte pelo
sistema. Vale a pena se as alunas treinarem em academia com sinal ruim, e
aí é melhor decidir de propósito.

---

## Deploy

O `render.yaml` hoje publica o **preview com dados falsos**
(`lib/main_demo.dart`) — serve para validar interface, não é o app.

Para publicar o app de verdade, troque o entrypoint no
`scripts/render_build.sh` para `lib/main.dart` e acrescente o
`--dart-define` da chave VAPID. Isso só funciona depois do
`flutterfire configure` (ver `docs/setup-firebase.md`): sem
`lib/firebase_options.dart` o build falha.

Vale manter os dois: o preview para mexer na interface sem risco, e o app
real em outro endereço.

## Como testar se ficou de pé

Servindo o `build/web` em HTTPS (ou `localhost`):

1. **Android/Chrome:** menu → *Instalar app*. Deve abrir sem barra do
   navegador, com o ícone certo e a barra de status escura.
2. **iPhone/Safari:** o convite aparece uns segundos depois de carregar.
   Compartilhar → *Agregar a inicio* → abrir pelo ícone.
3. **DevTools → Application → Manifest:** sem avisos.
4. **DevTools → Application → Service workers:**
   `firebase-messaging-sw.js` ativo (só depois do passo 2 acima).
5. **DevTools → Network, throttling em "Slow 3G":** o fundo escuro e o
   carregador têm de aparecer de imediato, não uma tela branca.
