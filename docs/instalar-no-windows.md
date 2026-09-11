# Instalar tudo no Windows, do zero

Guia para quem nunca programou. Cada passo diz **onde** fazer, **o que**
digitar e **como saber que deu certo**.

Reserve umas 2 horas na primeira vez. A maior parte é o computador
baixando coisas sozinho — você só espera.

> **Sobre o iPhone:** no Windows não dá para construir a versão de
> iPhone. É regra da Apple, não falta de programa. Android e web
> funcionam normalmente. Quando houver um Mac disponível, o mesmo código
> vira app de iPhone sem reescrever nada (ver `docs/setup-movil.md`).

---

## O que vamos instalar, e para quê

| Programa | Para que serve |
|---|---|
| **Git** | Baixa o código do projeto para o teu computador |
| **Flutter** | Transforma o código em app. É o principal |
| **Android Studio** | Traz as peças da Google para construir apps Android e testar num celular de mentira na tela |
| **Node.js** | Necessário para o comando `firebase` do próximo passo |

---

## Passo 0 — Abrir o Terminal

O Terminal é uma janela onde você digita comandos em vez de clicar.

1. Aperte a tecla **Windows**
2. Digite `powershell`
3. Clique em **Windows PowerShell**

Abre uma janela azul-escura com um texto tipo `PS C:\Users\SeuNome>`.
É aí que tudo acontece daqui para frente.

**Dica:** para colar algo no PowerShell, use **botão direito do mouse**
(Ctrl+V às vezes não funciona).

---

## Passo 1 — Ver o que você já tem

Cole este comando e aperte **Enter**:

```powershell
winget --version
```

`winget` é a "loja de programas por comando" que já vem no Windows. Ele
instala as coisas sem você precisar caçar site de download.

- **Apareceu um número** (ex.: `v1.8.1911`) → ótimo, siga para o Passo 2.
- **Deu erro** → abre a Microsoft Store, procura por **App Installer** e
  instala. Depois feche e abra o PowerShell de novo e repita.

---

## Passo 2 — Instalar Git e Node.js

São os dois menores. Um comando de cada vez, esperando terminar.

```powershell
winget install --id Git.Git -e
```

```powershell
winget install --id OpenJS.NodeJS.LTS -e
```

**Importante:** depois que os dois terminarem, **feche o PowerShell e
abra de novo**. Programas recém-instalados só aparecem em janelas novas.

Confira:

```powershell
git --version
node --version
```

Cada um deve responder um número. Se disser "não é reconhecido", feche e
abra o PowerShell mais uma vez.

---

## Passo 3 — Instalar o Android Studio

É o maior (uns 1,5 GB). Ele traz o "Android SDK", que são as peças da
Google para montar apps Android.

```powershell
winget install --id Google.AndroidStudio -e
```

Quando terminar, **abra o Android Studio pelo menu Iniciar**. Na primeira
vez ele faz um assistente:

1. *Do not import settings* → OK
2. Escolha **Standard**
3. Aceite as licenças e deixe baixar (mais uns minutos)

Depois pode fechar o Android Studio. Ele só precisava baixar as peças.

---

## Passo 4 — Instalar o Flutter

Esse não está no winget de forma confiável, então é manual — mas é só
baixar e descompactar.

1. Abra <https://docs.flutter.dev/get-started/install/windows/mobile>
2. Baixe o arquivo **.zip** do Flutter
3. No Explorador de Arquivos, crie a pasta `C:\src`
4. Descompacte o zip lá dentro, de forma a ficar **`C:\src\flutter`**

> **Não** coloque em `Arquivos de Programas`. O espaço no nome da pasta
> quebra o Flutter.

Agora avise o Windows onde o Flutter está:

1. Tecla **Windows** → digite `variáveis de ambiente`
2. Abra **Editar as variáveis de ambiente do sistema**
3. Botão **Variáveis de Ambiente…**
4. Em *Variáveis de usuário*, clique em **Path** → **Editar**
5. **Novo** → cole `C:\src\flutter\bin`
6. **OK** em todas as janelas

**Feche o PowerShell e abra de novo**, e confira:

```powershell
flutter --version
```

Deve aparecer `Flutter 3.x.x`. Se disser "não é reconhecido", o caminho
do Path está errado — confira se existe mesmo o arquivo
`C:\src\flutter\bin\flutter.bat`.

---

## Passo 5 — Aceitar as licenças do Android

```powershell
flutter doctor --android-licenses
```

Vai perguntar várias vezes `y/N`. Digite **`y`** e Enter em todas.

Depois:

```powershell
flutter doctor
```

Esse comando é o teu melhor amigo: ele lista o que está certo e o que
falta.

O que precisa estar com **✓**:

- `Flutter`
- `Android toolchain`

Pode ficar com **✗** sem problema:

- `Xcode` — é do iPhone, só existe em Mac
- `Visual Studio` — é para app de Windows, não usamos
- `Chrome` — só se você não tiver o Chrome instalado

---

## Passo 6 — Baixar o projeto

Escolha onde guardar. Vamos usar a pasta Documentos:

```powershell
cd $HOME\Documents
git clone https://github.com/ijunior00/GymRank.git
cd GymRank
git checkout claude/festive-lovelace-vupka8
```

