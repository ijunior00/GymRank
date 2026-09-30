#!/usr/bin/env node
// Monta o Word (e os .md) a partir de JSON escrito à mão, sem chamar a API.
// Serve para livros revisados capítulo a capítulo e para livros com imagens.
//
//   node montar.mjs --pasta ../produtos/controle-total/pt-BR [--pdf]
//
// A pasta precisa ter:
//   livro.json      { idioma, nicho?, autor, marca?, cor?, corClara?, capa?, imagens?, aviso? }
//   esboco.json     no formato EsquemaEsboco
//   capitulos.json  lista no formato EsquemaCapitulo (+ blocos { tipo: "imagem", arquivo, texto })
//   vendas.json     (opcional) no formato EsquemaVendas
// As imagens ficam em <pasta>/imagens/ ou na pasta indicada em livro.json → imagens.
import fs from 'node:fs/promises';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { montarDocx } from './lib/docx.mjs';
import { capaEmMarkdown, livroEmMarkdown, vendasEmMarkdown } from './lib/markdown.mjs';
import { IDIOMAS, NICHOS } from './lib/prompts.mjs';
import { EsquemaCapituloLocal, EsquemaEsboco, EsquemaVendas } from './lib/schemas.mjs';

function lerArgumentos(argv) {
  const opts = { pasta: null, pdf: false };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--pasta') opts.pasta = argv[++i];
    else if (a === '--pdf') opts.pdf = true;
    else if (a === '--ajuda' || a === '-h') {
      console.log('Uso: node montar.mjs --pasta <pasta-do-livro> [--pdf]');
      process.exit(0);
    } else {
      console.error(`Opção desconhecida: ${a}`);
      process.exit(2);
    }
  }
  if (!opts.pasta) {
    console.error('Falta --pasta <pasta-do-livro>.');
    process.exit(2);
  }
  return opts;
}

async function lerJson(caminho, esquema, rotulo) {
  let bruto;
  try {
    bruto = JSON.parse(await fs.readFile(caminho, 'utf8'));
  } catch (e) {
    throw new Error(`${rotulo}: não consegui ler ${caminho} (${e.message})`);
  }
  if (!esquema) return bruto;
  const r = esquema.safeParse(bruto);
  if (!r.success) {
    const problemas = r.error.issues.slice(0, 12).map((i) => `  - ${i.path.join('.') || '(raiz)'}: ${i.message}`);
    throw new Error(`${rotulo}: o JSON não está no formato esperado.\n${problemas.join('\n')}`);
  }
  return r.data;
}

/** capitulos.json (lista) ou a pasta capitulos/ com um arquivo por capítulo (cap-01.json, cap-02.json…). */
async function lerCapitulos(pasta) {
  const unico = path.join(pasta, 'capitulos.json');
  if (await fs.access(unico).then(() => true, () => false)) return lerJson(unico, EsquemaCapituloLocal.array(), 'capitulos.json');
  const dir = path.join(pasta, 'capitulos');
  let nomes;
  try {
    nomes = (await fs.readdir(dir)).filter((n) => n.endsWith('.json')).sort();
  } catch {
    throw new Error(`Não achei capitulos.json nem a pasta capitulos/ em ${pasta}.`);
  }
  if (!nomes.length) throw new Error(`A pasta ${dir} está vazia.`);
  const capitulos = [];
  for (const nome of nomes) capitulos.push(await lerJson(path.join(dir, nome), EsquemaCapituloLocal, `capitulos/${nome}`));
  return capitulos;
}

async function lerImagens(pasta) {
  const imagens = {};
  let nomes = [];
  try {
    nomes = await fs.readdir(pasta);
  } catch {
    return imagens;
  }
  for (const nome of nomes) {
    if (!/\.(png|jpe?g)$/i.test(nome)) continue;
    imagens[nome] = await fs.readFile(path.join(pasta, nome));
  }
  return imagens;
}

