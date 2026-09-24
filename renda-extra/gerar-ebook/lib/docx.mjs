// Monta o Word do e-book: capa, "antes de começar", sumário, capítulos com
// blocos formatados (passos, checklists, dicas em caixa), bônus e aviso.
import {
  AlignmentType,
  BorderStyle,
  Document,
  Footer,
  HeadingLevel,
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
    children: [new TextRun({ text: texto, bold: true, size: 40, color: ROXO })],
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
    children: [new TextRun({ text: texto, bold: true, size: 24, color: ROXO })],
  });

function lista(itens, referencia) {
  return itens.map(
    (t) =>
      new Paragraph({
        numbering: { reference: referencia, level: 0 },
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
      left: { style: BorderStyle.SINGLE, size: 24, color: ROXO },
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

function bloco(b, r) {
  switch (b.tipo) {
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
      return [caixa(r.exemplo, b.texto ?? '', ROXO_CLARO)];
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

/**
 * @param {object} livro { idioma, esboco, capitulos: [EsquemaCapitulo], autor, ano }
 * @returns {Promise<Buffer>}
 */
export async function montarDocx(livro) {
  const { idioma, esboco, capitulos, autor } = livro;
  const L = IDIOMAS[idioma].rotulos;
  const R = ROTULOS_CAIXA[idioma];
  const ano = livro.ano ?? new Date().getFullYear();

  const capa = [
    new Paragraph({ spacing: { before: 3200 }, children: [] }),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { after: 240 },
      children: [new TextRun({ text: esboco.titulo_escolhido, bold: true, size: 64, color: ROXO })],
    }),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { after: 1200 },
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
    ...lista(
      [
        `${L.capitulo} 1 → ${L.capitulo} ${capitulos.length}: cada um termina com "${L.acao}", tarefas para hoje.`,
        `☐ = checklist para marcar. Imprima ou copie para o celular.`,
        `${L.bonus}: modelos e planos prontos no final.`,
      ],
      'topicos',
    ),
    new Paragraph({ spacing: { before: 200 }, children: [new TextRun({ text: L.aviso, italics: true, size: 18, color: CINZA })] }),
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
      for (const b of s.blocos) corpo.push(...bloco(b, R));
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
  bonus.push(new Paragraph({ spacing: { before: 400 }, children: [new TextRun({ text: L.aviso, italics: true, size: 18, color: CINZA })] }));

  const doc = new Document({
    creator: autor,
    title: esboco.titulo_escolhido,
    description: esboco.promessa,
    styles: {
      default: { document: { run: { font: 'Calibri', size: 22 } } },
      paragraphStyles: [
        { id: 'Heading1', name: 'Heading 1', basedOn: 'Normal', next: 'Normal', quickFormat: true, run: { bold: true, size: 40, color: ROXO, font: 'Calibri' }, paragraph: { spacing: { after: 200 } } },
        { id: 'Heading2', name: 'Heading 2', basedOn: 'Normal', next: 'Normal', quickFormat: true, run: { bold: true, size: 28, font: 'Calibri' }, paragraph: { spacing: { before: 320, after: 120 } } },
        { id: 'Heading3', name: 'Heading 3', basedOn: 'Normal', next: 'Normal', quickFormat: true, run: { bold: true, size: 24, color: ROXO, font: 'Calibri' } },
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