Traduzindo:
- `cd` = "entra na pasta"
- `git clone` = baixa o projeto do GitHub
- `git checkout` = escolhe a versão do código com tudo o que fizemos

Confira que deu certo:

```powershell
dir
```

Tem de aparecer `lib`, `android`, `ios`, `pubspec.yaml`, entre outros.

---

## Passo 7 — Preparar o projeto

```powershell
flutter pub get
```

Baixa as bibliotecas que o app usa. Demora 1–2 min.

```powershell
dart run build_runner build --delete-conflicting-outputs
```

Gera arquivos de código automáticos. Demora 2–5 min e cospe muita
mensagem — é normal. No fim tem de dizer `Succeeded`.

---

## Passo 8 — Ferramentas do Firebase

```powershell
npm install -g firebase-tools
```

```powershell
firebase login
```

Abre o navegador. **Escolha a mesma conta Google** que criou o projeto
`gymrank-e1c0d`.

```powershell
dart pub global activate flutterfire_cli
```

Se depois o comando `flutterfire` não for encontrado, adicione ao Path
(igual ao Passo 4) a pasta:

```
C:\Users\SeuNome\AppData\Local\Pub\Cache\bin
```

---

## Passo 9 — Conectar o projeto ao Firebase

Este é o passo que faz o app real funcionar:

```powershell
flutterfire configure --project=gymrank-e1c0d --platforms=android --android-package-name=com.anahifitness.app
```

**Como saber que deu certo:**

```powershell
flutter analyze
```

Antes deste passo, esse comando reclamava de 2 erros sobre
`firebase_options.dart`. Agora tem de sair **limpo** (`No issues found`).
Esse é o sinal de que o app está ligado ao Firebase.

---

## Passo 10 — Enviar as regras e os robôs

```powershell
firebase deploy --only firestore:rules,firestore:indexes,storage:rules
```

Manda para o Firebase as regras de segurança (quem pode ler e escrever o
quê). Rápido.

Agora os "robôs" — as Cloud Functions, programas que rodam no servidor da
Google e fazem o que a aluna não pode fazer sozinha: somar XP, contar a
sequência, detectar recorde, ler os PDFs.

Um deles usa a IA da Anthropic para ler os PDFs da nutrióloga, e **o
envio falha se a chave não existir antes**. Pegue a chave em
<https://console.anthropic.com> → *API Keys* → criar. É cobrada por uso,
separado do Firebase.

```powershell
cd functions
npm install
cd ..
firebase functions:secrets:set ANTHROPIC_API_KEY
```

Vai pedir a chave: cole e Enter (não aparece nada na tela enquanto você
cola — é proposital).

```powershell
firebase deploy --only functions
```

Demora 5–10 min e pede para ativar umas APIs da Google: aceite.

---

## Passo 11 — Abrir o app

**No celular Android dela (ou no teu):**

1. Ajustes → Sobre o telefone
2. Toque 7 vezes em **Número da versão** (vira modo desenvolvedor)
3. Ajustes → Sistema → Opções do desenvolvedor → ligue **Depuração USB**
4. Ligue o celular no computador por cabo e aceite o aviso na tela

```powershell
flutter devices
```

O celular tem de aparecer na lista.

```powershell
flutter run
```

Primeira vez demora uns 5 min. Depois o app abre no celular.

---

## Passo 12 — Google Sign-In precisa do SHA-1

O login com Google **não funciona** até você fazer isto. É o erro que
mais faz gente perder tempo.

```powershell
cd android
./gradlew signingReport
cd ..
```

Procure o bloco `Variant: debug` e copie as linhas **SHA1** e **SHA-256**.

No navegador: console do Firebase → engrenagem → **Configurações do
projeto** → role até o app Android → **Adicionar impressão digital** →
cole o SHA-1. Repita para o SHA-256.

Depois rode o Passo 9 de novo, para baixar a configuração atualizada.

---

## Passo 13 — Transformar a conta dela em coach

O app não deixa ninguém virar treinadora sozinho — a regra de segurança
só aceita aluna no cadastro. É de propósito, para nenhuma aluna se
promover.

1. Ela cria a conta normalmente pelo app
2. Console do Firebase → **Firestore Database** → coleção `users`
3. Ache o documento dela (confira pelo e-mail)
4. No campo `role`, troque `alumno` por `coach` → Atualizar
5. Ela fecha e abre o app: cai na tela de criar a marca e o código de
   convite

Para a nutrióloga é igual, com `nutriologo`, mais o campo `coachId` com o
id da treinadora.

---

## Quando algo der errado

- **"não é reconhecido como cmdlet"** → o programa não está no Path, ou
  você não reabriu o PowerShell. Feche e abra de novo primeiro.
- **`flutter doctor` com ✗ no Android** → abra o Android Studio uma vez
  e deixe terminar o assistente.
- **`flutter run` não acha o celular** → cabo de dados (alguns cabos só
  carregam), Depuração USB ligada, e aceite o aviso na tela do celular.
- **Deploy das functions falhou** → veja o motivo com
  `firebase functions:log`. Quase sempre é a chave da Anthropic.

Cole a mensagem de erro inteira na conversa. Quase todo erro aqui tem uma
causa conhecida.
