# Renda extra: o sistema de vendas automático (plano mestre)

Este é o plano completo, do zero à primeira venda, para vender e-books de
**renda extra** em português, espanhol e inglês, com o mínimo de peças
possível. Tudo o que está aqui foi decidido com base nas três pesquisas
da pasta `pesquisa/` (set/2026). Onde um número é estimativa, está escrito.

Esta pasta é um negócio **separado do app AnahiFitness**. Nada daqui toca
o app, o Firebase ou as alunas.

## O que tem nesta pasta

| Onde | O que é |
|---|---|
| `README.md` (este arquivo) | O plano: o que vender, onde, para quem, como montar a máquina, o que fazer em 30 dias |
| `gerar-ebook/` | O programa que escreve o e-book, a página de vendas, os e-mails e os roteiros de vídeo com um comando (manual em `gerar-ebook/README.md`) |
| `pesquisa/01-nichos.md` | Os 12 sub-nichos avaliados, com dados, e os 3 escolhidos |
| `pesquisa/02-plataformas-regioes.md` | Hotmart, Kiwify, Gumroad, KDP e outras: taxas, quem aceita residente no México, impostos, políticas |
| `pesquisa/03-trafego-conversao.md` | Canais de tráfego, números de conversão, estrutura da página, os 5 e-mails, KPIs |

## 1. O sistema inteiro em uma imagem

```
 vídeo curto grátis        página da isca          5 e-mails automáticos        checkout Hotmart
 (TikTok / Reels /   -->   "deixe o e-mail e   -->  (dia 0, 1, 2, 3, 4)     -->  e-book + order bump
  Shorts, 1 por dia)        receba o mini-guia")     escritos pelo gerador         (entrega automática)
                                                                                      |
                                                                              depois de 100 vendas:
                                                                              afiliados da Hotmart
                                                                              vendem por você (60%)
```

Só existem **quatro peças**: o vídeo, a isca, os e-mails e o checkout.
Tudo depois do vídeo é automático. Você grava vídeos; o resto roda sozinho.

Regras de ouro que saem das pesquisas:

1. **Anúncio pago só depois** que a página converter 2% ou mais no
   tráfego orgânico e o checkout tiver order bump. Com e-book de R$ 37 e
   taxa da Hotmart, sobram cerca de R$ 31 por venda. Sem bump, o anúncio
   custa mais do que rende.
2. **Vender método, nunca "oportunidade de renda".** Título e anúncio
   dizem o que a pessoa aprende ("como conseguir o primeiro cliente"),
   nunca quanto vai ganhar. É o que passa nas regras da Meta, TikTok,
   Hotmart e Gumroad (ver seção 8).
3. **Um produto de cada vez.** O primeiro e-book sai em espanhol e
   português no mesmo mês. Só depois vem o segundo.

## 2. Decisões já tomadas

Para você não gastar tempo escolhendo, as pesquisas já apontaram:

### Onde vender

| Idioma / região | Plataforma | Por quê |
|---|---|---|
| **Espanhol (México e LatAm)** | **Hotmart** | Preço em pesos, OXXO e SPEI no checkout, maior marketplace de afiliados em espanhol. Para pessoa física residente no México, a própria Hotmart emite a nota ao comprador. |
| **Português (Brasil)** | **Hotmart** | É a única das grandes brasileiras que aceita você morando no México. **Kiwify, Eduzz e Monetizze exigem residência ou conta bancária no Brasil.** Pix e parcelamento no checkout, maior rede de afiliados em português. |
| **Inglês (EUA, Canadá, Europa)** | **Gumroad** + **Amazon KDP** | Gumroad recolhe os impostos do comprador no mundo todo (10% + US$ 0,50, sem mensalidade). KDP dá alcance na Amazon. **Não** inscrever no KDP Select, porque ele proíbe vender o mesmo e-book fora da Amazon. |

**Uma conta Hotmart nova, cadastrada como residente no México.** Não use
conta antiga com CPF e endereço do Brasil (detalhe na seção 9).

### Os três primeiros e-books, nesta ordem

