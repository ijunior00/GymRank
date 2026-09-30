#!/usr/bin/env python3
"""Confere os capítulos de uma edição contra o guia de estilo.

    python3 verificar.py pt-BR      (ou es-MX)

Checa: JSON válido, tipos de bloco, palavras proibidas, exclamações,
tamanho, imagens citadas x arquivos existentes, e se as doses da tabela
única aparecem sem contradição óbvia.
"""
import json
import re
import sys
from pathlib import Path

AQUI = Path(__file__).parent
TIPOS = {"paragrafo", "topicos", "passos", "checklist", "dica", "exemplo", "atencao", "citacao", "imagem"}

PROIBIDAS = {
    "pt-BR": [r"\bcura\b", r"\bcurar\b", r"\bcurad[oa]s?\b", r"\bgarantid[oa]s?\b", r"nunca mais", r"para sempre",
              r"em poucos dias", r"30 minutos", r"\bmilagre", r"\bsegredo", r"\btruque", r"sofre de", r"problema seu"],
    "es-MX": [r"\bcura\b", r"\bcurar\b", r"\bcurad[oa]s?\b", r"\bgarantizad[oa]s?\b", r"nunca más", r"para siempre",
              r"en pocos días", r"30 minutos", r"\bmilagro", r"\bsecreto", r"\btruco", r"sufre de", r"problema tuyo"],
}
# Exceções: onde a palavra aparece para dizer que NÃO prometemos isso.
EXCECOES = [r"não (é|promete|existe|garante|é uma) (cura|garantid)", r"nada de (cura|garant)", r"no (es|promete|existe|garantiza) (una )?(cura|garant)",
            r"(sem|sin) (promessa|promesa) de cura", r"\"cura\"", r"'cura'", r"«cura»", r"cura[^.]{0,40}(não|no) (existe|é o objetivo)"]

# Contagem sobre o JSON inteiro (inclui chaves e sintaxe): ~15% acima do texto real.
MIN_PALAVRAS, MAX_PALAVRAS = 1300, 2600


def textos(cap):
    yield "titulo", cap.get("titulo", "")
    yield "abertura", cap.get("abertura", "")
    for s in cap.get("secoes", []):
        yield "secao", s.get("titulo", "")
        for b in s.get("blocos", []):
            if b.get("texto"):
                yield b.get("tipo", "?"), b["texto"]
            for it in b.get("itens") or []:
                yield b.get("tipo", "?"), it
    for r in cap.get("resumo", []):
        yield "resumo", r
    for a in cap.get("acao_agora", []):
        yield "acao", a


def main(idioma):
    pasta = AQUI / idioma
    arquivos = sorted((pasta / "capitulos").glob("cap-*.json")) if (pasta / "capitulos").exists() else []
    if not arquivos and (pasta / "capitulos.json").exists():
        arquivos = [pasta / "capitulos.json"]
    if not arquivos:
        print(f"nenhum capítulo em {pasta}")
        return 1
    imagens_dir = AQUI / "imagens"
    existentes = {p.name for p in imagens_dir.glob("*.png")} | {p.name for p in imagens_dir.glob("*.jpg")}
    problemas = 0
    total_palavras = 0
    citadas = set()
    for arq in arquivos:
        try:
            dados = json.loads(arq.read_text(encoding="utf-8"))
        except Exception as e:  # noqa: BLE001
            print(f"[{arq.name}] JSON inválido: {e}")
            problemas += 1
            continue
        caps = dados if isinstance(dados, list) else [dados]
        for cap in caps:
            nome = f"{arq.name} · {cap.get('titulo', '?')[:40]}"
            palavras = len(json.dumps(cap, ensure_ascii=False).split())
            total_palavras += palavras
            if not (MIN_PALAVRAS <= palavras <= MAX_PALAVRAS):
                print(f"[{nome}] {palavras} palavras (esperado {MIN_PALAVRAS}–{MAX_PALAVRAS})")
                problemas += 1
            for chave in ("titulo", "abertura", "secoes", "resumo", "acao_agora"):
                if chave not in cap:
                    print(f"[{nome}] falta a chave '{chave}'")
                    problemas += 1
            for s in cap.get("secoes", []):
                for b in s.get("blocos", []):
                    t = b.get("tipo")
                    if t not in TIPOS:
                        print(f"[{nome}] tipo de bloco desconhecido: {t}")
                        problemas += 1
                    if t in {"topicos", "passos", "checklist"} and not b.get("itens"):
                        print(f"[{nome}] bloco '{t}' sem itens em '{s.get('titulo')}'")
                        problemas += 1
                    if t in {"paragrafo", "dica", "exemplo", "atencao", "citacao"} and not b.get("texto"):
                        print(f"[{nome}] bloco '{t}' sem texto em '{s.get('titulo')}'")
                        problemas += 1
                    if t == "imagem":
                        citadas.add(b.get("arquivo"))
                        if b.get("arquivo") not in existentes:
                            print(f"[{nome}] imagem não encontrada: {b.get('arquivo')}")
                            problemas += 1
            for origem, texto in textos(cap):
                baixo = texto.lower()
                if "!" in texto:
                    print(f"[{nome}] exclamação em {origem}: {texto[:70]}…")
                    problemas += 1
                if re.search(r"\|.*\|", texto):
                    print(f"[{nome}] parece tabela markdown em {origem}: {texto[:60]}…")
                    problemas += 1
                for padrao in PROIBIDAS[idioma]:
                    for m in re.finditer(padrao, baixo):
                        trecho = baixo[max(0, m.start() - 60): m.end() + 40]
                        if any(re.search(e, trecho) for e in EXCECOES):
                            continue
                        print(f"[{nome}] palavra proibida '{m.group(0)}' em {origem}: …{trecho.strip()}…")
                        problemas += 1
    print(f"\n{len(arquivos)} arquivo(s), ~{total_palavras} palavras, {len(citadas)} imagens citadas, {problemas} problema(s).")
    return 1 if problemas else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else "pt-BR"))
