#!/usr/bin/env python3
"""Encaixa as fotos do modelo no padrão do livro e desenha as setas.

    python3 montar_fotos.py              # grava imagens/<nome>.jpg
    python3 montar_fotos.py --teste DIR  # grava em DIR, sem mexer no livro

De onde vêm as fotos: a folha que o dono mandou (fotos/folha-modelo.jpg)
foi recortada em 12 e ampliada 4x com o modelo de super-resolução EDSR
(fotos_da_folha.py); os recortes ficam em fotos/recortes/. A foto do
Kegel deitado é a da respiração com as setas apagadas
(fotos/02-kegel-deitado.jpg).

Cada imagem final tem 1400 x 1000, cartão de cantos arredondados no fundo
claro do livro, e sai em JPEG (as fotos em PNG deixariam o Word pesado).
A capa e o gráfico do para-e-continua continuam vindo de desenhar.py.

As setas ficam em SETAS, em frações da FOTO (0,0 = canto de cima à
esquerda; 1,1 = canto de baixo à direita), e são convertidas para a
posição no cartão.
"""
import base64
import io
import sys
from pathlib import Path

import resvg_py
from PIL import Image

from desenhar import CARD, CORAL, SOFT, seta, seta_curva

AQUI = Path(__file__).parent
FOTOS = AQUI / "fotos"
W, H = 1400, 1000
CX, CY, CW, CH = 20, 20, W - 40, H - 40  # área interna do cartão

# imagem do livro → foto de origem (dentro de fotos/, sem extensão)
FONTE = {
    "01-anatomia": "recortes/folha-anatomia",
    "02-kegel-deitado": "02-kegel-deitado",
    "03-kegel-sentado": "recortes/folha-sentado",
    "04-contracoes-rapidas": "recortes/folha-em-pe",
    "05-kegel-reverso": "recortes/folha-quatro-apoios",
    "06-respiracao": "recortes/folha-deitado-respiracao",
    "07-agachamento": "recortes/folha-agachamento",
    "08-borboleta": "recortes/folha-borboleta",
    "09-flexor-quadril": "recortes/folha-flexor",
    "10-prancha": "recortes/folha-prancha",
}

# Setas que faltam. As outras fotos já vieram com as setas desenhadas.
# ("reta", x1, y1, x2, y2, cor, espessura) ou
# ("curva", x0, y0, cx, cy, x1, y1, cor, espessura)
SETAS = {
    "02-kegel-deitado": [("reta", 0.637, 0.790, 0.637, 0.700, "coral", 18)],
    "05-kegel-reverso": [("reta", 0.330, 0.500, 0.330, 0.635, "coral", 16)],
}

CORES = {"coral": CORAL, "cinza": SOFT}


def achar(rel):
    for ext in (".jpg", ".jpeg", ".png"):
        p = FOTOS / f"{rel}{ext}"
        if p.exists():
            return p
    return None


def geometria(w, h):
    """Escala e deslocamento da foto ao preencher o cartão (como 'slice')."""
    s = max(CW / w, CH / h)
    return s, CX + (CW - w * s) / 2, CY + (CH - h * s) / 2


def svg_da_foto(foto: Path, setas):
    with Image.open(foto) as im:
        w, h = im.size
    s, ox, oy = geometria(w, h)
    P = lambda fx, fy: (ox + fx * w * s, oy + fy * h * s)  # noqa: E731
    mime = "image/png" if foto.suffix == ".png" else "image/jpeg"
    dados = base64.b64encode(foto.read_bytes()).decode()
    partes = []
    for a in setas:
        if a[0] == "reta":
            _, x1, y1, x2, y2, cor, esp = a
            (ax, ay), (bx, by) = P(x1, y1), P(x2, y2)
            partes.append(seta(ax, ay, bx, by, CORES[cor], esp))
        else:
            _, x0, y0, cx, cy, x1, y1, cor, esp = a
            partes.append(seta_curva(P(x0, y0), P(cx, cy), P(x1, y1), CORES[cor], esp))
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
        f'width="{W}" height="{H}" viewBox="0 0 {W} {H}">'
        f'<defs><clipPath id="c"><rect x="{CX}" y="{CY}" width="{CW}" height="{CH}" rx="48"/></clipPath></defs>'
        f'<rect width="{W}" height="{H}" fill="#FFFFFF"/>'
        f'<rect x="{CX}" y="{CY}" width="{CW}" height="{CH}" rx="48" fill="{CARD}"/>'
        f'<image x="{CX}" y="{CY}" width="{CW}" height="{CH}" preserveAspectRatio="xMidYMid slice" '
        f'clip-path="url(#c)" xlink:href="data:{mime};base64,{dados}"/>'
        + "".join(partes)
        + "</svg>"
    )


def main():
    saida = AQUI
    if "--teste" in sys.argv:
        saida = Path(sys.argv[sys.argv.index("--teste") + 1])
        saida.mkdir(parents=True, exist_ok=True)
    for nome, rel in FONTE.items():
        foto = achar(rel)
        if not foto:
            print(f"{nome}: falta a foto fotos/{rel}.jpg; fica o desenho")
            continue
        png = bytes(resvg_py.svg_to_bytes(svg_string=svg_da_foto(foto, SETAS.get(nome, [])), width=W))
        destino = saida / f"{nome}.jpg"
        Image.open(io.BytesIO(png)).convert("RGB").save(destino, quality=88, optimize=True, progressive=True)
        print(f"{destino.name}  {destino.stat().st_size // 1024} KB")


if __name__ == "__main__":
    main()