async function main() {
  const opts = lerArgumentos(process.argv.slice(2));
  const pasta = path.resolve(opts.pasta);

  const livro = await lerJson(path.join(pasta, 'livro.json'), null, 'livro.json');
  if (!IDIOMAS[livro.idioma]) throw new Error(`livro.json: idioma inválido "${livro.idioma}" (use pt-BR, es-MX ou en-US).`);
  const nicho = NICHOS[livro.nicho ?? 'renda-extra'];
  if (!nicho) throw new Error(`livro.json: nicho inválido "${livro.nicho}".`);
  const aviso = livro.aviso ?? nicho.aviso[livro.idioma];

  const esboco = await lerJson(path.join(pasta, 'esboco.json'), EsquemaEsboco, 'esboco.json');
  const capitulos = await lerCapitulos(pasta);
  const pastaImagens = path.resolve(pasta, livro.imagens ?? 'imagens');
  const imagens = await lerImagens(pastaImagens);

  // Avisa sobre imagens citadas que não existem, antes de montar.
  const citadas = new Set();
  if (livro.capa) citadas.add(livro.capa);
  for (const c of capitulos) for (const s of c.secoes) for (const b of s.blocos) if (b.tipo === 'imagem') citadas.add(b.arquivo);
  const faltando = [...citadas].filter((n) => !imagens[n]);
  if (faltando.length) console.warn(`Atenção: ${faltando.length} imagem(ns) citada(s) e não encontrada(s) em ${pastaImagens}: ${faltando.join(', ')}`);

  const docx = await montarDocx({
    idioma: livro.idioma,
    esboco,
    capitulos,
    autor: livro.autor ?? nicho.autorPadrao[livro.idioma],
    marca: livro.marca,
    cor: livro.cor,
    corClara: livro.corClara,
    capa: livro.capa,
    imagens,
    aviso,
    ano: livro.ano,
  });
  await fs.writeFile(path.join(pasta, 'ebook.docx'), docx);
  await fs.writeFile(path.join(pasta, 'ebook.md'), livroEmMarkdown({ idioma: livro.idioma, esboco, capitulos, aviso }));

  const caminhoVendas = path.join(pasta, 'vendas.json');
  const existeVendas = await fs.access(caminhoVendas).then(() => true, () => false);
  const vendas = existeVendas ? await lerJson(caminhoVendas, EsquemaVendas, 'vendas.json') : null;
  if (vendas) {
    await fs.writeFile(path.join(pasta, 'vendas.md'), vendasEmMarkdown(vendas, esboco));
    await fs.writeFile(path.join(pasta, 'isca-digital.md'), `# ${vendas.isca_digital.titulo}\n\n${vendas.isca_digital.conteudo}\n`);
    await fs.writeFile(path.join(pasta, 'capa-canva.md'), capaEmMarkdown(vendas.capa, esboco));
  }

  const palavras = capitulos.reduce((n, c) => n + JSON.stringify(c).split(/\s+/).length, 0);
  console.log(`ebook.docx montado: ${capitulos.length} capítulos, ~${palavras} palavras, ${citadas.size - faltando.length} imagens.${vendas ? ' vendas.md, isca-digital.md e capa-canva.md também.' : ''}`);

  if (opts.pdf) {
    // O LibreOffice devolve código 0 mesmo quando falha; a prova é o arquivo existir.
    const caminhoPdf = path.join(pasta, 'ebook.pdf');
    await fs.rm(caminhoPdf, { force: true });
    const r = spawnSync('soffice', ['--headless', '--convert-to', 'pdf', '--outdir', pasta, path.join(pasta, 'ebook.docx')], { encoding: 'utf8' });
    const gerou = await fs.access(caminhoPdf).then(() => true, () => false);
    if (gerou) console.log('ebook.pdf gerado com o LibreOffice (conferência; o PDF final sai do Word).');
    else console.warn(`Não consegui gerar o PDF com o LibreOffice (${(r.stderr || r.error?.message || 'não encontrado').trim()}). Abra o .docx no Word e salve como PDF.`);
  }
}

main().catch((e) => {
  console.error(`\nDeu errado: ${e.message}`);
  process.exit(1);
});
