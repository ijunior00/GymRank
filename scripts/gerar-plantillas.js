// Gera os quatro modelos em Word que a treinadora e a nutrióloga
// preenchem. Os campos espelham functions/src/plans/planSchemas.ts —
// mudar lá exige mudar aqui.
const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  WidthType, ShadingType, AlignmentType, HeadingLevel, BorderStyle,
  PageOrientation, Footer, PageNumber,
} = require('docx');
const fs = require('fs');
const path = require('path');

const OUT = process.argv[2] || '.';

const LETTER = { width: 12240, height: 15840 };
const MARGIN = 1080; // 0,75"
const CONTENT = LETTER.width - MARGIN * 2; // 10080

const PURPLE = '7C3AED';
const PURPLE_SOFT = 'F2EBFC';
const GREY = '6B6B75';
const LINE = 'D8D4E0';

const cellBorders = {
  top: { style: BorderStyle.SINGLE, size: 2, color: LINE },
  bottom: { style: BorderStyle.SINGLE, size: 2, color: LINE },
  left: { style: BorderStyle.SINGLE, size: 2, color: LINE },
  right: { style: BorderStyle.SINGLE, size: 2, color: LINE },
};

function cell(text, width, opts = {}) {
  const { bold = false, fill, color, italics = false, align, size = 19 } = opts;
  return new TableCell({
    width: { size: width, type: WidthType.DXA },
    borders: cellBorders,
    shading: fill ? { type: ShadingType.CLEAR, fill, color: 'auto' } : undefined,
    margins: { top: 60, bottom: 60, left: 90, right: 90 },
    children: [
      new Paragraph({
        alignment: align,
        spacing: { before: 0, after: 0 },
        children: [new TextRun({ text, bold, italics, color, size })],
      }),
    ],
  });
}

/// Tabela com cabeçalho roxo, uma linha de exemplo em cinza itálico e
/// linhas vazias para preencher.
function table(columns, example, emptyRows) {
  const widths = columns.map((c) => c.width);
  const rows = [
    new TableRow({
      tableHeader: true,
      children: columns.map((c) =>
        cell(c.label, c.width, { bold: true, fill: PURPLE_SOFT, color: PURPLE, size: 18 })),
    }),
  ];
  if (example) {
    rows.push(new TableRow({
      children: example.map((t, i) =>
        cell(t, widths[i], { italics: true, color: GREY })),
    }));
  }
  for (let r = 0; r < emptyRows; r++) {
    rows.push(new TableRow({ children: widths.map((w) => cell('', w)) }));
  }
  return new Table({ columnWidths: widths, rows });
}

const gap = (after = 160) => new Paragraph({ spacing: { after }, children: [] });

function h1(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_1,
    spacing: { after: 60 },
    children: [new TextRun({ text, bold: true, size: 34, color: PURPLE })],
  });
}

function h2(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_2,
    spacing: { before: 260, after: 100 },
    children: [new TextRun({ text, bold: true, size: 24 })],
  });
}

function note(text) {
  return new Paragraph({
    spacing: { after: 120 },
    children: [new TextRun({ text, italics: true, color: GREY, size: 18 })],
  });
}

function body(text) {
  return new Paragraph({
    spacing: { after: 100 },
    children: [new TextRun({ text, size: 20 })],
  });
}

/// Linha "Rótulo: ____" que a pessoa preenche.
function field(label, hint) {
  return new Paragraph({
    spacing: { after: 90 },
    children: [
      new TextRun({ text: `${label}: `, bold: true, size: 20 }),
      new TextRun({ text: hint, color: GREY, italics: true, size: 20 }),
    ],
  });
}

/// Espaço livre para escrever (linhas com borda inferior).
function writingLines(n) {
  const out = [];
  for (let i = 0; i < n; i++) {
    out.push(new Paragraph({
      spacing: { after: 200 },
      border: { bottom: { style: BorderStyle.SINGLE, size: 2, color: LINE } },
      children: [],
    }));
  }
  return out;
}

const INTRO =
  'Llena solo lo que aplique; lo que dejes vacío se queda vacío en la app. ' +
  'No borres ni cambies los títulos de las columnas: son la referencia con la ' +
  'que la app lee este documento. Para agregar filas, párate en la última celda ' +
  'y presiona Tab.';

// Só nos formatos que trazem uma linha de exemplo dentro da tabela.
const INTRO_EXAMPLE =
  ' La fila marcada como EJEMPLO es solo una muestra — bórrala antes de enviar.';

