#!/usr/bin/env node
// Gera um e-book completo + material de venda.
//
//   node --env-file-if-exists=.env gerar.mjs --tema "..." --publico "..." --idioma pt-BR [--nicho saude]
//
// Etapas: pesquisa na web → esboço → capítulos → revisão de editor →
// material de venda → Word + arquivos. Veja o README.md ao lado.
import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { ClienteClaude, explicaErro } from './lib/claude.mjs';
import { montarDocx } from './lib/docx.mjs';
import { capaEmMarkdown, livroEmMarkdown, vendasEmMarkdown } from './lib/markdown.mjs';
import { IDIOMAS, NICHOS, persona, promptCapitulo, promptEsboco, promptPesquisa, promptRevisao, promptVendas } from './lib/prompts.mjs';
import { EsquemaCapitulo, EsquemaEsboco, EsquemaRevisao, EsquemaVendas } from './lib/schemas.mjs';
import { capituloSimulado, esbocoSimulado, vendasSimuladas } from './lib/simulado.mjs';

const aqui = path.dirname(fileURLToPath(import.meta.url));

function lerArgumentos(argv) {
  const opts = {
    tema: null,
    publico: 'pessoas que querem uma renda extra sem largar o emprego',
    idioma: 'pt-BR',
    nicho: 'renda-extra',
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
      case '--nicho': opts.nicho = v(); break;
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
  --nicho renda-extra renda-extra (padrão) ou saude (guias de treino/saúde: muda a persona,
                      a pesquisa e o aviso legal)
  --capitulos 8       Quantidade de capítulos (6 a 12)
  --autor "Nome"      Nome que sai na capa (padrão: pen name genérico por idioma)
  --rapido            Pula a revisão de editor (mais barato, um pouco menos polido)
  --sem-pesquisa      Pula a busca na web (não recomendado para o e-book final)
  --modelo id         Modelo da API (padrão claude-opus-5)
  --esforco nivel     low | medium | high | xhigh (padrão do modelo: high)
  --saida pasta       Onde salvar (padrão: ./saida)
  --simular           Não chama a API: gera arquivos de exemplo para testar o Word

Para montar o Word a partir de JSON escrito à mão (com imagens), use montar.mjs.`);
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
  if (!NICHOS[opts.nicho]) {
    console.error(`Nicho inválido: ${opts.nicho}. Use ${Object.keys(NICHOS).join(' ou ')}.`);
    process.exit(2);
  }
  if (!opts.simular && !process.env.ANTHROPIC_API_KEY) {
    console.error('Falta a chave da API. Copie .env.exemplo para .env e cole a sua chave nele (ANTHROPIC_API_KEY=...).');
    process.exit(2);
  }
  const idioma = IDIOMAS[opts.idioma];
  const nicho = NICHOS[opts.nicho];
  const autor = opts.autor ?? nicho.autorPadrao[opts.idioma];
  const aviso = nicho.aviso[opts.idioma];
  const pasta = path.join(opts.saida, `${slug(opts.tema)}-${new Date().toISOString().slice(0, 10)}`);
  await fs.mkdir(pasta, { recursive: true });

  log(`Tema: ${opts.tema}`);
  log(`Público: ${opts.publico} · Idioma: ${opts.idioma} · Nicho: ${opts.nicho} · Capítulos: ${opts.capitulos}${opts.simular ? ' · MODO SIMULADO' : ''}`);
  const inicio = Date.now();

  const base = { idioma: opts.idioma, tema: opts.tema, publico: opts.publico, nicho: opts.nicho };
  const sistema = persona(base);
  const claude = opts.simular ? null : new ClienteClaude({ modelo: opts.modelo, esforco: opts.esforco, log });

  // 1. Pesquisa
  let briefing = '';
  if (opts.simular) {
    briefing = '(briefing simulado)';
  } else if (opts.pesquisar) {
    log('1/5 Pesquisando na web (2 a 5 min)…');
    briefing = await claude.pesquisar({ sistema, pergunta: promptPesquisa(base) });
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
        pergunta: promptEsboco({ ...base, briefing, capitulos: opts.capitulos }),
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
          pergunta: promptCapitulo({ idioma: opts.idioma, nicho: opts.nicho, esboco, capitulo: c, anteriores }),
          esquema: EsquemaCapitulo,
          etapa: `capítulo ${c.numero}`,
        });
    if (opts.revisar && !opts.simular) {
      log(`4/5 Revisão de editor do capítulo ${c.numero}…`);
      const revisao = await claude.estruturado({
        sistema: sistemaLivro,
        pergunta: promptRevisao({ idioma: opts.idioma, nicho: opts.nicho, esboco, capitulo }),
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
        pergunta: promptVendas({ idioma: opts.idioma, nicho: opts.nicho, tema: opts.tema, esboco, resumos: anteriores }),
        esquema: EsquemaVendas,
        etapa: 'material de venda',
      });
  await fs.writeFile(path.join(pasta, 'vendas.json'), JSON.stringify(vendas, null, 2));

  // Arquivos finais
  const docx = await montarDocx({ idioma: opts.idioma, esboco, capitulos, autor, aviso });
  await fs.writeFile(path.join(pasta, 'ebook.docx'), docx);
  await fs.writeFile(path.join(pasta, 'ebook.md'), livroEmMarkdown({ idioma: opts.idioma, esboco, capitulos, aviso }));
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

main().catch((error) => {
  console.error(`\nDeu errado: ${explicaErro(error)}`);
  process.exit(1);
});
