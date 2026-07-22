"""Enlarge transparent center holes in avatar frame PNGs so the photo fits fully."""

from __future__ import annotations

import shutil
from pathlib import Path

import numpy as np
from PIL import Image

FRAMES_DIR = Path(
    r"c:\projetos\JacalorIA-CONTADOR-DE-CALORIAS\frontend\assets\images\avatar_frames"
)
BACKUP_DIR = FRAMES_DIR / "_backup_before_hole_expand"
ACTIVE = [
    "cat_ears.png",
    "jaca.png",
    "fox_tail.png",
    "panda.png",
    "fire_streak.png",
    "fruit_ring.png",
    "royal_gold.png",
]

# Target inner hole as fraction of half the shorter side.
TARGET_HOLE_RATIO = 0.80
FEATHER_RATIO = 0.018
OPAQUE_ALPHA = 32


def measure_hole(arr: np.ndarray) -> tuple[float, float]:
    h, w = arr.shape[:2]
    cy, cx = (h - 1) / 2.0, (w - 1) / 2.0
    yy, xx = np.ogrid[0:h, 0:w]
    dist = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2)
    opaque = arr[:, :, 3] > OPAQUE_ALPHA
    max_r = min(cx, cy, w - 1 - cx, h - 1 - cy)
    hole = 0.0
    for r in np.linspace(0, max_r, 500):
        mask = dist <= r
        count = int(mask.sum())
        if count == 0:
            continue
        if opaque[mask].mean() > 0.01:
            break
        hole = float(r)
    return hole, max_r


def expand_hole(arr: np.ndarray, target_r: float, feather: float) -> np.ndarray:
    out = arr.copy()
    h, w = out.shape[:2]
    cy, cx = (h - 1) / 2.0, (w - 1) / 2.0
    yy, xx = np.ogrid[0:h, 0:w]
    dist = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2)

    hard = dist <= (target_r - feather)
    soft = (dist > (target_r - feather)) & (dist < target_r)

    alpha = out[:, :, 3].astype(np.float32)
    alpha[hard] = 0.0
    if soft.any() and feather > 0:
        t = (dist[soft] - (target_r - feather)) / feather
        # Keep more of the original near the outer soft edge.
        alpha[soft] = alpha[soft] * t
    out[:, :, 3] = np.clip(alpha, 0, 255).astype(np.uint8)
    return out


def main() -> None:
    BACKUP_DIR.mkdir(parents=True, exist_ok=True)

    for name in ACTIVE:
        src = FRAMES_DIR / name
        backup = BACKUP_DIR / name
        if not backup.exists():
            shutil.copy2(src, backup)

        img = Image.open(src).convert("RGBA")
        arr = np.array(img)
        hole, max_r = measure_hole(arr)
        target = TARGET_HOLE_RATIO * max_r
        feather = FEATHER_RATIO * max_r

        if hole >= target - 1:
            print(f"{name}: already ok hole={hole:.1f}/{max_r:.1f} (target {target:.1f})")
            continue

        expanded = expand_hole(arr, target, feather)
        Image.fromarray(expanded, "RGBA").save(src, optimize=True)
        new_hole, _ = measure_hole(expanded)
        print(
            f"{name}: hole {hole:.1f} -> {new_hole:.1f} "
            f"(target {target:.1f}, +{(new_hole - hole) / max_r * 100:.1f}% of half)"
        )


if __name__ == "__main__":
    main()