| Ordem | E-book | Idiomas | Por quê |
|---|---|---|---|
| **1º** | **Freelancer com IA**: conseguir o primeiro cliente em plataformas como Workana, Upwork e Fiverr | ES + PT no mesmo mês; EN depois | Demanda medida (29% dos mexicanos com renda extra prestam serviços), promessa realista que passa em anúncio, e um ângulo que quase ninguém tem: trabalhar da América Latina para clientes dos EUA. |
| **2º** | **Seu primeiro produto digital**: criar e vender planilhas e templates (Canva, Excel, Notion) | PT + ES; EN depois | Maior nota do ranking (32/40). Os próprios templates viram bônus e novos produtos. Também serve de isca para o 1º. |
| **3º** | **Renda extra depois dos 50** | PT + ES | Quase nenhum concorrente em português e espanhol; público que paga por passo a passo bem-feito. |
| 4º (fila) | **Mães em casa** | ES primeiro | 55% a 77% das empreendedoras mexicanas são mães. Reaproveita a estrutura do 1º e do 2º. |

**Não começar** por "ganhar dinheiro com IA" nem por "afiliado": são os
dois com mais gente vendendo e os mais rejeitados em anúncio.

### Títulos de partida (o gerador propõe 5 e você escolhe)

- **ES:** *Freelance desde México: cómo cobrar en dólares con 5 servicios que puedes aprender en una semana*
- **PT:** *Seu Primeiro Cliente em 14 Dias: guia passo a passo para virar freelancer (Workana, Upwork e Fiverr) usando IA*
- **EN (depois):** *The Bilingual Freelancer: 7 services Spanish/Portuguese speakers can sell to US clients*

Padrão que funciona: número + prazo + público + barreira removida
("sem experiência", "sem investir") + ano na edição.

### Preços de partida

| Mercado | E-book | Âncora (preço "de") | Order bump | Upsell (mais tarde) |
|---|---|---|---|---|
| Brasil | R$ 37 | R$ 97 | R$ 17 (pack de modelos de proposta ou planilha de preços) | R$ 97 (mini-curso em vídeo ou mentoria em grupo) |
| México / LatAm | MXN 199 | MXN 399 | MXN 79 | MXN 499 |
| EUA / Europa (Gumroad) | US$ 12 | US$ 29 | US$ 7 | US$ 39 |
| Amazon KDP | US$ 4,99 a 7,99 | — | — | — |

Estimativas. A regra que vale: o bump custa 10% a 25% do e-book e
complementa (não repete) o conteúdo. Ajuste depois das primeiras 50 vendas.

### Produto

- E-book de **50 a 80 páginas**, PDF, legível no celular, com passos
  numerados, checklists e exemplos com números e data.
- **2 bônus** separados: uma planilha e um checklist ou pack de modelos.
- **Isca grátis**: mini-guia de 5 a 8 páginas (o gerador já entrega).
- **Garantia de 7 dias** na Hotmart, sem perguntas.

### Ferramentas (custo fixo: zero)

| Para quê | Ferramenta | Custo |
|---|---|---|
| Escrever o e-book, página, e-mails, roteiros | `gerar-ebook/` (API da Anthropic) | US$ 4 a 8 por e-book, estimativa |
| Capa, mockup, pins | Canva Free | 0 |
| Vender, entregar, bump, afiliados | Hotmart | 0 fixo; 9,9% + R$ 2,49 por venda (outras moedas: 9,9% + US$ 1) |
| Página da isca e os 5 e-mails | Hotmart Send (confira no painel se está liberado para a sua conta); se não, Brevo Free (300 e-mails/dia) | 0 |
| Editar vídeos curtos | CapCut (grátis, exporta 1080p) | 0 |
| Agendar posts | Metricool Free (20 posts/mês) ou Buffer | 0 |
| Inglês | Gumroad + KDP | 0 fixo; 10% + US$ 0,50 no Gumroad |

Quando quiser pagar algo: Canva Pro (US$ 12 a 18/mês) para tirar a marca
d'água dos templates e Systeme.io Startup (US$ 17/mês) se preferir um
funil próprio com 0% de taxa. Nada disso é necessário no primeiro mês.

## 3. Como o e-book é produzido (o que o gerador faz)

Um comando no Terminal, dentro de `renda-extra/gerar-ebook`:

```powershell
npm run gerar -- --tema "Conseguir o primeiro cliente como freelancer usando IA (Workana, Upwork, Fiverr)" --publico "pessoas de 22 a 40 anos com emprego formal, com computador e sem portfólio, que querem uma segunda renda" --idioma pt-BR --capitulos 8 --autor "NOME DA MARCA"
```

Para a versão em espanhol, troque `--idioma es-MX` e escreva tema e
público em espanhol. O programa:

1. **Pesquisa na web** os números atuais do tema (valores, prazos,
   plataformas) e salva com fontes em `pesquisa.md`.
