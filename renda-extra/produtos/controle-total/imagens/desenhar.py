#!/usr/bin/env python3
"""Desenha as 12 ilustrações do "Controle em 12 Semanas" em SVG e as
rasteriza em PNG (1400 px de largura). Sem texto dentro das imagens, para
servirem às edições em português e espanhol.

    python3 desenhar.py          # gera svg/*.svg e *.png nesta pasta

Estilo: cartão claro, figura masculina em silhueta de traço grosso (azul
marinho), setas coral para contração/respiração. Só depende de resvg_py.
"""
import math
from pathlib import Path

import resvg_py

AQUI = Path(__file__).parent
W, H = 1400, 1000
NAVY = "#1F3A5F"
CORAL = "#E8735A"
CARD = "#F4F7FB"
GROUND = "#C9D3E0"
SOFT = "#8FA3BF"
DARK2 = "#3A5A85"
BAND = "#EAF0F7"


# ---------- primitivas ----------
def svg(children, w=W, h=H, fundo=None):
    corpo = "".join(children)
    fundo_svg = f'<rect width="{w}" height="{h}" fill="{fundo}"/>' if fundo else ""
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">'
        f"{fundo_svg}{corpo}</svg>"
    )


def cartao(w=W, h=H):
    return f'<rect x="20" y="20" width="{w - 40}" height="{h - 40}" rx="48" fill="{CARD}"/>'


def chao(y, x1=140, x2=W - 140):
    return f'<line x1="{x1}" y1="{y}" x2="{x2}" y2="{y}" stroke="{GROUND}" stroke-width="10" stroke-linecap="round"/>'


def linha(pts, cor=NAVY, w=44):
    d = " ".join(f"{x},{y}" for x, y in pts)
    return (
        f'<polyline points="{d}" fill="none" stroke="{cor}" stroke-width="{w}" '
        f'stroke-linecap="round" stroke-linejoin="round"/>'
    )


def cabeca(x, y, r=52, cor=NAVY):
    return f'<circle cx="{x}" cy="{y}" r="{r}" fill="{cor}"/>'


def ponta(x2, y2, ux, uy, w, cor):
    """Triângulo da ponta da seta, apontando na direção (ux, uy)."""
    hl, hw = w * 2.4, w * 1.6
    bx, by = x2 - ux * hl, y2 - uy * hl
    px, py = -uy, ux
    return f'<polygon points="{x2},{y2} {bx + px * hw},{by + py * hw} {bx - px * hw},{by - py * hw}" fill="{cor}"/>'


def seta(x1, y1, x2, y2, cor=CORAL, w=22):
    dx, dy = x2 - x1, y2 - y1
    L = math.hypot(dx, dy)
    ux, uy = dx / L, dy / L
    hl = w * 2.4
    ex, ey = x2 - ux * hl * 0.8, y2 - uy * hl * 0.8
    return (
        f'<line x1="{x1}" y1="{y1}" x2="{ex}" y2="{ey}" stroke="{cor}" stroke-width="{w}" stroke-linecap="round"/>'
        + ponta(x2, y2, ux, uy, w, cor)
    )


def seta_curva(p0, c, p1, cor=CORAL, w=20):
    """Seta em curva quadrática de p0 a p1 com controle c."""
    ux, uy = p1[0] - c[0], p1[1] - c[1]
    L = math.hypot(ux, uy)
    ux, uy = ux / L, uy / L
    hl = w * 2.4
    fim = (p1[0] - ux * hl * 0.8, p1[1] - uy * hl * 0.8)
    return (
        f'<path d="M{p0[0]},{p0[1]} Q{c[0]},{c[1]} {fim[0]},{fim[1]}" fill="none" stroke="{cor}" '
        f'stroke-width="{w}" stroke-linecap="round"/>' + ponta(p1[0], p1[1], ux, uy, w, cor)
    )


def suave(pts, cor=NAVY, w=26):
    """Curva suave (Catmull-Rom → Bézier) pelos pontos."""
    if len(pts) < 3:
        return linha(pts, cor, w)
    d = f"M{pts[0][0]},{pts[0][1]}"
    for i in range(len(pts) - 1):
        p0 = pts[i - 1] if i > 0 else pts[i]
        p1, p2 = pts[i], pts[i + 1]
        p3 = pts[i + 2] if i + 2 < len(pts) else p2
        c1 = (p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6)
        c2 = (p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6)
        d += f" C{c1[0]},{c1[1]} {c2[0]},{c2[1]} {p2[0]},{p2[1]}"
    return f'<path d="{d}" fill="none" stroke="{cor}" stroke-width="{w}" stroke-linecap="round" stroke-linejoin="round"/>'


