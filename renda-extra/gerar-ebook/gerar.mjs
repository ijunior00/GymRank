#!/usr/bin/env node
// Gera um e-book completo de renda extra + material de venda.
//
//   node --env-file-if-exists=.env gerar.mjs --tema "..." --publico "..." --idioma pt-BR
//
// Etapas: pesquisa na web → esboço → capítulos → revisão de editor →
// material de venda → Word + arquivos. Veja o README.md ao lado.
import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { ClienteClaude, explicaErro } from './lib/claude.mjs';
import { montarDocx } from './lib/docx.mjs';
import { IDIOMAS, persona, promptCapitulo, promptEsboco, promptPesquisa, promptRevisao, promptVendas } from './lib/prompts.mjs';
import { EsquemaCapitulo, EsquemaEsboco, EsquemaRevisao, EsquemaVendas } from './lib/schemas.mjs';
import { capituloSimulado, esbocoSimulado, vendasSimuladas } from './lib/simulado.mjs';

const aqui = path.dirname(fileURLToPath(import.meta.url));

function lerArgumentos(argv) {
  const opts = {
    tema: null,
    publico: 'pessoas que querem uma renda extra sem largar o emprego',
    idioma: 'pt-BR',
    capitulos: 8,
    modelo: 'claude-opus-5',
    esforco: null,
    autor: null,
    revisar: true,
    pesquisar: true,
    simular: false,
    saida: path.join(aqui, 'saida'),
  };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    const v = () => argv[++i];
    switch (a) {
      case '--tema': opts.tema = v(); break;
      case '--publico': opts.publico = v(); break;
      case '--idioma': opts.idioma = v(); break;
      case '--capitulos': opts.capitulos = Number(v()); break;
      case '--modelo': opts.modelo = v(); break;
      case '--esforco': opts.esforco = v(); break;
      case '--autor': opts.autor = v(); break;
      case '--saida': opts.saida = v(); break;
      case '--rapido': opts.revisar = false; break;
      case '--sem-pesquisa': opts.pesquisar = false; break;
      case '--simular': opts.simular = true; break;
      case '--ajuda': case '-h': imprimeAjuda(); process.exit(0);
      default:
        console.error(`Opção desconhecida: ${a}`);
        imprimeAjuda();
        process.exit(2);
    }
  }
  return opts;
}

function imprimeAjuda() {
  console.log(`Uso: node --env-file-if-exists=.env gerar.mjs --tema "..." [opções]

  --tema "..."        Tema do e-book (obrigatório). Ex.: "Renda extra vendendo doces caseiros"
  --publico "..."     Para quem é. Ex.: "mães que querem trabalhar de casa"
  --idioma pt-BR      pt-BR (Brasil), es-MX (México/LatAm) ou en-US (EUA/Europa)
  --capitulos 8       Quantidade de capítulos (6 a 12)
  --autor "Nome"      Nome que sai na capa (padrão: pen name genérico por idioma)
  --rapido            Pula a revisão de editor (mais barato, um pouco menos polido)
  --sem-pesquisa      Pula a busca na web (não recomendado para o e-book final)
  --modelo id         Modelo da API (padrão claude-opus-5)
  --esforco nivel     low | medium | high | xhigh (padrão do modelo: high)
  --saida pasta       Onde salvar (padrão: ./saida)
  --simular           Não chama a API: gera arquivos de exemplo para testar o Word`);
}

const slug = (s) =>
  s.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '').slice(0, 60);

const agora = () => new Date().toLocaleTimeString('pt-BR', { hour12: false });
const log = (m) => console.log(`[${agora()}] ${m}`);

