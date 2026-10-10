"""Processa uma moldura gerada: recorta fundo, centraliza o furo e casa a
fracao do furo com a referencia cat_ears.

Uso:
    python process_frame.py <entrada.png> <saida.png> [--ref caminho/cat_ears.png]

Requer: pillow, numpy, scipy.
"""

import argparse
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage

OUT_SIZE = 1024
DEFAULT_REF = (
    Path(__file__).resolve().parents[4]
    / "frontend"
    / "assets"
    / "images"
    / "avatar_frames"
    / "cat_ears.png"
)


def cut_background(arr: np.ndarray) -> np.ndarray:
    """Torna transparente fundo quase-branco, quase-preto e xadrez cinza."""
    arr = np.array(arr, copy=True)
    rgb = arr[..., :3].astype(np.int16)
    h, w = rgb.shape[:2]
    alpha = arr[..., 3].astype(np.uint8).copy()

    white = (rgb.min(axis=2) >= 235) & (rgb.max(axis=2) - rgb.min(axis=2) < 25)
    black = rgb.max(axis=2) <= 28
    sat = rgb.max(axis=2) - rgb.min(axis=2)
    gray = (sat <= 18) & (rgb.mean(axis=2) >= 40) & (rgb.mean(axis=2) <= 220)

    # Preserva pixels coloridos da arte mesmo que meio acinzentados
    warmish = (rgb[..., 0] > rgb[..., 2] + 8) | (rgb[..., 1] > rgb[..., 2] + 8)
    cool = (rgb[..., 2] > rgb[..., 1] + 15) | (rgb[..., 2] > rgb[..., 0] + 15)

    bg = white | black | (gray & ~warmish & ~cool)

    # Flood-fill do fundo a partir das bordas do canvas
    edge = np.zeros((h, w), dtype=bool)
    edge[0, :] = edge[-1, :] = True
    edge[:, 0] = edge[:, -1] = True
    seed = edge & (white | black | gray)
    structure = np.ones((3, 3), dtype=bool)
    grown = seed.copy()
    for _ in range(max(h, w)):
        dil = ndimage.binary_dilation(grown, structure=structure)
        add = dil & (white | black | gray) & ~grown
        if not add.any():
            break
        grown |= add
    bg |= grown

    alpha[bg] = 0
    alpha_img = Image.fromarray(alpha, "L").filter(ImageFilter.GaussianBlur(0.6))
    alpha = np.array(alpha_img, copy=True)
    alpha[bg] = 0
    out = arr.copy()
    out[..., 3] = alpha
    # Zera RGB no fundo: residual em alpha=0 vaza no iOS/Impeller e no
    # downscale (cacheWidth), parecendo "fundo nao cortado".
    out = sanitize_straight_alpha(out)
    return out


def sanitize_straight_alpha(arr: np.ndarray) -> np.ndarray:
    """Remove RGB residual em pixels transparentes (straight alpha limpo).

    PNGs gerados por IA / remocao de fundo costumam deixar cor no canal RGB
    com alpha 0. Android/Skia ignora; iOS (e resize bilinear) mistura e
    cria halo / mancha de fundo.
    """
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


def hole_stats(alpha: np.ndarray) -> dict:
    """Furo interno = raio onde a maior parte do circulo vira opaca."""
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

    transparent = alpha < 16
    labels, _ = ndimage.label(transparent)
    center_lbl = labels[cy, cx]
    if center_lbl == 0:
        hole_bbox = (cx - hole_r, cy - hole_r, cx + hole_r, cy + hole_r)
    else:
        ys, xs = np.where(labels == center_lbl)
        hole_bbox = (int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max()))

    return {
        "hole_r": hole_r,
        "outer_r": outer_r,
        "ring_thick": outer_r - hole_r,
        "hole_frac": hole_r * 2 / float(w),
        "hole_bbox": hole_bbox,
    }


def content_bbox(alpha: np.ndarray, thresh: int = 20):
    ys, xs = np.where(alpha > thresh)
    if len(xs) == 0:
        return None
    return int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())


