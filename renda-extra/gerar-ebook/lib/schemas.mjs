// Formatos que pedimos ao Claude. Saída estruturada (JSON validado) em vez
// de texto solto: assim o Word sai sempre bem formatado e nada se perde.
import { z } from 'zod';

export const EsquemaEsboco = z.object({
  titulos: z
    .array(
      z.object({
        titulo: z.string(),
        subtitulo: z.string(),
        por_que_converte: z.string(),
      }),
    )
    .describe('5 opções de título, da mais forte para a mais fraca'),
  titulo_escolhido: z.string(),
  subtitulo_escolhido: z.string(),
  promessa: z.string().describe('Uma frase: o resultado concreto que o leitor terá'),
  publico: z.string().describe('Quem é o leitor, em uma frase específica'),
  tom: z.string(),
  capitulos: z.array(
    z.object({
      numero: z.number(),
      titulo: z.string(),
      objetivo: z.string().describe('O que o leitor consegue fazer ao terminar o capítulo'),
      pontos: z.array(z.string()).describe('3 a 6 pontos que o capítulo cobre'),
      entregavel: z.string().describe('Checklist, modelo, planilha ou script que o capítulo entrega'),
    }),
  ),
  bonus: z.array(z.object({ nome: z.string(), descricao: z.string() })),
});

const Bloco = z.object({
  tipo: z.enum(['paragrafo', 'topicos', 'passos', 'checklist', 'dica', 'exemplo', 'atencao', 'citacao']),
  texto: z.string().nullable().describe('Para paragrafo/dica/exemplo/atencao/citacao'),
  itens: z.array(z.string()).nullable().describe('Para topicos/passos/checklist'),
});

export const EsquemaCapitulo = z.object({
  titulo: z.string(),
  abertura: z.string().describe('1 a 3 parágrafos que prendem e dizem o que vem'),
  secoes: z.array(
    z.object({
      titulo: z.string(),
      blocos: z.array(Bloco),
    }),
  ),
  resumo: z.array(z.string()).describe('3 a 5 frases curtas: o que levar deste capítulo'),
  acao_agora: z.array(z.string()).describe('2 a 4 tarefas concretas para fazer hoje, com tempo estimado'),
});

export const EsquemaRevisao = z.object({
  melhorias: z.array(z.string()).describe('O que o editor mudou e por quê'),
  capitulo: EsquemaCapitulo,
});

export const EsquemaVendas = z.object({
  titulo_pagina: z.string(),
  subtitulo_pagina: z.string(),
  descricao_longa: z.string().describe('Texto da página de vendas em markdown, 400 a 700 palavras'),
  bullets: z.array(z.string()).describe('7 benefícios concretos, começando por verbo'),
  para_quem_e: z.array(z.string()),
  para_quem_nao_e: z.array(z.string()),
  bonus: z.array(z.object({ nome: z.string(), descricao: z.string() })),
  garantia: z.string(),
  faq: z.array(z.object({ pergunta: z.string(), resposta: z.string() })),
  precos: z.array(
    z.object({
      mercado: z.string(),
      preco_sugerido: z.string(),
      preco_ancora: z.string(),
      justificativa: z.string(),
    }),
  ),
  emails: z.array(
    z.object({
      dia: z.number(),
      assunto: z.string(),
      corpo: z.string(),
    }),
  ).describe('5 e-mails para quem baixou a isca, do dia 0 ao dia 4'),
  videos_curtos: z.array(
    z.object({ gancho: z.string(), roteiro: z.string(), cta: z.string() }),
  ).describe('10 roteiros de 30 a 45 segundos para TikTok/Reels'),
  capa: z.object({
    conceito: z.string(),
    cores: z.array(z.string()),
    texto_capa: z.string(),
    prompt_canva: z.string().describe('Instruções passo a passo para montar a capa no Canva'),
  }),
  isca_digital: z.object({
    titulo: z.string(),
    conteudo: z.string().describe('Mini-guia gratuito de 1 a 2 páginas em markdown, que leva ao e-book'),
  }),
});