2. Propõe **5 títulos**, escolhe um e monta o esboço dos capítulos.
3. Escreve **capítulo por capítulo**, com passos, checklists, caixas de
   dica e exemplos numéricos, e passa um **editor** por cima de cada um.
4. Escreve a **página de vendas**, os **5 e-mails**, **10 roteiros de
   vídeo curto**, o **conceito da capa** e a **isca grátis**.
5. Entrega tudo em `saida/<tema>-<data>/`: `ebook.docx`, `vendas.md`,
   `isca-digital.md`, `capa-canva.md`, `pesquisa.md`, `revisao.md`.

Leva de 15 a 30 minutos e imprime o custo no fim. Antes de gastar,
teste o formato com `npm run simular` (não usa a API).

**A sua parte depois de gerar (1 a 2 horas por e-book):**

1. Abrir o `ebook.docx` no Word e ler do começo ao fim. Conferir os
   números marcados em `pesquisa.md`. Cortar o que soar genérico.
2. Salvar como PDF (Arquivo → Salvar como → PDF).
3. Montar a capa no Canva seguindo `capa-canva.md` (15 min).
4. Montar os 2 bônus: a planilha no Google Sheets, o checklist no Canva.

Nenhum e-book vai para a Hotmart sem você ter lido. É a mesma regra do
app: a máquina sugere, um humano aprova.

## 4. Plano de 30 dias (1 a 2 horas por dia)

Semana a semana. "Você" = só você consegue fazer. "Claude" = peça na
conversa, a qualquer hora, e receba pronto.

### Semana 1: produto e isca

| Dia | Quem | O que fazer | Pronto quando |
|---|---|---|---|
| 1 | Você | Decidir o **nome da marca** que vai na capa e no perfil (ver seção 10). Criar a chave da API e rodar `npm run simular` | O `.docx` de teste abriu no Word |
| 1 | Você | Criar conta na Hotmart como residente no México (e-mail novo, dados do México) e iniciar a verificação de identidade | Conta aprovada (pode levar 1 a 3 dias) |
| 2 | Você + gerador | Gerar o e-book nº 1 em **espanhol** (`--idioma es-MX`) | Pasta `saida/` com os 9 arquivos |
| 2–3 | Você | Ler, corrigir, salvar em PDF | PDF de 50+ páginas |
| 3 | Você + gerador | Gerar o e-book nº 1 em **português** | Segunda pasta `saida/` |
| 4 | Você | Ler, corrigir, salvar em PDF | Dois PDFs |
| 5 | Você | Capas no Canva (ES e PT) usando `capa-canva.md` | 2 capas + 2 mockups |
| 6 | Você + Claude | Bônus: planilha de preços e pack de modelos de proposta (peça ao Claude o conteúdo; você monta no Sheets/Canva) | 2 bônus por idioma |
| 7 | Você | Isca: transformar `isca-digital.md` em PDF de 5 a 8 páginas no Canva ou no Word | 1 isca por idioma |

### Semana 2: a máquina

| Dia | Quem | O que fazer | Pronto quando |
|---|---|---|---|
| 8 | Você | Cadastrar o produto ES na Hotmart (seção 5, checklist) | Link de checkout funcionando |
| 9 | Você | Cadastrar o produto PT | Segundo checkout |
| 10 | Você + Claude | Página de vendas: colar `vendas.md` no Hotmart Pages ou na página padrão da Hotmart; pedir ao Claude ajustes de texto se algo soar estranho | Página abre no celular em menos de 3 s |
| 11 | Você | Página da isca (formulário de e-mail) no Hotmart Send ou Brevo | Você testou com o seu e-mail e recebeu o PDF |
| 12 | Você | Colar os 5 e-mails de `vendas.md` na automação (dia 0, 1, 2, 3, 4) | Sequência ativa |
| 13 | Você | Criar perfil no TikTok e Instagram com o nome da marca, link da isca na bio, grupo de WhatsApp "lista VIP" | Perfis criados |
| 14 | Você | Gravar **10 vídeos** de 20 a 40 s em lote, usando os roteiros de `vendas.md` (5 formatos × 2). Editar no CapCut | 10 vídeos prontos para agendar |
| 14 | Você | **Teste final**: comprar o próprio produto com cupom de R$ 1 / MXN 1 e conferir que o e-book chega | Recebeu o e-mail de entrega |

### Semana 3: tráfego orgânico

Todo dia, 30 a 60 min:

