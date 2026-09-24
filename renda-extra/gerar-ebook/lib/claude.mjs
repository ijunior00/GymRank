// A conversa com a API do Claude, em três formas:
//   - pesquisa: texto livre com busca na web (o modelo pesquisa sozinho);
//   - estruturado: JSON validado por um esquema (esboço, capítulos, vendas);
// Tudo com "fallbacks": se o modelo principal recusar algo por política, a
// própria API refaz o pedido num modelo alternativo. Se a conta ainda não
// tiver esse recurso, o código tenta de novo sem ele.
import Anthropic from '@anthropic-ai/sdk';
import { zodOutputFormat } from '@anthropic-ai/sdk/helpers/zod';

const FALLBACK_BETA = 'server-side-fallback-2026-07-01';

export class ClienteClaude {
  constructor({ modelo, esforco, log }) {
    this.client = new Anthropic(); // lê ANTHROPIC_API_KEY do ambiente
    this.modelo = modelo;
    this.esforco = esforco;
    this.log = log;
    this.uso = { entrada: 0, saida: 0, cacheLido: 0, cacheEscrito: 0, buscas: 0 };
    this.fallbacksDisponiveis = true;
  }

  _contabiliza(msg) {
    const u = msg.usage ?? {};
    this.uso.entrada += u.input_tokens ?? 0;
    this.uso.saida += u.output_tokens ?? 0;
    this.uso.cacheLido += u.cache_read_input_tokens ?? 0;
    this.uso.cacheEscrito += u.cache_creation_input_tokens ?? 0;
    this.uso.buscas += u.server_tool_use?.web_search_requests ?? 0;
  }

  _base(extra = {}) {
    const params = { model: this.modelo, max_tokens: 16000, ...extra };
    if (this.esforco) {
      params.output_config = { ...(params.output_config ?? {}), effort: this.esforco };
    }
    return params;
  }

  /** Tenta com fallbacks; se a API recusar o parâmetro, repete sem ele. */
  async _comFallbacks(comBeta, semBeta) {
    if (this.fallbacksDisponiveis) {
      try {
        return await comBeta();
      } catch (error) {
        if (error instanceof Anthropic.BadRequestError) {
          this.log(`  (fallbacks indisponíveis nesta conta: ${error.message.slice(0, 80)}… seguindo sem)`);
          this.fallbacksDisponiveis = false;
        } else {
          throw error;
        }
      }
    }
    return semBeta();
  }

  _checaParada(msg, etapa) {
    if (msg.stop_reason === 'refusal') {
      throw new Error(`O modelo recusou a etapa "${etapa}" (${msg.stop_details?.category ?? 'sem categoria'}). Tente reformular o tema.`);
    }
    if (msg.stop_reason === 'max_tokens') {
      this.log(`  aviso: a etapa "${etapa}" bateu no limite de tamanho; o texto pode ter sido cortado.`);
    }
  }

  /**
   * Texto livre com busca na web. O servidor pode pausar um turno longo
   * (`pause_turn`); aí devolvemos a resposta parcial e ele continua.
   */
  async pesquisar({ sistema, pergunta, maxBuscas = 8 }) {
    const messages = [{ role: 'user', content: pergunta }];
    const tools = [{ type: 'web_search_20260209', name: 'web_search', max_uses: maxBuscas }];
    let texto = '';
    for (let rodada = 0; rodada < 6; rodada++) {
      const params = this._base({ system: sistema, messages, tools });
      const msg = await this._comFallbacks(
        () => this.client.beta.messages.create({ ...params, betas: [FALLBACK_BETA], fallbacks: 'default' }),
        () => this.client.messages.create(params),
      );
      this._contabiliza(msg);
      this._checaParada(msg, 'pesquisa');
      texto = msg.content.filter((b) => b.type === 'text').map((b) => b.text).join('\n');
      if (msg.stop_reason !== 'pause_turn') break;
      messages.push({ role: 'assistant', content: msg.content });
    }
    return texto.trim();
  }

  /** JSON validado por um esquema zod. O `sistema` grande é cacheado. */
  async estruturado({ sistema, pergunta, esquema, etapa }) {
    const params = this._base({
      system: [{ type: 'text', text: sistema, cache_control: { type: 'ephemeral' } }],
      messages: [{ role: 'user', content: pergunta }],
      output_config: { format: zodOutputFormat(esquema) },
    });
    const msg = await this._comFallbacks(
      () => this.client.beta.messages.parse({ ...params, betas: [FALLBACK_BETA], fallbacks: 'default' }),
      () => this.client.messages.parse(params),
    );
    this._contabiliza(msg);
    this._checaParada(msg, etapa);
    if (!msg.parsed_output) {
      throw new Error(`A etapa "${etapa}" não devolveu um resultado válido. Rode de novo; se repetir, simplifique o tema.`);
    }
    return msg.parsed_output;
  }

  /** Estimativa de custo em dólares para o modelo padrão (Opus 5). */
  custoEstimadoUsd() {
    const precos = this.modelo.includes('sonnet')
      ? { entrada: 2, saida: 10, cache: 0.2 }
      : this.modelo.includes('haiku')
        ? { entrada: 1, saida: 5, cache: 0.1 }
        : { entrada: 5, saida: 25, cache: 0.5 };
    const tokens =
      (this.uso.entrada * precos.entrada +
        this.uso.saida * precos.saida +
        this.uso.cacheLido * precos.cache +
        this.uso.cacheEscrito * precos.entrada * 1.25) /
      1_000_000;
    const buscas = (this.uso.buscas * 10) / 1000;
    return tokens + buscas;
  }
}

/** Erro legível para quem não programa. */
export function explicaErro(error) {
  if (error instanceof Anthropic.AuthenticationError) {
    return 'A chave da API não foi aceita. Confira o arquivo .env (ANTHROPIC_API_KEY=...) e se a chave está ativa em console.anthropic.com.';
  }
  if (error instanceof Anthropic.RateLimitError) {
    return 'Muitos pedidos seguidos. Espere um minuto e rode de novo.';
  }
  if (error instanceof Anthropic.APIError) {
    if (`${error.message}`.toLowerCase().includes('credit balance')) {
      return 'A conta da Anthropic está sem crédito. Recarregue em console.anthropic.com → Billing.';
    }
    return `A API respondeu com erro ${error.status}: ${error.message}`;
  }
  if (error instanceof Error && /ANTHROPIC_API_KEY/.test(error.message)) {
    return 'Falta a chave da API. Copie .env.exemplo para .env e cole a sua chave nele.';
  }
  return error instanceof Error ? error.message : String(error);
}
