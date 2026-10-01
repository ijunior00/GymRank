#!/usr/bin/env python3
"""Recorta a folha de fotos do modelo (fotos/folha-modelo.jpg) em 12 e
amplia cada recorte 4x com o modelo de super-resolução EDSR do OpenCV.

    pip install opencv-contrib-python-headless pillow numpy
    curl -L -o EDSR_x4.pb https://raw.githubusercontent.com/Saafke/EDSR_Tensorflow/master/models/EDSR_x4.pb
    python3 fotos_da_folha.py EDSR_x4.pb

Grava fotos/recortes/folha-*.jpg (leva uns 3 minutos sem placa de vídeo).
A foto do Kegel deitado (fotos/02-kegel-deitado.jpg) é a da respiração com
as duas setas apagadas; foi feita uma vez, à mão, com cv2.inpaint.
"""
import sys
from pathlib import Path

import cv2
import numpy as np
from PIL import Image

AQUI = Path(__file__).parent
COLUNAS = [(29, 348), (367, 686), (706, 1025)]
LINHAS = [(24, 251), (276, 501), (525, 751), (775, 1000)]
NOMES = [
    ["folha-capa", "folha-anatomia", "folha-closeup"],
    ["folha-sentado", "folha-em-pe", "folha-quatro-apoios"],
    ["folha-deitado-respiracao", "folha-agachamento", "folha-borboleta"],
    ["folha-flexor", "folha-prancha", "folha-curva-abdomen"],
]


def main(modelo):
    folha = Image.open(AQUI / "fotos" / "folha-modelo.jpg").convert("RGB")
    saida = AQUI / "fotos" / "recortes"
    saida.mkdir(parents=True, exist_ok=True)
    sr = cv2.dnn_superres.DnnSuperResImpl_create()
    sr.readModel(modelo)
    sr.setModel("edsr", 4)
    for r, (y0, y1) in enumerate(LINHAS):
        for c, (x0, x1) in enumerate(COLUNAS):
            recorte = folha.crop((x0 + 6, y0 + 6, x1 - 6, y1 - 6))
            grande = sr.upsample(cv2.cvtColor(np.asarray(recorte), cv2.COLOR_RGB2BGR))
            Image.fromarray(cv2.cvtColor(grande, cv2.COLOR_BGR2RGB)).save(
                saida / f"{NOMES[r][c]}.jpg", quality=95, subsampling=0
            )
            print(NOMES[r][c])


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "EDSR_x4.pb")