1. Publicar **1 vídeo** no TikTok e repostar como Reels e Shorts
   (agendar pelo Metricool). Melhor horário: 18h às 21h.
2. Responder **todo comentário** com a palavra-chave ("RENDA" / "INGRESO")
   com o link da isca.
3. Mandar **1 mensagem** no grupo VIP com uma dica e o link.
4. Pedir a 5 pessoas conhecidas que leiam de graça e mandem uma opinião
   com print (vão para a página de vendas como depoimento, com permissão).

### Semana 4: otimizar e primeira venda

1. Repetir o formato de vídeo que mais gerou comentários (o gerador dá
   10 roteiros; peça mais ao Claude na mesma linha).
2. Abrir **cupom de 48 horas** para a lista (é o e-mail do dia 4).
3. Se muitos cliques e zero venda: reescrever headline e bullets (Claude).
4. **Dias 28 a 30, só se a página converteu 2% ou mais no orgânico:**
   testar R$ 20 a 30/dia (ou MXN 200/dia) em TikTok Ads ou Meta, 1
   campanha, 3 criativos (os seus 3 melhores vídeos), por 7 dias.

**Segundo mês:** repetir o ciclo com o e-book nº 2, que também vira isca
para o nº 1. **Terceiro mês:** e-book nº 3 e versão em inglês do nº 1 no
Gumroad e KDP. Abrir para **afiliados** (comissão 60%) quando a página
tiver 100 vendas e reembolso de até 5%: é isso que os afiliados filtram
no marketplace da Hotmart.

## 5. Checklist de cadastro do produto na Hotmart

Tudo no navegador, em hotmart.com, área do produtor.

1. **Produto → Cadastrar produto → E-book (arquivo).** Suba o PDF e os 2
   bônus. Nome = título do e-book. Idioma e moeda do mercado (ES = MXN,
   PT = BRL).
2. **Preço** conforme a tabela da seção 2. Ative **parcelamento** no BR.
3. **Garantia: 7 dias.**
4. **Order bump**: crie o bump como produto separado (R$ 17 / MXN 79) e
   ative em *Ferramentas → Order bump* no checkout do e-book.
5. **Página de vendas**: use o Hotmart Pages (modelo de e-book) e cole o
   texto de `vendas.md` na ordem: headline, problema, o que é, bullets,
   prova, quem é você, oferta empilhada com âncora, garantia + FAQ + botão.
6. **Afiliação**: deixe *fechada* no primeiro mês. Abra em 60% quando
   tiver 100 vendas.
7. **Aviso obrigatório** na página e na descrição: *"Este material é
   educativo e não garante resultados financeiros."* (em ES: *"Este
   producto no garantiza resultados."*)
8. **Teste de compra** com cupom de 100% ou R$ 1 e conferência de que o
   e-mail de entrega chega com o arquivo.

## 6. O que olhar toda segunda-feira (KPIs)

Anote em uma planilha simples, uma linha por semana. Faixas estimadas a
partir dos dados da pesquisa 03.

| KPI | Semana 3 | Semana 4 | Se estiver abaixo, o problema é |
|---|---|---|---|
| Views na semana (TikTok + Reels + Shorts) | 5 a 20 mil | 15 a 50 mil | Gancho dos 3 primeiros segundos |
| Comentários com a palavra-chave | 20 a 60 | 60 a 150 | Chamada fraca ou isca sem graça |
| Cliques no link da bio | 100 a 300 | 300 a 800 | Bio ou chamada para ação |
| Leads (e-mails captados) | 30 a 100 | 100 a 300 | Página da isca (meta: 25% de quem entra deixa o e-mail) |
| Conversão da página de vendas | 2 a 5% | 3 a 8% | Abaixo de 1%: headline, bullets e prova |
| Vendas | 1 a 3 | 4 a 12 | Zero com 200 visitas: preço, promessa ou confiança |
| Aceitação do order bump | — | 20 a 40% | Abaixo de 10%: o bump não complementa |
| Reembolso | — | até 5% | Acima de 10%: a página promete mais do que o livro entrega |
| Se ligou anúncio: custo por venda | — | até R$ 30 (MXN 200) | Acima do e-book + bump líquido: desligue |

**Como usar o Claude nesse dia:** cole a linha da semana na conversa e
peça "diagnóstico e as 3 ações da semana". Regra de escala de anúncio: só
aumente 20% por vez quando, por 7 dias, o custo por venda ficar abaixo de
70% do ticket médio (e-book + bump).

