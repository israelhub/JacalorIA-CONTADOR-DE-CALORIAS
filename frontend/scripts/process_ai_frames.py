"""Convert AI-generated frames (magenta hole + black bg) into app-ready PNGs."""

from __future__ import annotations

import shutil
from pathlib import Path

import numpy as np
from PIL import Image

SRC_DIR = Path(
    r"C:\Users\israelcu\.cursor\projects\c-projetos-JacalorIA-CONTADOR-DE-CALORIAS\assets"
)
OUT_DIR = Path(
    r"c:\projetos\JacalorIA-CONTADOR-DE-CALORIAS\frontend\assets\images\avatar_frames"
)
BACKUP_AI = OUT_DIR / "_backup_before_ai_regen"
PREVIEW_DIR = OUT_DIR / "_generated_previews"

MAPPING = {
    "gen_cat_ears.png": "cat_ears.png",
    "gen_jaca.png": "jaca.png",
    "gen_fox_tail.png": "fox_tail.png",
    "gen_panda.png": "panda.png",
    "gen_fire_streak.png": "fire_streak.png",
    "gen_fruit_ring.png": "fruit_ring.png",
    "gen_royal_gold.png": "royal_gold.png",
}

# Consistent transparent hole across all frames.
TARGET_HOLE_RATIO = 0.74
OUTPUT_SIZE = 1024


def is_magenta(rgb: np.ndarray) -> np.ndarray:
    r, g, b = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
    # Bright magenta / hot pink center marker.
    return (r > 180) & (b > 180) & (g < 140) & (r + b > g * 2.2)


def is_black_bg(rgb: np.ndarray) -> np.ndarray:
    r, g, b = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
    return (r < 28) & (g < 28) & (b < 28)


def process(src: np.ndarray) -> np.ndarray:
    rgb = src[:, :, :3].astype(np.float32)
    alpha = np.full(src.shape[:2], 255, dtype=np.float32)

    magenta = is_magenta(rgb)
    black = is_black_bg(rgb)
    alpha[magenta | black] = 0

    # Soften magenta fringe (semi-magenta pixels near hole).
    r, g, b = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
    soft_magenta = (r > 140) & (b > 140) & (g < 160) & (r + b > g * 1.8) & ~magenta
    alpha[soft_magenta] *= 0.15

    out = src.copy().astype(np.float32)
    out[:, :, 3] = alpha

    # Enforce a clean circular hole at a consistent ratio.
    h, w = out.shape[:2]
    cy, cx = (h - 1) / 2.0, (w - 1) / 2.0
    yy, xx = np.ogrid[0:h, 0:w]
    dist = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2)
    max_r = min(cx, cy, w - 1 - cx, h - 1 - cy)
    hole_r = TARGET_HOLE_RATIO * max_r
    feather = max_r * 0.01

    a = out[:, :, 3]
    hard = dist <= (hole_r - feather)
    soft = (dist > (hole_r - feather)) & (dist < hole_r)
    a[hard] = 0
    if soft.any():
        t = (dist[soft] - (hole_r - feather)) / feather
        a[soft] *= t
    out[:, :, 3] = a

    # Clean almost-transparent dust.
    out[out[:, :, 3] < 8, 3] = 0

    return np.clip(out, 0, 255).astype(np.uint8)


def measure_hole(arr: np.ndarray) -> tuple[float, float]:
    h, w = arr.shape[:2]
    cy, cx = (h - 1) / 2.0, (w - 1) / 2.0
    yy, xx = np.ogrid[0:h, 0:w]
    dist = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2)
    opaque = arr[:, :, 3] > 24
    max_r = min(cx, cy, w - 1 - cx, h - 1 - cy)
    hole = 0.0
    for r in np.linspace(0, max_r, 500):
        mask = dist <= r
        if mask.any() and opaque[mask].mean() > 0.008:
            break
        hole = float(r)
    return hole, float(max_r)


def make_preview(frame: np.ndarray, path: Path) -> None:
    h, w = frame.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w]
    preview = np.zeros((h, w, 4), dtype=np.uint8)
    checker = ((xx // 32) + (yy // 32)) % 2 == 0
    preview[checker] = (220, 220, 220, 255)
    preview[~checker] = (40, 40, 40, 255)

    cy, cx = (h - 1) / 2.0, (w - 1) / 2.0
    dist = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2)
    hole, max_r = measure_hole(frame)
    # App photo ~ same as hole with outerScale ~ 1/0.74
    photo_r = hole * 0.98
    preview[dist <= photo_r] = (80, 170, 120, 255)

    src = frame.astype(np.float32)
    dst = preview.astype(np.float32)
    a = src[:, :, 3:4] / 255.0
    comp = src * a + dst * (1 - a)
    Image.fromarray(np.clip(comp, 0, 255).astype(np.uint8)[:, :, :3], "RGB").save(
        path, quality=92
    )


def main() -> None:
    BACKUP_AI.mkdir(parents=True, exist_ok=True)
    PREVIEW_DIR.mkdir(parents=True, exist_ok=True)

    for src_name, out_name in MAPPING.items():
        src_path = SRC_DIR / src_name
        out_path = OUT_DIR / out_name

        if out_path.exists() and not (BACKUP_AI / out_name).exists():
            shutil.copy2(out_path, BACKUP_AI / out_name)

        img = Image.open(src_path).convert("RGBA")
        if img.size != (OUTPUT_SIZE, OUTPUT_SIZE):
            img = img.resize((OUTPUT_SIZE, OUTPUT_SIZE), Image.Resampling.LANCZOS)

        processed = process(np.array(img))
        Image.fromarray(processed, "RGBA").save(out_path, optimize=True)

        hole, max_r = measure_hole(processed)
        make_preview(processed, PREVIEW_DIR / out_name.replace(".png", "_preview.jpg"))
        print(f"{out_name}: hole {100 * hole / max_r:.1f}% ({hole:.0f}/{max_r:.0f})")


if __name__ == "__main__":
    main()