function doc(title, children) {
  return new Document({
    styles: {
      default: {
        document: { run: { font: 'Calibri', size: 20 } },
      },
    },
    sections: [{
      properties: {
        page: {
          size: { width: LETTER.width, height: LETTER.height, orientation: PageOrientation.PORTRAIT },
          margin: { top: MARGIN, bottom: MARGIN, left: MARGIN, right: MARGIN },
        },
      },
      footers: {
        default: new Footer({
          children: [new Paragraph({
            alignment: AlignmentType.CENTER,
            children: [new TextRun({
              text: `Método AF · AnahiFitness — ${title}`,
              size: 16, color: GREY,
            })],
          })],
        }),
      },
      children,
    }],
  });
}

function head(title, subtitle, kindLabel, hasExample = false) {
  return [
    h1(title),
    new Paragraph({
      spacing: { after: 160 },
      border: { bottom: { style: BorderStyle.SINGLE, size: 6, color: PURPLE } },
      children: [new TextRun({ text: subtitle, color: GREY, size: 19 })],
    }),
    new Paragraph({
      spacing: { after: 140 },
      children: [
        new TextRun({ text: 'Al subirlo a la app elige: ', size: 19, color: GREY }),
        new TextRun({ text: kindLabel, bold: true, size: 19, color: PURPLE }),
      ],
    }),
    note(hasExample ? INTRO + INTRO_EXAMPLE : INTRO),
    gap(120),
    field('Alumna', '(nombre completo)'),
    field('Fecha', '(dd/mm/aaaa)'),
  ];
}

// ---------------------------------------------------------------- treino
const workoutCols = [
  { label: 'Ejercicio', width: 2500 },
  { label: 'Series', width: 800 },
  { label: 'Reps', width: 1000 },
  { label: 'Carga', width: 1300 },
  { label: 'Descanso', width: 1180 },
  { label: 'Técnica', width: 1500 },
  { label: 'Notas', width: 1800 },
];
const workoutExample = [
  'EJEMPLO · Sentadilla con barra', '4', '10-12', '40 kg', '90 seg',
  'Serie normal', 'Bajar controlado',
];

function workoutDay(n) {
  return [
    h2(`Día ${n}`),
    field('Enfoque', '(ej. Pierna, Empuje, Full body)'),
    table(workoutCols, n === 1 ? workoutExample : null, n === 1 ? 6 : 7),
    gap(80),
    field('Notas del día', '(opcional)'),
  ];
}

const entrenamiento = doc('Plan de entrenamiento', [
  ...head('Plan de entrenamiento', 'Formato para la coach', 'Entrenamiento', true),
  field('Título del plan', '(ej. Fuerza · Bloque 1)'),
  field('Duración', '(ej. 4 semanas)'),
  field('Resumen', '(1 o 2 frases sobre el objetivo del bloque)'),
  note('Hay cuatro días. Borra los que no uses o copia un bloque entero para agregar más.'),
  ...workoutDay(1),
  ...workoutDay(2),
  ...workoutDay(3),
  ...workoutDay(4),
  h2('Notas generales'),
  note('Progresión entre semanas, calentamiento, cardio, avisos de lesiones.'),
  ...writingLines(4),
]);

// ----------------------------------------------------------------- dieta
const dietCols = [
  { label: 'Alimento', width: 4200 },
  { label: 'Cantidad', width: 2200 },
  { label: 'Notas', width: 3680 },
];
const dietExample = [
  'EJEMPLO · Claras de huevo', '4 piezas', 'Revueltas, sin aceite',
];

function meal(name, hint, withExample) {
  return [
    h2(name),
    field('Hora', hint),
    table(dietCols, withExample ? dietExample : null, withExample ? 4 : 5),
    gap(80),
    field('Notas de la comida', '(opcional)'),
  ];
}

const dieta = doc('Plan de alimentación', [
  ...head('Plan de alimentación', 'Formato para la nutrióloga', 'Dieta', true),
  field('Título del plan', '(ej. Plan de definición · Marzo)'),
  field('Resumen', '(1 o 2 frases sobre el objetivo)'),
  ...meal('Desayuno', '(ej. 7:30)', true),
  ...meal('Colación 1', '(ej. 11:00)', false),
  ...meal('Comida', '(ej. 14:30)', false),
  ...meal('Colación 2', '(ej. 17:30)', false),
  ...meal('Cena', '(ej. 20:00)', false),
  h2('Equivalencias e intercambios'),
  note('Una por línea. Ej.: "100 g de pollo = 100 g de pescado blanco = 120 g de atún en agua".'),
  ...writingLines(6),
  h2('Notas generales'),
  note('Hidratación, suplementos, comida libre, alergias e intolerancias.'),
  ...writingLines(4),
]);

