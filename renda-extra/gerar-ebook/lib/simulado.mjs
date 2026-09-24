// Conteúdo de mentira para o modo --simular: testa o Word e os arquivos de
// saída sem gastar um centavo de API. Não use como conteúdo real.

export function esbocoSimulado({ tema, publico }) {
  return {
    titulos: [
      { titulo: `${tema}: do zero à primeira venda`, subtitulo: 'Um plano de 14 dias', por_que_converte: 'prazo + resultado' },
      { titulo: 'Renda extra sem sair de casa', subtitulo: 'O guia prático', por_que_converte: 'dor direta' },
    ],
    titulo_escolhido: `${tema}: do zero à primeira venda`,
    subtitulo_escolhido: 'Um plano de 14 dias, com valores reais',
    promessa: 'Em 14 dias você faz a primeira venda e sabe exatamente o que repetir.',
    publico: publico,
    tom: 'amigo(a) experiente, direto',
    capitulos: [
      { numero: 1, titulo: 'Por que isso funciona (e para quem)', objetivo: 'Decidir se este caminho é para você', pontos: ['quanto rende', 'custo inicial', 'tempo'], entregavel: 'Checklist "é para mim?"' },
      { numero: 2, titulo: 'Seu primeiro produto em 48 horas', objetivo: 'Ter algo pronto para vender', pontos: ['escolha', 'custo', 'preço'], entregavel: 'Planilha de custo em texto' },
    ],
    bonus: [{ nome: 'Plano de 7 dias', descricao: 'Um dia por linha: o que fazer, quanto tempo leva, o que marcar como feito.' }],
  };
}

export function capituloSimulado(c, moeda) {
  return {
    titulo: c.titulo,
    abertura: `Este capítulo cumpre o objetivo: ${c.objetivo}. Vamos direto ao ponto, com números em ${moeda}.\n\nNo fim há tarefas para você fazer hoje.`,
    secoes: [
      {
        titulo: 'O que você precisa saber antes',
        blocos: [
          { tipo: 'paragrafo', texto: 'Texto **simulado** de parágrafo. No e-book real, aqui entram os fatos pesquisados na web, com fonte.', itens: null },
          { tipo: 'passos', texto: null, itens: ['Primeiro passo simulado.', 'Segundo passo simulado.', 'Terceiro passo simulado.'] },
          { tipo: 'dica', texto: 'Uma dica curta e aplicável.', itens: null },
        ],
      },
      {
        titulo: 'Mão na massa',
        blocos: [
          { tipo: 'exemplo', texto: `Maria, de Curitiba, começou com ${moeda} 150 e vendeu 12 unidades na primeira semana (exemplo simulado).`, itens: null },
          { tipo: 'checklist', texto: null, itens: ['Item de checklist 1', 'Item de checklist 2'] },
          { tipo: 'atencao', texto: 'Cuidado com quem promete ganho garantido.', itens: null },
          { tipo: 'citacao', texto: 'Comece pequeno, mas comece hoje.', itens: null },
        ],
      },
    ],
    resumo: ['Ponto principal um.', 'Ponto principal dois.', 'Ponto principal três.'],
    acao_agora: ['Fazer a tarefa A (20 min).', 'Fazer a tarefa B (10 min).'],
  };
}

export function vendasSimuladas(esboco) {
  return {
    titulo_pagina: esboco.titulo_escolhido,
    subtitulo_pagina: esboco.subtitulo_escolhido,
    descricao_longa: '## Descrição simulada\n\nAqui entra a página de vendas gerada de verdade.',
    bullets: ['Benefício 1', 'Benefício 2', 'Benefício 3'],
    para_quem_e: ['Quem quer começar hoje'],
    para_quem_nao_e: ['Quem busca ganho garantido'],
    bonus: esboco.bonus,
    garantia: '7 dias: não gostou, devolvemos.',
    faq: [{ pergunta: 'Preciso investir?', resposta: 'Pouco: o e-book mostra como começar com quase nada.' }],
    precos: [
      { mercado: 'Brasil', preco_sugerido: 'R$ 47', preco_ancora: 'R$ 97', justificativa: 'faixa de impulso' },
      { mercado: 'México', preco_sugerido: 'MXN 249', preco_ancora: 'MXN 499', justificativa: 'faixa de impulso' },
    ],
    emails: [{ dia: 0, assunto: 'Seu mini-guia chegou', corpo: 'Corpo simulado.' }],
    videos_curtos: [{ gancho: 'Gancho simulado', roteiro: 'Roteiro simulado', cta: 'Link na bio' }],
    capa: { conceito: 'Fundo roxo, título grande', cores: ['#7C3AED', '#FFFFFF', '#FFD60A'], texto_capa: esboco.titulo_escolhido, prompt_canva: 'Passos simulados.' },
    isca_digital: { titulo: 'Mini-guia grátis', conteudo: '# Mini-guia\n\nConteúdo simulado.' },
  };
}
