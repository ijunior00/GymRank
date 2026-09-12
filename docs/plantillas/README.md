# Modelos em Word para os planos

Quatro arquivos `.docx` que a treinadora e a nutrióloga preenchem. Depois
sobem o **próprio Word** no app (Panel de coach → aluna → *Subir plan*) —
não precisa exportar para PDF, o leitor entende `.docx` direto.

| Arquivo | Quem preenche | Ao subir, escolher |
| --- | --- | --- |
| `plantilla-entrenamiento.docx` | a treinadora | Entrenamiento |
| `plantilla-dieta.docx` | a nutrióloga | Dieta |
| `plantilla-macros.docx` | a nutrióloga | Macros |
| `plantilla-evaluacion.docx` | qualquer uma das duas | Evaluación |

## Por que um formato fixo

Quem lê o documento é um modelo de linguagem, não um programa de regras
fixas: ele entende folha bagunçada e até foto de papel. Só que quanto mais
previsível o documento, menos coisa a treinadora precisa corrigir na tela
de revisão. Os modelos existem para isso — não são obrigatórios.

## As colunas não são decorativas

Cada coluna corresponde a um campo que o app guarda. Renomear "Series"
para "Sets" não quebra nada (o leitor entende), mas apagar a coluna faz o
dado sumir do app. A correspondência está em
`functions/src/plans/planSchemas.ts`, que por sua vez espelha
`lib/features/plans/domain/entities/plan_content.dart`.

**Se um dia mudar os campos lá, regenere os modelos** — senão o formato
passa a pedir coisas que o app não guarda mais.

## Como regenerar

Os `.docx` são gerados por script, não editados à mão, para não saírem do
compasso com o código:

```bash
node scripts/gerar-plantillas.js docs/plantillas
```

Precisa da biblioteca `docx` do npm (`npm install docx` na raiz, ou global).

## O que o app faz com o arquivo

1. A treinadora sobe o Word → vai para o Storage e cria `documents/{id}`
   com status `subido`.
2. A Cloud Function `parseDocument` lê e devolve o plano estruturado.
3. A treinadora **revisa e corrige** na tela de revisão.
4. Ela publica → só aí a aluna vê.

O passo 3 não tem como ser pulado, de propósito: nenhum plano chega à
aluna sem revisão humana.