// ---------------------------------------------------------------- macros
const macroCols = [
  { label: 'Tipo de día', width: 2400 },
  { label: 'kcal', width: 1080 },
  { label: 'Proteína (g)', width: 1400 },
  { label: 'Carbohidratos (g)', width: 1800 },
  { label: 'Grasa (g)', width: 1200 },
  { label: 'Fibra (g)', width: 1100 },
  { label: 'Agua (ml)', width: 1100 },
];

const macros = doc('Metas de macros', [
  ...head('Metas de macronutrientes', 'Formato para la nutrióloga', 'Macros'),
  field('Título del plan', '(ej. Macros · Etapa de definición)'),
  field('Resumen', '(1 o 2 frases)'),
  h2('Metas por tipo de día'),
  note('Ejemplo de una fila: Día de entrenamiento · 1900 kcal · 140 g de proteína · 180 g de carbohidratos · 55 g de grasa · 30 g de fibra · 2500 ml de agua.'),
  note('Si la meta es la misma todos los días, llena solo la primera fila y escribe "Diario" en el tipo de día.'),
  new Table({
    columnWidths: macroCols.map((c) => c.width),
    rows: [
      new TableRow({
        tableHeader: true,
        children: macroCols.map((c) =>
          cell(c.label, c.width, { bold: true, fill: PURPLE_SOFT, color: PURPLE, size: 18 })),
      }),
      ...['Día de entrenamiento', 'Día de descanso', '', ''].map((label) =>
        new TableRow({
          children: macroCols.map((c, i) => cell(i === 0 ? label : '', c.width)),
        })),
    ],
  }),
  h2('Notas generales'),
  note('Cómo repartir los macros en el día, qué hacer si entrena en ayunas, suplementos.'),
  ...writingLines(4),
]);

// ------------------------------------------------------------ evaluación
const evalCols = [
  { label: 'Medida', width: 4000 },
  { label: 'Valor', width: 2400 },
  { label: 'Unidad', width: 3680 },
];

function evalRow(label) {
  return new TableRow({
    children: [
      cell(label, 4000),
      cell('', 2400),
      cell('', 3680),
    ],
  });
}

const evalTable = new Table({
  columnWidths: [4000, 2400, 3680],
  rows: [
    new TableRow({
      tableHeader: true,
      children: evalCols.map((c) =>
        cell(c.label, c.width, { bold: true, fill: PURPLE_SOFT, color: PURPLE, size: 18 })),
    }),
    ...['Peso', '% de grasa', 'Masa muscular', 'Cintura', 'Cadera', 'Brazo', 'Muslo',
      'Pecho', 'Cuello'].map(evalRow),
    ...[0, 1, 2].map(() => evalRow('')),
  ],
});

const evaluacion = doc('Evaluación física', [
  ...head('Evaluación física', 'Formato para la coach o la nutrióloga', 'Evaluación'),
  field('Título', '(ej. Evaluación inicial)'),
  field('Fecha de la evaluación', '(dd/mm/aaaa)'),
  field('Resumen', '(1 o 2 frases)'),
  h2('Medidas'),
  note('Ejemplo de una fila: Peso · 64.8 · kg.'),
  note('Deja vacía la fila que no midas. Puedes agregar las que quieras con Tab en la última celda.'),
  evalTable,
  h2('Notas generales'),
  note('Condiciones de la medición (en ayunas, hora del día), observaciones.'),
  ...writingLines(4),
]);

const files = {
  'plantilla-entrenamiento.docx': entrenamiento,
  'plantilla-dieta.docx': dieta,
  'plantilla-macros.docx': macros,
  'plantilla-evaluacion.docx': evaluacion,
};

(async () => {
  fs.mkdirSync(OUT, { recursive: true });
  for (const [name, document] of Object.entries(files)) {
    const buffer = await Packer.toBuffer(document);
    fs.writeFileSync(path.join(OUT, name), buffer);
    console.log('ok', name, buffer.length, 'bytes');
  }
})();
