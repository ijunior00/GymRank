// Versões em markdown do livro e do material de venda (para ler no GitHub,
// colar na plataforma ou conferir sem abrir o Word).
import { IDIOMAS } from './prompts.mjs';

export function livroEmMarkdown({ idioma, esboco, capitulos, aviso }) {
  const L = IDIOMAS[idioma].rotulos;
  const out = [`# ${esboco.titulo_escolhido}`, `_${esboco.subtitulo_escolhido}_`, '', esboco.promessa, ''];
  capitulos.forEach((c, i) => {
    out.push(`## ${L.capitulo} ${i + 1} · ${c.titulo}`, '', c.abertura, '');
    for (const s of c.secoes) {
      out.push(`### ${s.titulo}`, '');
      for (const b of s.blocos) {
        if (b.tipo === 'imagem') {
          out.push(`![${b.texto ?? ''}](imagens/${b.arquivo})`, '');
        } else if (b.itens?.length) {
          const marca = b.tipo === 'passos' ? (k) => `${k + 1}.` : b.tipo === 'checklist' ? () => '- [ ]' : () => '-';
          out.push(...b.itens.map((t, k) => `${marca(k)} ${t}`), '');
        } else if (b.texto) {
          const prefixo = { dica: '💡 ', exemplo: '📌 ', atencao: '⚠️ ', citacao: '> ' }[b.tipo] ?? '';
          out.push(`${prefixo}${b.texto}`, '');
        }
      }
    }
    out.push(`**${L.resumo}**`, ...c.resumo.map((r) => `- ${r}`), '', `**${L.acao}**`, ...c.acao_agora.map((r) => `- [ ] ${r}`), '');
  });
  out.push(`## ${L.bonus}`, '');
  for (const b of esboco.bonus ?? []) out.push(`### ${b.nome}`, '', b.descricao, '');
  out.push(`_${aviso ?? L.aviso}_`, '');
  return out.join('\n');
}

export function vendasEmMarkdown(v, esboco) {
  const sec = (t) => `\n## ${t}\n`;
  const out = [`# Material de venda · ${esboco.titulo_escolhido}`];
  out.push(sec('Título e subtítulo da página'), `**${v.titulo_pagina}**`, '', v.subtitulo_pagina);
  out.push(sec('Descrição longa (cole na Hotmart/Kiwify/Gumroad)'), v.descricao_longa);
  out.push(sec('Bullets de benefício'), ...v.bullets.map((b) => `- ${b}`));
  out.push(sec('Para quem é'), ...v.para_quem_e.map((b) => `- ${b}`));
  out.push(sec('Para quem NÃO é'), ...v.para_quem_nao_e.map((b) => `- ${b}`));
  out.push(sec('Bônus'), ...v.bonus.map((b) => `- **${b.nome}**: ${b.descricao}`));
  out.push(sec('Garantia'), v.garantia);
  out.push(sec('Perguntas frequentes'), ...v.faq.map((f) => `**${f.pergunta}**\n${f.resposta}\n`));
  out.push(sec('Preços sugeridos'), ...v.precos.map((p) => `- **${p.mercado}**: ${p.preco_sugerido} (âncora ${p.preco_ancora}) — ${p.justificativa}`));
  out.push(sec('Sequência de 5 e-mails (para quem baixou a isca)'), ...v.emails.map((e) => `### Dia ${e.dia} · ${e.assunto}\n\n${e.corpo}\n`));
  out.push(sec('10 roteiros de vídeo curto'), ...v.videos_curtos.map((r, i) => `### Vídeo ${i + 1}\n**Gancho:** ${r.gancho}\n\n${r.roteiro}\n\n**CTA:** ${r.cta}\n`));
  out.push(sec('Alternativas de título'), ...(esboco.titulos ?? []).map((t) => `- **${t.titulo}** — ${t.subtitulo} _(${t.por_que_converte})_`));
  return out.join('\n');
}

export function capaEmMarkdown(capa, esboco) {
  return `# Capa · ${esboco.titulo_escolhido}

**Conceito:** ${capa.conceito}

**Cores:** ${capa.cores.join(', ')}

**Texto exato da capa:**

${capa.texto_capa}

## Passo a passo no Canva

${capa.prompt_canva}
`;
}
