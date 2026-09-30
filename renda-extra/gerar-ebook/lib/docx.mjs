// Monta o Word do e-book: capa, "antes de começar", sumário, capítulos com
// blocos formatados (passos, checklists, dicas em caixa), bônus e aviso.
import {
  AlignmentType,
  BorderStyle,
  Document,
  Footer,
  HeadingLevel,
  ImageRun,
  LevelFormat,
  PageBreak,
  PageNumber,
  Packer,
  Paragraph,
  ShadingType,
  TableOfContents,
  TextRun,
} from 'docx';
import { IDIOMAS } from './prompts.mjs';

const ROXO = '7C3AED';
const ROXO_CLARO = 'F2EBFC';
const AMARELO_CLARO = 'FFF6DA';
const VERMELHO_CLARO = 'FDE8E8';
const VERDE_CLARO = 'E7F6EC';
const CINZA = '6B6B75';
const LINHA = 'D8D4E0';

const LETTER = { width: 12240, height: 15840 };
const MARGEM = 1300;

// Cor principal do livro. O padrão é o roxo; montarDocx troca por livro.cor.
const T = { primaria: ROXO, primariaClara: ROXO_CLARO };

const paragrafo = (texto, extra = {}) =>
  new Paragraph({
    spacing: { after: 140, line: 312 },
    ...extra,
    children: negritos(texto, extra.run ?? {}),
  });

/** Suporta **negrito** dentro do texto, o resto sai como veio. */
function negritos(texto, run = {}) {
  const partes = String(texto).split(/(\*\*[^*]+\*\*)/g).filter(Boolean);
  return partes.map((p) =>
    p.startsWith('**') && p.endsWith('**')
      ? new TextRun({ text: p.slice(2, -2), bold: true, size: 22, ...run })
      : new TextRun({ text: p, size: 22, ...run }),
  );
}

const h1 = (texto) =>
  new Paragraph({
    heading: HeadingLevel.HEADING_1,
    spacing: { before: 0, after: 200 },
    children: [new TextRun({ text: texto, bold: true, size: 40, color: T.primaria })],
  });

const h2 = (texto) =>
  new Paragraph({
    heading: HeadingLevel.HEADING_2,
    spacing: { before: 320, after: 120 },
    children: [new TextRun({ text: texto, bold: true, size: 28 })],
  });

const h3 = (texto) =>
  new Paragraph({
    heading: HeadingLevel.HEADING_3,
    spacing: { before: 240, after: 80 },
    children: [new TextRun({ text: texto, bold: true, size: 24, color: T.primaria })],
  });

// Cada lista numerada recebe uma instância própria; sem isso o Word continua
// a contagem de um capítulo para o outro (passo 120, 121…).
let instanciaNumerada = 0;

function lista(itens, referencia) {
  const instance = referencia === 'passos' ? ++instanciaNumerada : undefined;
  return itens.map(
    (t) =>
      new Paragraph({
        numbering: { reference: referencia, level: 0, instance },
        spacing: { after: 80, line: 300 },
        children: negritos(t),
      }),
  );
}

const checklist = (itens) =>
  itens.map(
    (t) =>
      new Paragraph({
        spacing: { after: 80, line: 300 },
        indent: { left: 360 },
        children: [new TextRun({ text: '☐  ', size: 24 }), ...negritos(t)],
      }),
  );

/** Caixa colorida com rótulo em negrito (dica, exemplo, atenção). */
function caixa(rotulo, texto, fundo) {
  return new Paragraph({
    spacing: { before: 120, after: 180, line: 300 },
    shading: { type: ShadingType.CLEAR, fill: fundo, color: 'auto' },
    border: {
      left: { style: BorderStyle.SINGLE, size: 24, color: T.primaria },
    },
    indent: { left: 200, right: 200 },
    children: [new TextRun({ text: `${rotulo}: `, bold: true, size: 22 }), ...negritos(texto)],
  });
}

const citacao = (texto) =>
  new Paragraph({
    spacing: { before: 120, after: 160 },
    indent: { left: 600, right: 600 },
    children: [new TextRun({ text: `“${texto}”`, italics: true, size: 22, color: CINZA })],
  });

/** Largura, altura e tipo de um PNG ou JPEG, lendo só o cabeçalho. */
function dimensoes(buf) {
  if (buf[0] === 0x89 && buf[1] === 0x50) {
    return { width: buf.readUInt32BE(16), height: buf.readUInt32BE(20), type: 'png' };
  }
  if (buf[0] === 0xff && buf[1] === 0xd8) {
    let i = 2;
    while (i + 9 < buf.length) {
      if (buf[i] !== 0xff) {
        i++;
        continue;
      }
      const marcador = buf[i + 1];
      const inicioDeQuadro = marcador >= 0xc0 && marcador <= 0xcf && ![0xc4, 0xc8, 0xcc].includes(marcador);
      if (inicioDeQuadro) return { height: buf.readUInt16BE(i + 5), width: buf.readUInt16BE(i + 7), type: 'jpg' };
      i += 2 + buf.readUInt16BE(i + 2);
    }
  }
  throw new Error('A imagem precisa ser PNG ou JPEG.');
}

