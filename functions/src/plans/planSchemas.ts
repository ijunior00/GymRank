import { z } from 'zod';

/**
 * Esquemas de saída estruturada do parser de documentos. Espelham as
 * classes de conteúdo em lib/features/plans/domain/entities/plan_content.dart
 * — mudar aqui exige mudar lá.
 *
 * Todos os campos opcionais são `nullable` (não `optional`): o modo estrito
 * de structured outputs exige que toda propriedade esteja presente.
 */
const confidence = z.enum(['alta', 'media', 'baja']);

const base = {
  title: z.string().describe('Título curto do plano, em español'),
  summary: z.string().nullable().describe('Resumo de 1-2 frases, em español'),
  generalNotes: z.string().nullable().describe('Observações gerais do documento'),
  confidence,
  warnings: z
    .array(z.string())
    .describe('Trechos ilegíveis, ambíguos ou que precisaram de interpretação'),
};

export const workoutPlanSchema = z.object({
  ...base,
  weeksDuration: z.number().int().nullable(),
  days: z.array(
    z.object({
      name: z.string().describe('Ej. "Día 1 · Pierna"'),
      focus: z.string().nullable(),
      exercises: z.array(
        z.object({
          name: z.string(),
          sets: z.number().int().nullable(),
          reps: z.string().nullable().describe('Ej. "10-12", "AMRAP", "30 seg"'),
          load: z.string().nullable().describe('Ej. "40 kg", "RPE 8", "peso corporal"'),
          restSeconds: z.number().int().nullable(),
          technique: z.string().nullable().describe('Drop set, rest-pause, superserie…'),
          notes: z.string().nullable(),
        }),
      ),
      notes: z.string().nullable(),
    }),
  ),
});

export const dietPlanSchema = z.object({
  ...base,
  meals: z.array(
    z.object({
      name: z.string().describe('Ej. "Desayuno", "Colación 1"'),
      time: z.string().nullable().describe('Ej. "7:30"'),
      items: z.array(
        z.object({
          food: z.string(),
          quantity: z.string().nullable().describe('Ej. "120 g", "1 taza", "2 piezas"'),
          notes: z.string().nullable(),
        }),
      ),
      notes: z.string().nullable(),
    }),
  ),
  substitutions: z.array(z.string()).describe('Equivalencias/intercambios permitidos'),
});

export const macrosPlanSchema = z.object({
  ...base,
  targets: z.array(
    z.object({
      label: z.string().describe('Ej. "Día de entrenamiento", "Día de descanso"'),
      kcal: z.number().nullable(),
      proteinG: z.number().nullable(),
      carbsG: z.number().nullable(),
      fatG: z.number().nullable(),
      fiberG: z.number().nullable(),
      waterMl: z.number().nullable(),
    }),
  ),
});

export const evaluationSchema = z.object({
  ...base,
  recordedAt: z.string().nullable().describe('Fecha de la evaluación, si aparece'),
  metrics: z.array(
    z.object({
      label: z.string().describe('Ej. "Peso", "% grasa", "Cintura"'),
      value: z.string(),
      unit: z.string().nullable(),
    }),
  ),
});

export const genericSchema = z.object({
  ...base,
  sections: z.array(
    z.object({
      heading: z.string(),
      content: z.string(),
    }),
  ),
});

export type PlanKind = 'entrenamiento' | 'dieta' | 'macros' | 'evaluacion' | 'otro';

export function schemaForKind(kind: PlanKind): z.ZodTypeAny {
  switch (kind) {
    case 'entrenamiento':
      return workoutPlanSchema;
    case 'dieta':
      return dietPlanSchema;
    case 'macros':
      return macrosPlanSchema;
    case 'evaluacion':
      return evaluationSchema;
    default:
      return genericSchema;
  }
}

export const KIND_INSTRUCTIONS: Record<PlanKind, string> = {
  entrenamiento:
    'El documento es un plan de entrenamiento. Separa por días/sesiones y lista cada ejercicio con series, repeticiones, carga, descanso y técnica tal como aparecen. Si el documento organiza por semanas, usa la primera semana como base y describe la progresión en generalNotes.',
  dieta:
    'El documento es un plan de alimentación elaborado por una nutrióloga. Separa por comidas (desayuno, colaciones, comida, cena) con cada alimento y su cantidad exacta. Copia las listas de equivalencias o intercambios en substitutions. No agregues alimentos que no estén en el documento.',
  macros:
    'El documento define metas de macronutrientes. Extrae kcal, proteína, carbohidratos, grasa, fibra y agua por tipo de día (entrenamiento, descanso, etc.). Si solo hay un objetivo, usa un único target con label "Diario".',
  evaluacion:
    'El documento es una evaluación física (peso, % grasa, perímetros, pliegues, etc.). Extrae cada métrica con su valor y unidad tal como aparece.',
  otro: 'Organiza el documento en secciones con encabezado y contenido, sin resumir de más.',
};
