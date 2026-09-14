import Anthropic from '@anthropic-ai/sdk';
import { zodOutputFormat } from '@anthropic-ai/sdk/helpers/zod';
import { defineSecret } from 'firebase-functions/params';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import * as mammoth from 'mammoth';
import { storage, Timestamp } from '../admin';
import { dispatchNotification } from '../notifications/dispatchNotification';
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
        throw new ReadableError(
          'El modelo no pudo procesar este documento. Revisa el archivo o captura el plan a mano.',
        );
      }
      const parsed = response.parsed_output;
      if (!parsed) {
        throw new ReadableError('No se obtuvo un plan válido del documento. Intenta de nuevo.');
      }

      await ref.update({
        status: 'listo',
        parsedPlan: parsed,
        parsedAt: Timestamp.now(),
        parserModel: response.model,
        updatedAt: Timestamp.now(),
      });

      // "Te avisamos cuando esté listo para revisar" — este é o aviso.
      const warnings = (parsed as { warnings?: unknown[] }).warnings?.length ?? 0;
      await notifyUploader(data, {
        type: 'documentReady',
        title: 'Plan listo para revisar',
        body:
          `${data.fileName} ya está leído.` +
          (warnings > 0 ? ` Tiene ${warnings} aviso(s) para revisar antes de publicar.` : ''),
        deepLink: `/coach/documents/${event.params.docId}/review`,
      });
    } catch (error) {
      console.error('parseDocument failed', event.params.docId, error);
      const message = describeError(error);
      await ref.update({
        status: 'error',
        errorMessage: message,
        updatedAt: Timestamp.now(),
      });
      await notifyUploader(data, {
        type: 'documentFailed',
        title: 'No pudimos leer el archivo',
        body: message,
        deepLink: `/coach/clients/${data.userId as string}`,
      });
    }
  },
);

/**
 * Avisa quem subiu o documento. Um push que falhe não pode mudar o
 * resultado da leitura, por isso o erro fica só no log.
 */
async function notifyUploader(
  data: FirebaseFirestore.DocumentData,
  input: { type: 'documentReady' | 'documentFailed'; title: string; body: string; deepLink: string },
): Promise<void> {
  const uploadedBy = data.uploadedBy as string | undefined;
  if (!uploadedBy) return;
  try {
    await dispatchNotification({ userId: uploadedBy, ...input });
  } catch (error) {
    console.error('parseDocument: falha ao notificar', uploadedBy, error);
  }
}

/**
 * Traduz o erro para algo que a treinadora consiga resolver sozinha. O que
 * ela via antes era o JSON cru da API — inútil para quem não programa.
 *
 * O SDK da Anthropic começa a mensagem pelo status HTTP ("400 {...}"), e
 * o texto do erro traz a causa; os dois entram na decisão.
 */
export function describeError(error: unknown): string {
  if (error instanceof ReadableError) return error.message;
  const raw = error instanceof Error ? error.message : String(error);
  const lower = raw.toLowerCase();
  const status = /^(\d{3})\b/.exec(raw)?.[1];

  if (lower.includes('credit balance')) {
    return (
      'La cuenta de Anthropic no tiene crédito. Recárgala en console.anthropic.com → ' +
      'Billing y toca "Reintentar".'
    );
  }
  if (status === '401' || lower.includes('authentication_error') || lower.includes('invalid x-api-key')) {
    return (
      'La clave de la API de Anthropic no es válida. Hay que guardarla de nuevo ' +
      '(firebase functions:secrets:set ANTHROPIC_API_KEY) y volver a desplegar parseDocument.'
    );
  }
  if (status === '429' || lower.includes('rate_limit')) {
    return 'Demasiadas lecturas seguidas. Espera un par de minutos y toca "Reintentar".';
  }
  if (status === '529' || status === '503' || lower.includes('overloaded')) {
    return 'El servicio de lectura está saturado en este momento. Toca "Reintentar" en unos minutos.';
  }
  if (status === '413' || lower.includes('too large') || lower.includes('request_too_large')) {
    return 'El archivo es demasiado grande para leerlo. Divídelo o comprímelo y súbelo de nuevo.';
  }
  if (lower.includes('could not process') || lower.includes('invalid_request_error')) {
    return (
      'El servicio no pudo procesar este archivo. Prueba guardarlo de nuevo como PDF o Word, ' +
      'o súbelo como foto.'
    );
  }
  return `No se pudo leer el archivo. Detalle técnico: ${raw.slice(0, 200)}${raw.length > 200 ? '…' : ''}`;
}

/** Erro cuja mensagem já foi escrita para a treinadora ler — passa direto. */
export class ReadableError extends Error {}

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