const LARGURA_MAX_PX = 560; // ≈ 5,8 polegadas a 96 dpi: cabe na página Letter com as margens

/** Imagem centralizada com legenda opcional. `ctx.imagens[arquivo]` é o Buffer do arquivo. */
function imagem(arquivo, legenda, ctx, { larguraPx = LARGURA_MAX_PX, alturaPx = 700 } = {}) {
  const data = ctx.imagens?.[arquivo];
  if (!data) return [caixa('Imagem', `falta o arquivo ${arquivo} na pasta imagens/`, AMARELO_CLARO)];
  const d = dimensoes(data);
  let width = Math.min(larguraPx, d.width);
  let height = Math.round((d.height / d.width) * width);
  if (height > alturaPx) {
    height = alturaPx;
    width = Math.round((d.width / d.height) * height);
  }
  const saida = [
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: 160, after: legenda ? 60 : 200 },
      keepNext: Boolean(legenda),
      children: [
        new ImageRun({
          type: d.type,
          data,
          transformation: { width, height },
          altText: { title: arquivo, description: legenda || arquivo, name: arquivo },
        }),
      ],
    }),
  ];
  if (legenda) {
    saida.push(
      new Paragraph({
        alignment: AlignmentType.CENTER,
        spacing: { after: 220 },
        children: [new TextRun({ text: legenda, italics: true, size: 18, color: CINZA })],
      }),
    );
  }
  return saida;
}

function bloco(b, r, ctx = {}) {
  switch (b.tipo) {
    case 'imagem':
      return imagem(b.arquivo, b.texto, ctx, { larguraPx: b.largura ?? LARGURA_MAX_PX });
    case 'paragrafo':
      return [paragrafo(b.texto ?? '')];
    case 'topicos':
      return lista(b.itens ?? [], 'topicos');
    case 'passos':
      return lista(b.itens ?? [], 'passos');
    case 'checklist':
      return checklist(b.itens ?? []);
    case 'dica':
      return [caixa(r.dica, b.texto ?? '', VERDE_CLARO)];
    case 'exemplo':
      return [caixa(r.exemplo, b.texto ?? '', T.primariaClara)];
    case 'atencao':
      return [caixa(r.atencao, b.texto ?? '', VERMELHO_CLARO)];
    case 'citacao':
      return [citacao(b.texto ?? '')];
    default:
      return [paragrafo(b.texto ?? (b.itens ?? []).join(' '))];
  }
}

const ROTULOS_CAIXA = {
  'pt-BR': { dica: 'Dica', exemplo: 'Exemplo real', atencao: 'Atenção' },
  'es-MX': { dica: 'Tip', exemplo: 'Ejemplo real', atencao: 'Ojo' },
  'en-US': { dica: 'Tip', exemplo: 'Real example', atencao: 'Watch out' },
};

// As três linhas de "Como usar este e-book", por idioma.
const COMO_USAR = {
  'pt-BR': (L, n) => [
    `${L.capitulo} 1 → ${L.capitulo} ${n}: cada um termina com "${L.acao}", tarefas para hoje.`,
    '☐ = checklist para marcar. Imprima ou copie para o celular.',
    `${L.bonus}: modelos e planos prontos no final.`,
  ],
  'es-MX': (L, n) => [
    `${L.capitulo} 1 → ${L.capitulo} ${n}: cada uno termina con "${L.acao}", tareas para hoy.`,
    '☐ = lista para marcar. Imprímela o cópiala en tu celular.',
    `${L.bonus}: plantillas y planes listos al final.`,
  ],
  'en-US': (L, n) => [
    `${L.capitulo} 1 → ${L.capitulo} ${n}: each one ends with "${L.acao}", tasks for today.`,
    '☐ = checklist to tick. Print it or copy it to your phone.',
    `${L.bonus}: ready-made templates and plans at the end.`,
  ],
};

/**
 * @param {object} livro {
 *   idioma, esboco, capitulos: [EsquemaCapitulo], autor, ano,
 *   marca?: linha pequena no topo da capa,
 *   imagens?: { 'arquivo.png': Buffer }, capa?: nome da imagem da capa,
 *   cor?: hex da cor principal (sem #), corClara?: hex do fundo das caixas de exemplo,
 *   aviso?: texto do aviso legal (padrão: o do idioma)
 * }
 * @returns {Promise<Buffer>}
 */