def process(src: Path, dst: Path, ref: Path) -> None:
    ref_alpha = np.asarray(Image.open(ref).convert("RGBA"))[..., 3]
    target = hole_stats(ref_alpha)["hole_frac"]
    print(f"referencia {ref.name}: hole_frac={target:.3f} (alvo)")

    im = Image.open(src).convert("RGBA")
    arr = cut_background(np.asarray(im))
    alpha = arr[..., 3]
    stats = hole_stats(alpha)
    bbox = content_bbox(alpha)
    if bbox is None:
        raise SystemExit(f"imagem vazia apos recorte: {src}")

    h, w = alpha.shape
    pad = 4
    x0 = max(0, bbox[0] - pad)
    y0 = max(0, bbox[1] - pad)
    x1 = min(w - 1, bbox[2] + pad)
    y1 = min(h - 1, bbox[3] + pad)

    hx0, hy0, hx1, hy1 = stats["hole_bbox"]
    hcx = (hx0 + hx1) / 2
    hcy = (hy0 + hy1) / 2

    # Canvas quadrado centrado no furo, cobrindo todo o conteudo e com lado
    # suficiente para o furo atingir a fracao alvo.
    half = max(abs(hcx - x0), abs(x1 - hcx), abs(hcy - y0), abs(y1 - hcy))
    half = max(half, (stats["hole_r"] * 2 / target) / 2)
    side = int(np.ceil(half * 2))

    canvas = np.zeros((side, side, 4), dtype=np.uint8)
    ox = int(round(side / 2 - hcx))
    oy = int(round(side / 2 - hcy))
    sx0, sy0 = max(0, -ox), max(0, -oy)
    sx1, sy1 = min(w, side - ox), min(h, side - oy)
    dx0, dy0 = max(0, ox), max(0, oy)
    canvas[dy0 : dy0 + (sy1 - sy0), dx0 : dx0 + (sx1 - sx0)] = arr[sy0:sy1, sx0:sx1]

    # Se enfeites esparramados derrubaram a fracao do furo, recorta o excesso
    cur = hole_stats(canvas[..., 3])
    if cur["hole_frac"] < target - 0.03:
        crop_side = max(int(round(cur["hole_r"] * 2 / target)), 64)
        cc = side // 2
        half_c = crop_side // 2
        y0c, x0c = max(0, cc - half_c), max(0, cc - half_c)
        cropped = canvas[y0c : min(side, y0c + crop_side), x0c : min(side, x0c + crop_side)]
        ch, cw = cropped.shape[:2]
        if ch != crop_side or cw != crop_side:
            padded = np.zeros((crop_side, crop_side, 4), dtype=np.uint8)
            padded[:ch, :cw] = cropped
            cropped = padded
        canvas = cropped

    pil = Image.fromarray(canvas, "RGBA").resize(
        (OUT_SIZE, OUT_SIZE), Image.Resampling.LANCZOS
    )
    a = np.array(pil, copy=True)
    soft = Image.fromarray(a[..., 3], "L").filter(ImageFilter.GaussianBlur(0.4))
    a[..., 3] = np.asarray(soft)
    a[a[..., 3] < 8, 3] = 0
    a = sanitize_straight_alpha(a)
    # Halo suave esbranquicado (rosa/azul/ouro) vaza no Safari iOS.
    from defringe_frames import defringe_frame

    a = defringe_frame(a)

    Image.fromarray(a, "RGBA").save(dst)
    final = hole_stats(a[..., 3])
    print(
        f"{dst.name}: hole_frac={final['hole_frac']:.3f} "
        f"ring_thick~{final['ring_thick']} ({final['ring_thick'] / OUT_SIZE:.3f})"
    )
    if not (0.70 <= final["hole_frac"] <= 0.74):
        print("AVISO: hole_frac fora do alvo 0.70-0.74 — revisar a geracao.")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("src", type=Path)
    parser.add_argument("dst", type=Path)
    parser.add_argument("--ref", type=Path, default=DEFAULT_REF)
    args = parser.parse_args()
    process(args.src, args.dst, args.ref)


if __name__ == "__main__":
    main()
