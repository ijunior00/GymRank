#!/usr/bin/env python3
"""Encaixa as fotos geradas por IA no padrão do livro e desenha as setas.

    python3 montar_fotos.py              # grava em imagens/<nome>.png
    python3 montar_fotos.py --teste DIR  # grava em DIR, sem mexer no livro

Lê imagens/fotos/<nome>.png|jpg|jpeg e escreve imagens/<nome>.png no
mesmo tamanho dos desenhos (1400 x 1000), com o cartão de cantos
arredondados e as setas coral. O que não tiver foto continua com o
desenho de desenhar.py. Depois disso é só rodar o montar.mjs de novo.

As posições das setas ficam em SETAS, em frações da imagem final
(0,0 é o canto de cima à esquerda; 1,1 o de baixo à direita).
"""
import base64
import sys
from pathlib import Path

import resvg_py

from desenhar import CARD, CORAL, H, SOFT, W, seta, seta_curva

AQUI = Path(__file__).parent
FOTOS = AQUI / "fotos"

# Imagens que reaproveitam a foto de outra (mesma pose, seta diferente).
FONTE = {"05-kegel-reverso": "02-kegel-deitado"}

# Setas por imagem: ("reta", x1, y1, x2, y2, cor, espessura) ou
# ("curva", x0, y0, cx, cy, x1, y1, cor, espessura). Ajustadas quando as
# fotos chegam, olhando cada uma.
SETAS = {
    "02-kegel-deitado": [],
    "03-kegel-sentado": [],
    "04-contracoes-rapidas": [],
    "05-kegel-reverso": [],
    "06-respiracao": [],
    "07-agachamento": [],
    "08-borboleta": [],
    "09-flexor-quadril": [],
    "10-prancha": [],
    "01-anatomia": [],
}

CORES = {"coral": CORAL, "cinza": SOFT}


def achar_foto(nome):
    for ext in (".png", ".jpg", ".jpeg"):
        p = FOTOS / f"{nome}{ext}"
        if p.exists():
            return p
    return None


def svg_da_foto(foto: Path, setas):
    mime = "image/png" if foto.suffix == ".png" else "image/jpeg"
    dados = base64.b64encode(foto.read_bytes()).decode()
    partes = []
    for s in setas:
        if s[0] == "reta":
            _, x1, y1, x2, y2, cor, w = s
            partes.append(seta(x1 * W, y1 * H, x2 * W, y2 * H, CORES[cor], w))
        else:
            _, x0, y0, cx, cy, x1, y1, cor, w = s
            partes.append(seta_curva((x0 * W, y0 * H), (cx * W, cy * H), (x1 * W, y1 * H), CORES[cor], w))
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
        f'width="{W}" height="{H}" viewBox="0 0 {W} {H}">'
        f'<defs><clipPath id="c"><rect x="20" y="20" width="{W - 40}" height="{H - 40}" rx="48"/></clipPath></defs>'
        f'<rect x="20" y="20" width="{W - 40}" height="{H - 40}" rx="48" fill="{CARD}"/>'
        f'<image x="20" y="20" width="{W - 40}" height="{H - 40}" preserveAspectRatio="xMidYMid slice" '
        f'clip-path="url(#c)" xlink:href="data:{mime};base64,{dados}"/>'
        + "".join(partes)
        + "</svg>"
    )


def main():
    saida = AQUI
    if "--teste" in sys.argv:
        saida = Path(sys.argv[sys.argv.index("--teste") + 1])
        saida.mkdir(parents=True, exist_ok=True)
    feitas, faltam = [], []
    for nome, setas in SETAS.items():
        foto = achar_foto(FONTE.get(nome, nome))
        if not foto:
            faltam.append(nome)
            continue
        png = bytes(resvg_py.svg_to_bytes(svg_string=svg_da_foto(foto, setas), width=W))
        (saida / f"{nome}.png").write_bytes(png)
        feitas.append(f"{nome}.png ({len(png) // 1024} KB)")
    print("com foto:", ", ".join(feitas) or "nenhuma")
    print("ainda com desenho:", ", ".join(faltam) or "nenhuma")


if __name__ == "__main__":
    main()