export async function montarDocx(livro) {
  const { idioma, esboco, capitulos, autor } = livro;
  const L = IDIOMAS[idioma].rotulos;
  const R = ROTULOS_CAIXA[idioma];
  const ano = livro.ano ?? new Date().getFullYear();
  const aviso = livro.aviso ?? L.aviso;
  T.primaria = livro.cor ?? ROXO;
  T.primariaClara = livro.corClara ?? ROXO_CLARO;
  const ctx = { imagens: livro.imagens ?? {} };
  const temCapa = Boolean(livro.capa && ctx.imagens[livro.capa]);

  const capa = [
    new Paragraph({ spacing: { before: temCapa ? 300 : 3200 }, children: [] }),
    ...(livro.marca
      ? [
          new Paragraph({
            alignment: AlignmentType.CENTER,
            spacing: { after: 240 },
            children: [new TextRun({ text: livro.marca.toUpperCase(), size: 22, color: CINZA, characterSpacing: 60 })],
          }),
        ]
      : []),
    ...(temCapa ? imagem(livro.capa, null, ctx, { larguraPx: 600, alturaPx: 470 }) : []),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: temCapa ? 200 : 0, after: 240 },
      children: [new TextRun({ text: esboco.titulo_escolhido, bold: true, size: 64, color: T.primaria })],
    }),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { after: temCapa ? 500 : 1200 },
      children: [new TextRun({ text: esboco.subtitulo_escolhido, size: 30, color: CINZA })],
    }),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      children: [new TextRun({ text: autor, size: 26 })],
    }),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      children: [new TextRun({ text: `${ano}`, size: 22, color: CINZA })],
    }),
    new Paragraph({ children: [new PageBreak()] }),
  ];

  const antes = [
    h1(L.antes),
    paragrafo(esboco.promessa, { run: { bold: true } }),
    paragrafo(esboco.publico),
    h2(L.comoUsar),
    ...lista(COMO_USAR[idioma](L, capitulos.length), 'topicos'),
    new Paragraph({ spacing: { before: 200 }, children: [new TextRun({ text: aviso, italics: true, size: 18, color: CINZA })] }),
    new Paragraph({ children: [new PageBreak()] }),
    h1(L.sumario),
    new TableOfContents(L.sumario, { hyperlink: true, headingStyleRange: '1-2' }),
    new Paragraph({ children: [new PageBreak()] }),
  ];

  const corpo = [];
  capitulos.forEach((c, idx) => {
    corpo.push(h1(`${L.capitulo} ${idx + 1} · ${c.titulo}`));
    for (const p of String(c.abertura).split(/\n+/).filter(Boolean)) corpo.push(paragrafo(p));
    for (const s of c.secoes) {
      corpo.push(h2(s.titulo));
      for (const b of s.blocos) corpo.push(...bloco(b, R, ctx));
    }
    corpo.push(h3(L.resumo));
    corpo.push(...lista(c.resumo, 'topicos'));
    corpo.push(h3(L.acao));
    corpo.push(...checklist(c.acao_agora));
    corpo.push(new Paragraph({ children: [new PageBreak()] }));
  });

  const bonus = [h1(L.bonus)];
  for (const b of esboco.bonus ?? []) {
    bonus.push(h2(b.nome));
    for (const p of String(b.descricao).split(/\n+/).filter(Boolean)) bonus.push(paragrafo(p));
  }
  bonus.push(new Paragraph({ spacing: { before: 400 }, children: [new TextRun({ text: aviso, italics: true, size: 18, color: CINZA })] }));

  const doc = new Document({
    creator: autor,
    title: esboco.titulo_escolhido,
    description: esboco.promessa,
    styles: {
      default: { document: { run: { font: 'Calibri', size: 22 } } },
      paragraphStyles: [
        { id: 'Heading1', name: 'Heading 1', basedOn: 'Normal', next: 'Normal', quickFormat: true, run: { bold: true, size: 40, color: T.primaria, font: 'Calibri' }, paragraph: { spacing: { after: 200 } } },
        { id: 'Heading2', name: 'Heading 2', basedOn: 'Normal', next: 'Normal', quickFormat: true, run: { bold: true, size: 28, font: 'Calibri' }, paragraph: { spacing: { before: 320, after: 120 } } },
        { id: 'Heading3', name: 'Heading 3', basedOn: 'Normal', next: 'Normal', quickFormat: true, run: { bold: true, size: 24, color: T.primaria, font: 'Calibri' } },
      ],
    },
    numbering: {
      config: [
        {
          reference: 'topicos',
          levels: [{ level: 0, format: LevelFormat.BULLET, text: '•', alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 540, hanging: 300 } } } }],
        },
        {
          reference: 'passos',
          levels: [{ level: 0, format: LevelFormat.DECIMAL, text: '%1.', alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 540, hanging: 300 } } } }],
        },
      ],
    },
    features: { updateFields: true },
    sections: [
      {
        properties: {
          page: { size: LETTER, margin: { top: MARGEM, bottom: MARGEM, left: MARGEM, right: MARGEM } },
        },
        footers: {
          default: new Footer({
            children: [
              new Paragraph({
                alignment: AlignmentType.CENTER,
                border: { top: { style: BorderStyle.SINGLE, size: 2, color: LINHA } },
                children: [
                  new TextRun({ text: `${esboco.titulo_escolhido}  ·  `, size: 16, color: CINZA }),
                  new TextRun({ children: [PageNumber.CURRENT], size: 16, color: CINZA }),
                ],
              }),
            ],
          }),
        },
        children: [...capa, ...antes, ...corpo, ...bonus],
      },
    ],
  });

  return Packer.toBuffer(doc);
}
