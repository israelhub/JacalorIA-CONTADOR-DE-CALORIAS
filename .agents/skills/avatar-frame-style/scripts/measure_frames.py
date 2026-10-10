"""Mede furo e espessura do anel de todas as molduras para comparacao.

Uso:
    python measure_frames.py [nomes.png ...]   # sem args mede todas

Alvo (padrao cat_ears): hole_frac ~0.72-0.73, anel solido ~8% do canvas.
Requer: pillow, numpy.
"""

import sys
from pathlib import Path

import numpy as np
from PIL import Image

FRAMES_DIR = (
    Path(__file__).resolve().parents[4]
    / "frontend"
    / "assets"
    / "images"
    / "avatar_frames"
)


def measure(path: Path) -> None:
    im = Image.open(path).convert("RGBA")
    alpha = np.asarray(im)[..., 3]
    h, w = alpha.shape
    cy, cx = h // 2, w // 2
    opaque = alpha >= 40
    max_r = min(cx, cy, w - 1 - cx, h - 1 - cy)
    n = 72

    def hits_at(r: int) -> int:
        hits = 0
        for i in range(n):
            ang = 2 * np.pi * i / n
            x = int(round(cx + r * np.cos(ang)))
            y = int(round(cy + r * np.sin(ang)))
            if 0 <= x < w and 0 <= y < h and opaque[y, x]:
                hits += 1
        return hits

    hole_r = max_r // 2
    for r in range(1, max_r):
        if hits_at(r) > n * 0.35:
            hole_r = r
            break
    outer_r = hole_r
    for r in range(hole_r, max_r):
        if hits_at(r) > n * 0.25:
            outer_r = r

    # Espessura da banda solida nas 4 direcoes cardeais
    bands = []
    for dx, dy in [(1, 0), (-1, 0), (0, 1), (0, -1)]:
        start = end = None
        for r in range(0, max_r):
            x = int(round(cx + r * dx))
            y = int(round(cy + r * dy))
            a = int(alpha[y, x]) if 0 <= x < w and 0 <= y < h else 0
            if a > 120 and start is None:
                start = r
            if start is not None and a < 40 and r > start + 3:
                end = r
                break
        if start is not None and end is not None:
            bands.append(end - start)

    band = f"{np.mean(bands) / w:.3f}" if bands else "?"
    print(
        f"{path.name}: canvas={w}x{h} hole_frac={hole_r * 2 / w:.3f} "
        f"anel_solido~{band} do canvas (bandas px: {bands})"
    )


def main() -> None:
    names = sys.argv[1:]
    paths = (
        [FRAMES_DIR / n for n in names]
        if names
        else sorted(FRAMES_DIR.glob("*.png"))
    )
    for p in paths:
        if p.exists():
            measure(p)
        else:
            print(f"{p} nao existe")


if __name__ == "__main__":
    main()
