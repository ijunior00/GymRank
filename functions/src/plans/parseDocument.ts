import Anthropic from '@anthropic-ai/sdk';
import { zodOutputFormat } from '@anthropic-ai/sdk/helpers/zod';
import { defineSecret } from 'firebase-functions/params';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import * as mammoth from 'mammoth';
import { storage, Timestamp } from '../admin';
import { KIND_INSTRUCTIONS, PlanKind, schemaForKind } from './planSchemas';

const anthropicApiKey = defineSecret('ANTHROPIC_API_KEY');

const MODEL = 'claude-opus-5';

const SYSTEM_PROMPT = `Eres asistente de una coach de entrenamiento y de su nutrióloga en México.
Recibes documentos (PDF, Word o fotos) con planes de entrenamiento, dietas, metas de macros o evaluaciones físicas escritos para un alumno específico, y los conviertes a datos estructurados para el app.

Reglas:
- Copia fielmente lo que dice el documento. No inventes ejercicios, alimentos, cantidades ni valores que no aparezcan.
- Conserva las unidades tal como vienen (kg, g, ml, tazas, piezas, minutos).
- Escribe todo en español de México.
- Si algo es ilegible, ambiguo o tuviste que interpretarlo, descríbelo en "warnings" y baja "confidence" a "media" o "baja". La coach revisará y corregirá antes de publicar.
- Si el documento no corresponde al tipo indicado, extrae lo que puedas y explícalo en warnings.`;

const DOCX_MIME =
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document';

type ImageMediaType = 'image/jpeg' | 'image/png' | 'image/gif' | 'image/webp';

const IMAGE_TYPES: ReadonlySet<string> = new Set<ImageMediaType>([
  'image/jpeg',
  'image/png',
  'image/gif',
  'image/webp',
]);

/**
 * Transforma um documento enviado pela treinadora/nutrióloga
 * (`documents/{docId}` com status `subido`) em um plano estruturado:
 * baixa o arquivo do Storage, manda ao Claude com saída estruturada no
 * esquema do tipo de plano e grava o resultado em `parsedPlan`. A
 * treinadora revisa e publica no app; nada chega ao aluno sem isso.
 *
 * Dispara em qualquer escrita para permitir "reintentar" (voltar o
 * status para `subido`), mas só processa a transição para esse status.
 */
export const parseDocument = onDocumentWritten(
  {
    document: 'documents/{docId}',
    secrets: [anthropicApiKey],
    timeoutSeconds: 540,
    memory: '1GiB',
  },
  async (event) => {
    const after = event.data?.after;
    if (!after?.exists) return;
    const data = after.data()!;
    const before = event.data?.before?.data();
    if (data.status !== 'subido' || before?.status === 'subido') return;

    const ref = after.ref;
    await ref.update({ status: 'procesando', errorMessage: null, updatedAt: Timestamp.now() });

    try {
      const [buffer] = await storage.bucket().file(data.storagePath as string).download();
      const kind = (data.kind as PlanKind) ?? 'otro';
      const contentType = data.contentType as string;

      const client = new Anthropic({ apiKey: anthropicApiKey.value() });
      const response = await client.messages.parse({
        model: MODEL,
        max_tokens: 16000,
        system: SYSTEM_PROMPT,
        messages: [
          {
            role: 'user',
            content: [
              ...(await buildSourceBlocks(buffer, contentType, data.fileName as string)),
              {
                type: 'text',
                text: `${KIND_INSTRUCTIONS[kind]}\n\nDevuelve el plan estructurado.`,
              },
            ],
          },
        ],
        output_config: { format: zodOutputFormat(schemaForKind(kind)) },
      });

      if (response.stop_reason === 'refusal') {
        throw new Error(
          'El modelo no pudo procesar este documento. Revisa el archivo o captura el plan a mano.',
        );
      }
      const parsed = response.parsed_output;
      if (!parsed) {
        throw new Error('No se obtuvo un plan válido del documento. Intenta de nuevo.');
      }

      await ref.update({
        status: 'listo',
        parsedPlan: parsed,
        parsedAt: Timestamp.now(),
        parserModel: response.model,
        updatedAt: Timestamp.now(),
      });
    } catch (error) {
      console.error('parseDocument failed', event.params.docId, error);
      await ref.update({
        status: 'error',
        errorMessage:
          error instanceof Error ? error.message : 'Error desconocido al procesar el documento.',
        updatedAt: Timestamp.now(),
      });
    }
  },
);

async function buildSourceBlocks(
  buffer: Buffer,
  contentType: string,
  fileName: string,
): Promise<Anthropic.ContentBlockParam[]> {
  if (contentType === 'application/pdf') {
    return [
      {
        type: 'document',
        source: { type: 'base64', media_type: 'application/pdf', data: buffer.toString('base64') },
        title: fileName,
      },
    ];
  }
  if (contentType === DOCX_MIME) {
    const { value } = await mammoth.extractRawText({ buffer });
    return [{ type: 'text', text: `Contenido del documento "${fileName}":\n\n${value}` }];
  }
  if (IMAGE_TYPES.has(contentType)) {
    return [
      {
        type: 'image',
        source: {
          type: 'base64',
          media_type: contentType as ImageMediaType,
          data: buffer.toString('base64'),
        },
      },
    ];
  }
  // Texto simples ou tipo desconhecido: tenta como texto UTF-8.
  return [{ type: 'text', text: `Contenido del documento "${fileName}":\n\n${buffer.toString('utf8')}` }];
}
