# Gerador de e-books de renda extra

Você dá o tema e o público; ele pesquisa na web, escreve o e-book
capítulo a capítulo, passa um editor por cima e entrega:

| Arquivo | O que é |
|---|---|
| `ebook.docx` | O livro em Word: capa, sumário, capítulos com passos, checklists e caixas de dica/exemplo/atenção, bônus |
| `vendas.md` | Página de vendas pronta para colar na Hotmart/Kiwify/Gumroad, bullets, FAQ, garantia, preços por país, 5 e-mails, 10 roteiros de vídeo curto |
| `capa-canva.md` | Conceito, cores e passo a passo para montar a capa no Canva |
| `isca-digital.md` | Mini-guia gratuito para trocar por e-mail (a "isca") |
| `pesquisa.md` | O que foi encontrado na web, com fontes, para você conferir os números |
| `revisao.md` | O que o editor mudou em cada capítulo |

Um e-book de 8 capítulos leva de 15 a 30 minutos e custa, em média, de
US$ 4 a 8 de API (estimativa; o programa imprime o custo no final).

## Uma vez só

Precisa de Node (você já tem, é o mesmo das functions) e de uma chave da
API da Anthropic com crédito.

1. **Chave nova.** No navegador: console.anthropic.com → API Keys →
   *Create key*. Copie. (Se você já tem uma no Secret Manager do Firebase,
   crie outra só para isto; assim dá para apagar uma sem mexer na outra.)
2. **Terminal, na pasta deste gerador:**
   ```powershell
   cd renda-extra\gerar-ebook
   npm install
   copy .env.exemplo .env
   ```
3. **Abra o `.env` no VS Code** e troque `cole-aqui-a-sua-chave` pela chave.
   Salve. O `.env` nunca vai para o GitHub (está no `.gitignore`). Nunca
   cole a chave em conversa nem em outro arquivo.

## Gerar um e-book

Na mesma pasta:

```powershell
npm run gerar -- --tema "Renda extra vendendo doces caseiros" --publico "mães que querem trabalhar de casa" --idioma pt-BR
```

O que você vai ver: cinco etapas numeradas com horário, o título
escolhido, um capítulo por vez, e no fim a pasta com os arquivos e o custo.
Os arquivos ficam em `saida/<tema>-<data>/`.

Opções úteis:

| Opção | Quando usar |
|---|---|
| `--idioma es-MX` ou `--idioma en-US` | Versão para México/LatAm ou EUA/Europa (muda idioma, moeda e plataformas citadas) |
| `--capitulos 10` | Livro maior (6 a 12) |
| `--autor "Nome"` | Nome na capa |
| `--rapido` | Sem a revisão de editor: metade do custo, texto um pouco menos polido |
| `--simular` | Sem gastar nada: arquivos de exemplo para ver o formato |

Teste sem custo primeiro: `npm run simular`.

## Depois que gerar

1. Abra o `ebook.docx` no Word. Se aparecer "Este documento contém campos
   que podem se referir a outros arquivos. Atualizar?", clique **Sim**: é o
   sumário se montando.
2. Leia o `pesquisa.md` e confira os números que entraram no livro. O
   Claude cita a fonte; se um valor parecer estranho, corrija no Word.
3. Ajuste o que quiser (o Word é seu), depois **Arquivo → Salvar como →
   PDF**. Esse PDF é o produto.
4. Monte a capa no Canva seguindo `capa-canva.md` e coloque como primeira
   página do PDF (ou use a capa só na página de vendas).
5. Cole o texto de `vendas.md` na plataforma e siga o plano em
   `../README.md`.

## Se der errado

- `Falta a chave da API` → o `.env` não existe ou está com o nome errado.
- `A chave da API não foi aceita` → chave copiada incompleta ou desativada.
- `sem crédito` → console.anthropic.com → Billing.
- `Muitos pedidos seguidos` → espere um minuto e rode de novo.
- Parou no meio → os capítulos já prontos estão em `capitulos.json`; rode
  de novo (gera outra pasta) ou use `--rapido`.
- Texto genérico ou com número errado → o problema quase sempre é o tema
  amplo demais. Especifique: em vez de "renda extra", "renda extra
  vendendo marmitas fit para academias em cidades médias".

## Como funciona por dentro

`gerar.mjs` → `lib/prompts.mjs` (o que pedimos, por idioma) →
`lib/claude.mjs` (API: pesquisa com busca na web, saída estruturada em
JSON validada por `lib/schemas.mjs`, cache do contexto do livro entre
capítulos) → `lib/docx.mjs` (o Word). Modelo padrão `claude-opus-5`.