# ---------- figuras reutilizáveis ----------
def deitado(braco_na_barriga=False):
    """Homem deitado de costas, joelhos dobrados, pés no chão (vista lateral, cabeça à esquerda)."""
    y = 740  # linha do tronco
    partes = [
        chao(778),
        cabeca(330, 726),
        linha([(400, y), (690, y)]),  # tronco
        linha([(690, y), (800, 560), (905, 770)]),  # coxa e perna
        linha([(905, 770), (960, 770)], w=40),  # pé
    ]
    if braco_na_barriga:
        partes.append(linha([(430, y), (500, 690), (580, 700)], w=38))  # braço dobrado, mão na barriga
        partes.append(f'<path d="M470,{y - 22} Q560,660 650,{y - 22}" fill="none" stroke="{NAVY}" stroke-width="18" stroke-linecap="round"/>')  # barriga
    else:
        partes.append(linha([(430, y), (560, 764), (650, 764)], w=38))  # braço ao lado do corpo
    return partes


def img_02_kegel_deitado():
    return svg([cartao(), *deitado(), seta(690, 690, 690, 600)])


def img_05_kegel_reverso():
    return svg([cartao(), *deitado(), seta(690, 590, 690, 690, w=18)])


def img_06_respiracao():
    return svg(
        [
            cartao(),
            *deitado(braco_na_barriga=True),
            seta_curva((520, 640), (500, 560), (540, 500), CORAL, 20),  # inspira: sobe
            seta_curva((640, 500), (680, 560), (660, 640), SOFT, 20),  # expira: desce
        ]
    )


def img_03_kegel_sentado():
    return svg(
        [
            cartao(),
            chao(780),
            # cadeira
            linha([(520, 300), (520, 565)], SOFT, 28),
            linha([(505, 565), (775, 565)], SOFT, 28),
            linha([(545, 565), (545, 780)], SOFT, 28),
            linha([(745, 565), (745, 780)], SOFT, 28),
            # figura
            cabeca(596, 240),
            linha([(600, 300), (610, 548)]),  # tronco ereto
            linha([(610, 548), (775, 548), (782, 770)]),  # coxa e perna
            linha([(782, 770), (840, 770)], w=40),  # pé
            linha([(602, 320), (650, 450), (720, 540)], w=38),  # braço, mão na coxa
            seta(612, 700, 612, 605),
        ]
    )


def img_04_contracoes_rapidas():
    return svg(
        [
            cartao(),
            chao(780),
            cabeca(700, 212),
            linha([(700, 270), (700, 540)]),
            linha([(700, 292), (612, 490)], w=40),
            linha([(700, 292), (788, 490)], w=40),
            linha([(700, 540), (648, 775)]),
            linha([(700, 540), (752, 775)]),
            seta(870, 650, 870, 570, w=18),
            seta(925, 650, 925, 570, w=18),
            seta(980, 650, 980, 570, w=18),
        ]
    )


def img_07_agachamento():
    return svg(
        [
            cartao(),
            chao(780),
            cabeca(612, 262),
            linha([(590, 320), (530, 600)]),  # tronco
            linha([(530, 600), (735, 540), (600, 760)]),  # coxa e perna
            linha([(560, 770), (700, 770)], w=40),  # pé inteiro no chão
            linha([(592, 340), (840, 340)], w=38),  # braços à frente
            seta(500, 730, 500, 650, w=18),
        ]
    )


def img_08_borboleta():
    return svg(
        [
            cartao(),
            chao(790),
            cabeca(700, 300),
            linha([(700, 360), (700, 690)]),  # tronco
            linha([(688, 690), (500, 640), (690, 772)]),  # perna esquerda
            linha([(712, 690), (900, 640), (710, 772)]),  # perna direita
            linha([(700, 772), (700, 772)], w=44),  # pés juntos
            linha([(655, 390), (560, 590), (640, 760)], w=38),  # braço até o pé
            linha([(745, 390), (840, 590), (760, 760)], w=38),
        ]
    )


def img_09_flexor_quadril():
    return svg(
        [
            cartao(),
            chao(780),
            cabeca(600, 246),
            linha([(600, 306), (600, 560)]),  # tronco ereto
            linha([(600, 560), (760, 560), (770, 770)]),  # perna da frente
            linha([(770, 770), (830, 770)], w=40),
            linha([(600, 560), (500, 762), (330, 768)]),  # perna de trás, joelho no chão
            linha([(600, 326), (525, 440), (590, 540)], w=38),  # mão no quadril
            seta(660, 470, 780, 470),
        ]
    )


