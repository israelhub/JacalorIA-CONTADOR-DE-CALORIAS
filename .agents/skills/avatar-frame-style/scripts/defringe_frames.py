"""Remove halo/franja de fundo em molduras (alpha suave esbranquicada).

No Safari/iOS esse residual vira mancha de "fundo nao cortado"; no Android
quase nao aparece. Panda/fox ja tem borda dura; soft_pink/blue/gold nao.

Uso:
    python defringe_frames.py [pasta_ou_arquivo.png]
"""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

DEFAULT_DIR = (
    Path(__file__).resolve().parents[4]
    / "frontend"
    / "assets"
    / "images"
    / "avatar_frames"
)


def sanitize_straight_alpha(arr: np.ndarray) -> np.ndarray:
    out = np.array(arr, copy=True, dtype=np.uint8)
    a = out[..., 3].astype(np.float32) / 255.0
    rgb = out[..., :3].astype(np.float32)
    premul = rgb * a[..., None]
    zero = a == 0
    rgb_out = np.zeros_like(rgb)
    nonzero = ~zero
    if nonzero.any():
        rgb_out[nonzero] = np.clip(
            premul[nonzero] / a[nonzero][..., None], 0, 255
        )
    out[..., :3] = rgb_out.astype(np.uint8)
    near = out[..., 3] < 8
    out[near, :3] = 0
    out[near, 3] = 0
    return out


def defringe_frame(arr: np.ndarray) -> np.ndarray:
    """Zera fringe clara/cinza e endurece AA externo/interno."""
    out = np.array(arr, copy=True, dtype=np.uint8)
    a = out[..., 3].astype(np.int16)
    rgb = out[..., :3].astype(np.int16)
    sat = rgb.max(axis=2) - rgb.min(axis=2)
    mean = rgb.mean(axis=2)

    whiteish = (mean >= 185) & (sat <= 45)
    grayish = (sat <= 22) & (mean >= 35) & (mean <= 210)
    soft = (a > 0) & (a < 200)
    leftover = soft & (whiteish | grayish)

    exterior = a < 12
    h, w = a.shape
    edge = np.zeros((h, w), dtype=bool)
    edge[0, :] = edge[-1, :] = True
    edge[:, 0] = edge[:, -1] = True
    seed = edge & exterior
    structure = np.ones((3, 3), dtype=bool)
    grown = seed.copy()
    for _ in range(max(h, w)):
        dil = ndimage.binary_dilation(grown, structure=structure)
        add = dil & exterior & ~grown
        if not add.any():
            break
        grown |= add

    outer_band = (
        ndimage.binary_dilation(grown, structure=structure, iterations=3) & ~grown
    )
    outer_fringe = outer_band & soft

    hole_fringe = np.zeros((h, w), dtype=bool)
    cy, cx = h // 2, w // 2
    if a[cy, cx] < 12:
        labels, _ = ndimage.label(exterior)
        hole_lbl = labels[cy, cx]
        if hole_lbl != 0:
            hole = labels == hole_lbl
            hole_band = (
                ndimage.binary_dilation(hole, structure=structure, iterations=3)
                & ~hole
            )
            hole_fringe = hole_band & soft & (whiteish | grayish | (a < 48))

    kill = leftover | outer_fringe | hole_fringe
    kill |= (a > 0) & (a < 24)

    out[kill, :3] = 0
    out[kill, 3] = 0

    # Endurece AA restante (aproxima do corte duro do panda).
    a2 = out[..., 3]
    soft2 = (a2 > 0) & (a2 < 64)
    out[soft2, 3] = 0
    out[soft2, :3] = 0

    return sanitize_straight_alpha(out)


def process_path(path: Path) -> None:
    im = np.array(Image.open(path).convert("RGBA"))
    before = int(((im[..., 3] >= 1) & (im[..., 3] <= 40)).sum())
    cleaned = defringe_frame(im)
    after = int(((cleaned[..., 3] >= 1) & (cleaned[..., 3] <= 40)).sum())
    Image.fromarray(cleaned, "RGBA").save(path, optimize=True)
    print(f"{path.name}: fringe1-40 {before} -> {after}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "target",
        nargs="?",
        type=Path,
        default=DEFAULT_DIR,
        help="Pasta de molduras ou um PNG",
    )
    args = parser.parse_args()
    target: Path = args.target
    if target.is_file():
        process_path(target)
        return
    for path in sorted(target.glob("*.png")):
        process_path(path)


if __name__ == "__main__":
    main()
