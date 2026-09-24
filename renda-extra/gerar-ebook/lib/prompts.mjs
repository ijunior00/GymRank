// Tudo o que o Claude precisa saber para escrever como um autor de guias
// práticos de renda extra que vende bem e não gera reembolso.

export const IDIOMAS = {
  'pt-BR': {
    nome: 'português do Brasil',
    pais: 'Brasil',
    moeda: 'reais (R$)',
    plataformas: 'Hotmart, Kiwify, Mercado Livre, Shopee, Pix, WhatsApp',
    rotulos: {
      capitulo: 'Capítulo',
      resumo: 'Em resumo',
      acao: 'Faça agora',
      antes: 'Antes de começar',
      comoUsar: 'Como usar este e-book',
      bonus: 'Bônus',
      sumario: 'Sumário',
      aviso:
        'Este material é educativo. Os resultados dependem do seu esforço, do seu contexto e do mercado; nenhum ganho é garantido.',
    },
  },
  'es-MX': {
    nome: 'español de México',
    pais: 'México',
    moeda: 'pesos mexicanos (MXN)',
    plataformas: 'Hotmart, Mercado Libre, Amazon México, WhatsApp, transferencia SPEI',
    rotulos: {
      capitulo: 'Capítulo',
      resumo: 'En resumen',
      acao: 'Hazlo hoy',
      antes: 'Antes de empezar',
      comoUsar: 'Cómo usar este e-book',
      bonus: 'Bonos',
      sumario: 'Índice',
      aviso:
        'Este material es educativo. Los resultados dependen de tu esfuerzo, tu contexto y el mercado; ninguna ganancia está garantizada.',
    },
  },
  'en-US': {
    nome: 'American English',
    pais: 'United States',
    moeda: 'US dollars (USD)',
    plataformas: 'Gumroad, Etsy, Amazon, PayPal, Venmo',
    rotulos: {
      capitulo: 'Chapter',
      resumo: 'Key takeaways',
      acao: 'Do this today',
      antes: 'Before you start',
      comoUsar: 'How to use this e-book',
      bonus: 'Bonuses',
      sumario: 'Contents',
      aviso:
        'This material is educational. Results depend on your effort, your context and the market; no income is guaranteed.',
    },
  },
};

export function persona({ idioma, tema, publico }) {
  const i = IDIOMAS[idioma];
  return `Você é autor(a) best-seller de guias práticos de renda extra, com experiência real em ${i.pais}. Escreve em ${i.nome}, para ${publico}.

Tema deste e-book: ${tema}.

Regras inegociáveis:
- Concreto sempre: valores em ${i.moeda}, nomes reais de plataformas e ferramentas (${i.plataformas} e o que mais couber), prazos, quantidades, exemplos com pessoas e cidades de ${i.pais}.
- Cada capítulo termina com algo que o leitor FAZ hoje, com tempo estimado.
- Nada de promessa de ganho garantido, nada de "fique rico", nada de números inventados apresentados como fato. Quando der um número, diga de onde vem ou marque como estimativa. O leitor tem de terminar confiando em você.
- Parágrafos curtos (2 a 4 frases), segunda pessoa, tom de amigo(a) experiente: direto, encorajador, sem enrolação e sem clichês de coach.
- Sem tabelas: use tópicos, passos numerados e checklists.
- Não mencione que é uma IA nem que o texto foi gerado.`;
}

export function promptPesquisa({ idioma, tema, publico }) {
  const i = IDIOMAS[idioma];
  return `Pesquise na web (fontes de 2025 e 2026 sempre que possível) e escreva um briefing em ${i.nome} para um e-book sobre "${tema}", para ${publico}, no mercado de ${i.pais}.

Inclua, com fontes (URL) ao lado de cada dado:
1. Quem é esse público hoje: dores, medos, objeções, palavras que ELE usa para descrever o problema (procure em comentários, fóruns, vídeos).
2. As 8 a 12 táticas/caminhos concretos dentro do tema, cada uma com: como funciona, custo inicial, quanto rende de forma realista por mês (faixa), tempo até o primeiro ganho, ferramentas/plataformas e taxas atuais.
3. Números reais e recentes do mercado (preços, taxas, comissões, salários mínimos, demanda) que darão credibilidade ao texto.
4. Erros que iniciantes cometem e golpes comuns nesse tema.
5. 3 histórias ou casos reais (com fonte) que sirvam de exemplo.
6. O que os e-books/cursos concorrentes prometem e o que os leitores reclamam nas avaliações.

Formato: markdown, direto, sem introdução. Máximo 1800 palavras.`;
}