## 7. Divisão de tarefas

**Só você consegue fazer:**
- Conta na Hotmart (e depois Gumroad e KDP) como residente no México,
  com a sua conta bancária.
- Escolher o nome da marca e aprovar cada e-book antes de subir.
- Gravar os vídeos (rosto ou só a tela do celular com a sua voz).
- Falar com o contador (seção 9).
- Responder comentários e o grupo VIP.

**O Claude faz quando você pedir (na conversa ou pelo gerador):**
- Gerar cada e-book nos 3 idiomas, página, e-mails, roteiros, isca, capa.
- Reescrever headline, bullets e e-mails quando um KPI estiver ruim.
- Mais roteiros no formato que funcionou.
- Traduzir e adaptar para EN quando chegar a hora.
- Ler a linha de KPIs e devolver o diagnóstico.
- Preparar o material de afiliados (banners em texto, e-mails prontos).

## 8. Regras de anúncio: o que nunca escrever

Vale para título, capa, página, vídeo e anúncio. As plataformas
(Meta, TikTok, Hotmart, Gumroad) rejeitam ou banem por isto:

| Nunca | Em vez disso |
|---|---|
| "Renda garantida", "renda passiva", "ganhe R$ 5 mil por mês" | "Aprenda a precificar e conseguir o primeiro cliente" |
| Print de saldo, extrato, Pix recebido | Print da planilha preenchida, do perfil aprovado, do passo feito |
| Carro, dinheiro, relógio, "liberdade financeira" | Mesa de trabalho, celular, tela do app |
| Perguntas sobre a pessoa: "Está endividado?", "Aposentado sem dinheiro?" | "12 formas de complementar a renda depois dos 50" |
| "Garantido", "em 10 segundos", "sem esforço" | "Passo a passo", "em 14 dias", "mesmo sem experiência" |
| Depoimento com valor ganho sem contexto | Depoimento + aviso "resultado não típico" |

Sempre na página e na descrição: **"Material educativo. Não garante
resultados."** Garantia de 7 dias visível.

## 9. Impostos: o que perguntar ao contador (não é aconselhamento)

O detalhe está em `pesquisa/02-plataformas-regioes.md`, seção 3. O
resumo para você levar ao contador no México:

1. "Vou vender e-books pela Hotmart (empresa holandesa, Hotmart B.V.),
   Gumroad e Amazon KDP. Preciso de **RFC** e de um regime: **Plataformas
   Tecnológicas** (a plataforma retém ISR e IVA) ou **RESICO / Actividad
   Empresarial**? A Hotmart me entrega CFDI de retenções?"
2. "Como declaro o que entra em dólar e em peso?"
3. Para o contador brasileiro: "Fiz a **Comunicação de Saída Definitiva**?
   Se não, ainda sou residente fiscal no Brasil e preciso declarar a renda
   mundial (com crédito do imposto pago no México pelo tratado)."

Na Gumroad, KDP e Udemy, preencha o **W-8BEN** com o RFC. Sem ele, os
EUA retêm 30% das vendas; com ele e o tratado EUA–México, royalties ficam
em 10% (KDP). Cadastre a Hotmart com endereço e banco do México, não com
CPF e endereço do Brasil.

## 10. Decisões que só você pode tomar antes do dia 1

1. **Nome da marca** que assina os e-books nos 3 idiomas. Recomendação:
   um nome de marca (não o seu nome) que funcione em PT, ES e EN, para
   os afiliados acharem e para separar do AnahiFitness. O gerador aceita
   `--autor "Nome"`.
2. **Você aparece nos vídeos?** Rosto converte melhor, mas gravação de
   tela com a sua voz também funciona (formato "como eu cadastrei em 5
   min"). Escolha um e mantenha 30 dias.
3. **Conta bancária** que recebe: a do México, no mesmo nome do cadastro
   da Hotmart.

## 11. O que fazer hoje

1. Escolher o nome da marca (item 10.1).
2. Abrir o Terminal e rodar o teste do gerador (`gerar-ebook/README.md`,
   "Uma vez só" e depois `npm run simular`).
3. Criar a conta na Hotmart como residente no México e iniciar a
   verificação.
4. Amanhã: gerar o e-book nº 1 em espanhol e ler.

Quando tiver o primeiro `.docx` gerado de verdade, me mande o título
escolhido e o que achou do capítulo 1. Daí ajustamos o tom uma vez e os
próximos saem no mesmo padrão.