def img_10_prancha():
    return svg(
        [
            cartao(),
            chao(780),
            cabeca(392, 500),
            linha([(460, 522), (730, 610), (1030, 712)]),  # tronco e pernas em linha
            linha([(1030, 712), (1075, 780)]),  # pés apoiados nas pontas
            linha([(460, 522), (475, 770)]),  # braço
            linha([(475, 770), (610, 770)], w=40),  # antebraço no chão
            seta(745, 740, 745, 665, w=18),
            seta(320, 500, 230, 500, SOFT, 18),
        ]
    )


def img_01_anatomia():
    return svg(
        [
            cartao(),
            # coluna lombar pontilhada
            f'<line x1="880" y1="230" x2="880" y2="470" stroke="{SOFT}" stroke-width="16" stroke-linecap="round" stroke-dasharray="4 34"/>',
            # bacia vista de lado (arco aberto para baixo)
            f'<path d="M450,660 C450,330 950,330 950,660" fill="none" stroke="{NAVY}" stroke-width="30" stroke-linecap="round"/>',
            # assoalho pélvico: a rede
            f'<path d="M478,650 Q700,790 922,650" fill="none" stroke="{CORAL}" stroke-width="36" stroke-linecap="round"/>',
            seta(620, 690, 620, 600, w=16),
            seta(700, 700, 700, 610, w=16),
            seta(780, 690, 780, 600, w=16),
        ]
    )


def img_11_para_e_continua():
    pts = [(170, 790), (300, 640), (400, 335), (470, 470), (560, 400), (640, 325), (710, 470), (800, 400), (880, 320), (950, 470), (1050, 360), (1150, 200)]
    return svg(
        [
            cartao(),
            f'<rect x="150" y="300" width="1100" height="130" rx="20" fill="{BAND}"/>',
            f'<line x1="150" y1="260" x2="1250" y2="260" stroke="{CORAL}" stroke-width="10" stroke-linecap="round" stroke-dasharray="26 22"/>',
            f'<line x1="150" y1="800" x2="1250" y2="800" stroke="{SOFT}" stroke-width="10" stroke-linecap="round"/>',
            suave(pts),
            f'<circle cx="400" cy="335" r="20" fill="{CORAL}"/>',
            f'<circle cx="640" cy="325" r="20" fill="{CORAL}"/>',
            f'<circle cx="880" cy="320" r="20" fill="{CORAL}"/>',
        ]
    )


def img_00_capa():
    w, h = 1400, 1050
    return svg(
        [
            f'<path d="M{700 - 470},600 A470,470 0 0 1 {700 + 470},600" fill="none" stroke="{DARK2}" stroke-width="4"/>',
            f'<path d="M{700 - 380},600 A380,380 0 0 1 {700 + 380},600" fill="none" stroke="{DARK2}" stroke-width="6"/>',
            f'<path d="M400,560 Q700,780 1000,560" fill="none" stroke="{CORAL}" stroke-width="40" stroke-linecap="round"/>',
            seta(620, 600, 620, 500, w=18),
            seta(700, 620, 700, 520, w=18),
            seta(780, 600, 780, 500, w=18),
        ],
        w,
        h,
        fundo=NAVY,
    )


IMAGENS = {
    "00-capa": img_00_capa,
    "01-anatomia": img_01_anatomia,
    "02-kegel-deitado": img_02_kegel_deitado,
    "03-kegel-sentado": img_03_kegel_sentado,
    "04-contracoes-rapidas": img_04_contracoes_rapidas,
    "05-kegel-reverso": img_05_kegel_reverso,
    "06-respiracao": img_06_respiracao,
    "07-agachamento": img_07_agachamento,
    "08-borboleta": img_08_borboleta,
    "09-flexor-quadril": img_09_flexor_quadril,
    "10-prancha": img_10_prancha,
    "11-para-e-continua": img_11_para_e_continua,
}


def main():
    (AQUI / "svg").mkdir(exist_ok=True)
    for nome, fn in IMAGENS.items():
        conteudo = fn()
        (AQUI / "svg" / f"{nome}.svg").write_text(conteudo, encoding="utf-8")
        png = bytes(resvg_py.svg_to_bytes(svg_string=conteudo, width=1400))
        (AQUI / f"{nome}.png").write_bytes(png)
        print(f"{nome}.png  {len(png) // 1024} KB")


if __name__ == "__main__":
    main()