async function main() {
  const opts = lerArgumentos(process.argv.slice(2));
  if (!opts.tema) {
    imprimeAjuda();
    process.exit(2);
  }
  if (!IDIOMAS[opts.idioma]) {
    console.error(`Idioma inválido: ${opts.idioma}. Use pt-BR, es-MX ou en-US.`);
    process.exit(2);
  }
  if (!opts.simular && !process.env.ANTHROPIC_API_KEY) {
    console.error('Falta a chave da API. Copie .env.exemplo para .env e cole a sua chave nele (ANTHROPIC_API_KEY=...).');
    process.exit(2);
  }
  const idioma = IDIOMAS[opts.idioma];
  const autor = opts.autor ?? { 'pt-BR': 'Equipe Renda Extra', 'es-MX': 'Equipo Ingreso Extra', 'en-US': 'The Side Income Team' }[opts.idioma];
  const pasta = path.join(opts.saida, `${slug(opts.tema)}-${new Date().toISOString().slice(0, 10)}`);
  await fs.mkdir(pasta, { recursive: true });

  log(`Tema: ${opts.tema}`);
  log(`Público: ${opts.publico} · Idioma: ${opts.idioma} · Capítulos: ${opts.capitulos}${opts.simular ? ' · MODO SIMULADO' : ''}`);
  const inicio = Date.now();

  const sistema = persona({ idioma: opts.idioma, tema: opts.tema, publico: opts.publico });
  const claude = opts.simular ? null : new ClienteClaude({ modelo: opts.modelo, esforco: opts.esforco, log });

  // 1. Pesquisa
  let briefing = '';
  if (opts.simular) {
    briefing = '(briefing simulado)';
  } else if (opts.pesquisar) {
    log('1/5 Pesquisando na web (2 a 5 min)…');
    briefing = await claude.pesquisar({ sistema, pergunta: promptPesquisa({ idioma: opts.idioma, tema: opts.tema, publico: opts.publico }) });
    await fs.writeFile(path.join(pasta, 'pesquisa.md'), briefing);
    log(`    briefing com ${briefing.split(/\s+/).length} palavras salvo em pesquisa.md`);
  } else {
    log('1/5 Pesquisa pulada (--sem-pesquisa).');
    briefing = 'Sem pesquisa web nesta rodada: use o seu conhecimento, marque estimativas como estimativas.';
  }

  // 2. Esboço
  log('2/5 Montando o esboço (títulos, capítulos, bônus)…');
  const esboco = opts.simular
    ? esbocoSimulado({ tema: opts.tema, publico: opts.publico })
    : await claude.estruturado({
        sistema,
        pergunta: promptEsboco({ idioma: opts.idioma, tema: opts.tema, publico: opts.publico, briefing, capitulos: opts.capitulos }),
        esquema: EsquemaEsboco,
        etapa: 'esboço',
      });
  await fs.writeFile(path.join(pasta, 'esboco.json'), JSON.stringify(esboco, null, 2));
  log(`    título: ${esboco.titulo_escolhido} — ${esboco.subtitulo_escolhido}`);

  // 3 e 4. Capítulos (+ revisão)
  const sistemaLivro = `${sistema}

<esboco_do_livro>
${JSON.stringify(esboco)}
</esboco_do_livro>

<briefing_de_pesquisa>
${briefing}
</briefing_de_pesquisa>`;

  const capitulos = [];
  const anteriores = [];
  for (const c of esboco.capitulos) {
    log(`3/5 Escrevendo capítulo ${c.numero}/${esboco.capitulos.length}: ${c.titulo}`);
    let capitulo = opts.simular
      ? capituloSimulado(c, idioma.moeda)
      : await claude.estruturado({
          sistema: sistemaLivro,
          pergunta: promptCapitulo({ idioma: opts.idioma, esboco, capitulo: c, anteriores }),
          esquema: EsquemaCapitulo,
          etapa: `capítulo ${c.numero}`,
        });
    if (opts.revisar && !opts.simular) {
      log(`4/5 Revisão de editor do capítulo ${c.numero}…`);
      const revisao = await claude.estruturado({
        sistema: sistemaLivro,
        pergunta: promptRevisao({ idioma: opts.idioma, esboco, capitulo }),
        esquema: EsquemaRevisao,
        etapa: `revisão do capítulo ${c.numero}`,
      });
      capitulo = revisao.capitulo;
      await fs.appendFile(path.join(pasta, 'revisao.md'), `## Capítulo ${c.numero}\n${revisao.melhorias.map((m) => `- ${m}`).join('\n')}\n\n`);
    }
    capitulos.push(capitulo);
    anteriores.push({ numero: c.numero, titulo: capitulo.titulo, resumo: capitulo.resumo });
    await fs.writeFile(path.join(pasta, 'capitulos.json'), JSON.stringify(capitulos, null, 2));
  }

  // 5. Material de venda
  log('5/5 Criando página de vendas, e-mails, roteiros de vídeo, capa e isca…');
  const vendas = opts.simular
    ? vendasSimuladas(esboco)
    : await claude.estruturado({
        sistema: sistemaLivro,
        pergunta: promptVendas({ idioma: opts.idioma, tema: opts.tema, esboco, resumos: anteriores }),
        esquema: EsquemaVendas,
        etapa: 'material de venda',
      });

  // Arquivos finais
  const docx = await montarDocx({ idioma: opts.idioma, esboco, capitulos, autor });
  await fs.writeFile(path.join(pasta, 'ebook.docx'), docx);
  await fs.writeFile(path.join(pasta, 'ebook.md'), livroEmMarkdown({ idioma: opts.idioma, esboco, capitulos }));
  await fs.writeFile(path.join(pasta, 'vendas.md'), vendasEmMarkdown(vendas, esboco));
  await fs.writeFile(path.join(pasta, 'isca-digital.md'), `# ${vendas.isca_digital.titulo}\n\n${vendas.isca_digital.conteudo}\n`);
  await fs.writeFile(path.join(pasta, 'capa-canva.md'), capaEmMarkdown(vendas.capa, esboco));

  const palavras = capitulos.reduce((n, c) => n + JSON.stringify(c).split(/\s+/).length, 0);
  const minutos = ((Date.now() - inicio) / 60000).toFixed(1);
  log(`Pronto em ${minutos} min. ~${palavras} palavras em ${capitulos.length} capítulos.`);
  if (claude) {
    const u = claude.uso;
    log(`Uso da API: ${u.entrada + u.cacheLido + u.cacheEscrito} tokens de entrada (${u.cacheLido} do cache), ${u.saida} de saída, ${u.buscas} buscas. Custo estimado: US$ ${claude.custoEstimadoUsd().toFixed(2)}.`);
  }
  console.log(`\nArquivos em: ${pasta}
  ebook.docx        → abra no Word, revise, exporte em PDF
  vendas.md         → página de vendas, preços, e-mails, roteiros de vídeo
  capa-canva.md     → como montar a capa no Canva
  isca-digital.md   → mini-guia grátis para capturar e-mails
  pesquisa.md       → o que o Claude achou na web (confira os números!)`);
}

function livroEmMarkdown({ idioma, esboco, capitulos }) {
  const L = IDIOMAS[idioma].rotulos;
  const out = [`# ${esboco.titulo_escolhido}`, `_${esboco.subtitulo_escolhido}_`, '', esboco.promessa, ''];
  capitulos.forEach((c, i) => {
    out.push(`## ${L.capitulo} ${i + 1} · ${c.titulo}`, '', c.abertura, '');
    for (const s of c.secoes) {
      out.push(`### ${s.titulo}`, '');
      for (const b of s.blocos) {
        if (b.itens?.length) {
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
  out.push(`_${L.aviso}_`, '');
  return out.join('\n');
}

function vendasEmMarkdown(v, esboco) {
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

function capaEmMarkdown(capa, esboco) {
  return `# Capa · ${esboco.titulo_escolhido}

**Conceito:** ${capa.conceito}

**Cores:** ${capa.cores.join(', ')}

**Texto exato da capa:**

${capa.texto_capa}

## Passo a passo no Canva

${capa.prompt_canva}
`;
}

main().catch((error) => {
  console.error(`\nDeu errado: ${explicaErro(error)}`);
  process.exit(1);
});