export function promptEsboco({ idioma, tema, publico, briefing, capitulos }) {
  const i = IDIOMAS[idioma];
  return `Com base neste briefing de pesquisa:

<briefing>
${briefing}
</briefing>

Monte o esboço de um e-book em ${i.nome} sobre "${tema}" para ${publico}, com ${capitulos} capítulos, para vender a preço baixo (equivalente a 10–25 dólares) em plataformas como Hotmart/Gumroad.

- 5 opções de título com subtítulo: específicos, com resultado e prazo ou número quando fizer sentido, sem promessas irreais. Escolha o melhor.
- A promessa central em uma frase.
- Capítulos em progressão lógica (do "por que/para quem" ao "como, passo a passo" e ao "como escalar"), cada um com objetivo prático, 3 a 6 pontos e um entregável (checklist, modelo, script, planilha simples descrita em texto).
- 2 a 3 bônus que dá para entregar dentro do próprio e-book (modelos, scripts, planos de 7 dias).`;
}

export function promptCapitulo({ idioma, esboco, capitulo, anteriores }) {
  const i = IDIOMAS[idioma];
  const c = capitulo;
  const contexto = anteriores.length
    ? `Capítulos já escritos (só os títulos e resumos, para não repetir): ${anteriores
        .map((a) => `${a.numero}. ${a.titulo} — ${a.resumo.join(' ')}`)
        .join(' | ')}`
    : 'Este é o primeiro capítulo.';
  return `Escreva o capítulo ${c.numero} do e-book "${esboco.titulo_escolhido}" (promessa: ${esboco.promessa}; público: ${esboco.publico}), em ${i.nome}.

Título do capítulo: ${c.titulo}
Objetivo: ${c.objetivo}
Pontos a cobrir: ${c.pontos.join('; ')}
Entregável do capítulo: ${c.entregavel}
${contexto}

Extensão: entre 1300 e 1900 palavras no total. Use 3 a 5 seções. Dentro delas, misture parágrafos com blocos de "passos", "checklist", "dica", "exemplo" (com pessoa, cidade, números em ${i.moeda}) e "atencao" (erro comum ou golpe). O entregável do capítulo tem de aparecer de fato (o checklist completo, o script pronto, o modelo preenchível).`;
}

export function promptRevisao({ idioma, esboco, capitulo }) {
  const i = IDIOMAS[idioma];
  return `Você agora é o editor(a) sênior deste e-book ("${esboco.titulo_escolhido}", em ${i.nome}). Revise o capítulo abaixo e devolva a versão melhorada completa, no mesmo formato.

Critérios, nesta ordem:
1. Precisão: números, taxas e nomes de plataformas plausíveis e atuais; corrija ou marque como estimativa. Remova qualquer promessa de ganho garantido.
2. Concretude: troque frases genéricas por instruções que uma pessoa consiga executar hoje (quantidades, valores em ${i.moeda}, onde clicar, o que dizer).
3. Utilidade dos entregáveis: checklists e scripts completos e usáveis, não "exemplos de".
4. Ritmo: corte repetição e enrolação; parágrafos de 2 a 4 frases; mantenha o tom de amigo(a) experiente.
5. Coerência com a promessa e o público do e-book.

<capitulo>
${JSON.stringify(capitulo)}
</capitulo>`;
}

export function promptVendas({ idioma, tema, esboco, resumos }) {
  const i = IDIOMAS[idioma];
  return `Crie o material de venda, em ${i.nome}, para o e-book "${esboco.titulo_escolhido}: ${esboco.subtitulo_escolhido}" (tema: ${tema}; promessa: ${esboco.promessa}; público: ${esboco.publico}).

Conteúdo do e-book (resumo por capítulo):
${resumos.map((r) => `- Cap. ${r.numero} ${r.titulo}: ${r.resumo.join(' ')}`).join('\n')}

Bônus: ${esboco.bonus.map((b) => `${b.nome} (${b.descricao})`).join('; ')}

Entregue:
- Título e subtítulo da página de vendas (podem ser diferentes do livro, mais diretos).
- Descrição longa em markdown (400–700 palavras): dor → virada → o que tem dentro → para quem é → bônus → garantia → chamada. Sem promessa de ganho garantido; use "pode", "muitos conseguem", números com contexto.
- 7 bullets de benefício concretos, "para quem é" e "para quem não é".
- Garantia de 7 dias em uma frase amigável.
- 5 perguntas frequentes com respostas curtas.
- Preços: sugestão para Brasil (R$), México/LatAm (MXN e USD) e EUA/Europa (USD/EUR), cada um com preço âncora (o "de") e justificativa.
- 5 e-mails (dia 0 a 4) para quem baixou a isca digital gratuita: assunto e corpo curtos (80–150 palavras), o último com a oferta.
- 10 roteiros de vídeo curto (30–45 s): gancho nos 2 primeiros segundos, desenvolvimento, chamada para o link da bio.
- Capa: conceito visual, 3 cores, texto exato da capa e instruções passo a passo para montar no Canva (modelo de e-book, fontes, posição do título).
- Isca digital: mini-guia gratuito de 1 a 2 páginas (markdown) com uma vitória rápida do tema, que termina convidando para o e-book.`;
}
