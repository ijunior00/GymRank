# Como trabalhar neste repositório

## Quem vai ler as tuas respostas

O dono do projeto **não é programador**. Pediu, com estas palavras:
*"lembra que sou noob em programação, sempre me explica bem explicadinho
passo a passo"*.

Isso vale para toda resposta, sempre — não só quando ele pedir de novo.

Na prática:

- **Um passo por vez, numerado.** Nada de blocos de comandos empilhados
  sem explicação entre eles.
- **Diga onde digitar.** "Abre o Terminal", "isso é no navegador, no
  console do Firebase", "isso é no VS Code".
- **Explique o que cada comando faz**, em uma linha, antes de mandar
  rodar. Ele precisa entender, não só copiar.
- **Diga o que ele vai ver quando der certo.** Um jeito de conferir
  sozinho, sem ter que perguntar.
- **Diga o que fazer se der errado**, nos pontos onde costuma falhar.
- **Nada de jargão sem tradução.** Se usar "deploy", "build", "branch",
  "bundle id", explique na hora, em poucas palavras.
- **Não presuma ferramenta instalada.** Antes de mandar rodar algo,
  confirme que ele tem (Flutter, Node, git…).
- Escreva em **português**. A interface do app é em espanhol do México,
  mas a conversa com ele é em português.

O que **não** fazer: encher de teoria, listar alternativas que não vai
seguir, ou pedir desculpa. Ele quer avançar, só precisa enxergar o
caminho.

## O projeto em uma frase

App do método de uma personal trainer no México (**AnahiFitness**,
`com.anahifitness.app`): ela gerencia as alunas no painel, elas treinam,
registram evolução e competem. Interface 100% em espanhol do México,
pensada para celular.

Detalhes em `README.md`. Direção de produto em
`docs/brainstorm-personal-trainer.md`.

## Roteiros já escritos

Antes de explicar um setup do zero, veja se já existe:

- `docs/setup-firebase.md` — criar e ligar o projeto Firebase
- `docs/setup-movil.md` — daí até a Play Store e a App Store
- `docs/setup-web-pwa.md` — a versão web / PWA

## Regras técnicas que não podem ser quebradas

- **Nada de gamificação escrito pelo cliente.** XP, nível, sequência,
  Gym Score, recordes, `referralCount` — tudo só por Cloud Function, e
  bloqueado em `firestore.rules`. É o que impede a aluna de burlar o
  ranking.
- **Região das functions**: `us-central1`, fixado em
  `functions/src/constants.ts` **e** em `AppConstants.functionsRegion`.
  Se as duas divergirem, a chamada volta `NOT_FOUND`.
- **Nenhum plano chega à aluna sem revisão humana.** O leitor de PDF
  sugere; a treinadora revisa e publica.
- **O pacote Dart continua `gymrank`** (imports `package:gymrank/…`).
  Não vale a pena renomear: 122 arquivos e ninguém vê esse nome.

## Verificação antes de dizer que está pronto

```bash
flutter analyze     # limpo (sem firebase_options.dart, sobram 2 erros conhecidos)
flutter test        # as regras puras
cd functions && npx tsc --noEmit
```
