"""Regenerate avatar frames with a moderate larger hole, without cropping ornaments."""

from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image

FRAMES_DIR = Path(
    r"c:\projetos\JacalorIA-CONTADOR-DE-CALORIAS\frontend\assets\images\avatar_frames"
)
BACKUP_DIR = FRAMES_DIR / "_backup_before_hole_expand"
PREVIEW_DIR = FRAMES_DIR / "_generated_previews"

# Modest hole targets (fraction of half shorter side). Enough for the photo,
# not so large that a gap appears between photo and ring.
TARGET_HOLE_BY_FILE = {
    "cat_ears.png": 0.76,
    "jaca.png": 0.78,
    "fox_tail.png": 0.75,
    "panda.png": 0.73,
    "fire_streak.png": 0.77,
    "fruit_ring.png": 0.74,
    "royal_gold.png": 0.73,
}

OPAQUE_ALPHA = 24


def load_rgba(path: Path) -> np.ndarray:
    return np.array(Image.open(path).convert("RGBA"))


def measure_hole(arr: np.ndarray) -> tuple[float, float]:
    h, w = arr.shape[:2]
    cy, cx = (h - 1) / 2.0, (w - 1) / 2.0
    yy, xx = np.ogrid[0:h, 0:w]
    dist = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2)
    opaque = arr[:, :, 3] > OPAQUE_ALPHA
    max_r = min(cx, cy, w - 1 - cx, h - 1 - cy)
    hole = 0.0
    for r in np.linspace(0, max_r, 600):
        mask = dist <= r
        if not mask.any():
            continue
        if opaque[mask].mean() > 0.008:
            break
        hole = float(r)
    return hole, float(max_r)


def sample_bilinear(arr: np.ndarray, ys: np.ndarray, xs: np.ndarray) -> np.ndarray:
    h, w = arr.shape[:2]
    out = np.zeros(ys.shape + (4,), dtype=np.float32)
    valid = (ys >= 0) & (ys <= h - 1) & (xs >= 0) & (xs <= w - 1)
    if not np.any(valid):
        return out

    ys_c = np.clip(ys, 0, h - 1)
    xs_c = np.clip(xs, 0, w - 1)
    y0 = np.floor(ys_c).astype(np.int32)
    x0 = np.floor(xs_c).astype(np.int32)
    y1 = np.minimum(y0 + 1, h - 1)
    x1 = np.minimum(x0 + 1, w - 1)
    wy = (ys_c - y0).astype(np.float32)[..., None]
    wx = (xs_c - x0).astype(np.float32)[..., None]

    i00 = arr[y0, x0].astype(np.float32)
    i01 = arr[y0, x1].astype(np.float32)
    i10 = arr[y1, x0].astype(np.float32)
    i11 = arr[y1, x1].astype(np.float32)
    sampled = (
        i00 * (1 - wy) * (1 - wx)
        + i01 * (1 - wy) * wx
        + i10 * wy * (1 - wx)
        + i11 * wy * wx
    )
    out[valid] = sampled[valid]
    return out


def regenerate_frame(src: np.ndarray, target_hole_ratio: float) -> np.ndarray:
    """Push only the inner edge out. Keep outer ornaments intact (no crop)."""
    h, w = src.shape[:2]
    cy, cx = (h - 1) / 2.0, (w - 1) / 2.0
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float64)
    dx = xx - cx
    dy = yy - cy
    dist = np.sqrt(dx * dx + dy * dy)
    angle = np.arctan2(dy, dx)

    src_hole, max_r = measure_hole(src)
    src_hole = max(src_hole, max_r * 0.4)

    opaque = src[:, :, 3] > OPAQUE_ALPHA
    src_outer = float(dist[opaque].max()) if opaque.any() else max_r

    target_hole = min(target_hole_ratio * max_r, max_r * 0.82)
    # Never shrink the hole; never jump more than +8pp from original.
    target_hole = max(target_hole, src_hole)
    target_hole = min(target_hole, src_hole + max_r * 0.08)

    if target_hole <= src_hole + 0.5:
        return src.copy()

    # Outer edge stays put — only the ring thickness compresses from the inside.
    dest_outer = src_outer

    span_d = max(dest_outer - target_hole, 1.0)
    span_s = max(src_outer - src_hole, 1.0)
    t = np.clip((dist - target_hole) / span_d, 0.0, 1.0)
    src_dist = src_hole + t * span_s

    # Outside the original outer radius: keep original pixels (ears/tails/crown).
    outside = dist > dest_outer
    src_x = cx + np.cos(angle) * src_dist
    src_y = cy + np.sin(angle) * src_dist
    sampled = sample_bilinear(src, src_y, src_x)

    out = src.copy().astype(np.float32)
    ring = ~outside
    out[ring] = sampled[ring]
    out = np.clip(np.nan_to_num(out), 0, 255).astype(np.uint8)

    # Clean circular hole only — do not touch outer decorations.
    feather = max(1.5, max_r * 0.008)
    alpha = out[:, :, 3].astype(np.float32)
    hard = dist <= (target_hole - feather)
    soft = (dist > (target_hole - feather)) & (dist < target_hole)
    alpha[hard] = 0.0
    if soft.any():
        alpha[soft] *= (dist[soft] - (target_hole - feather)) / feather
    out[:, :, 3] = np.clip(alpha, 0, 255).astype(np.uint8)
    return out


def make_preview(frame: np.ndarray, path: Path, photo_scale: float = 0.9) -> None:
    h, w = frame.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w]
    preview = np.zeros((h, w, 4), dtype=np.uint8)
    checker = ((xx // 28) + (yy // 28)) % 2 == 0
    preview[checker] = (255, 0, 180, 255)
    preview[~checker] = (35, 35, 35, 255)

    cy, cx = (h - 1) / 2.0, (w - 1) / 2.0
    dist = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2)
    hole, max_r = measure_hole(frame)
    photo_r = max_r * photo_scale
    preview[dist <= photo_r] = (70, 160, 110, 255)

    src = frame.astype(np.float32)
    dst = preview.astype(np.float32)
    a = src[:, :, 3:4] / 255.0
    comp = src * a + dst * (1.0 - a)
    Image.fromarray(np.clip(comp, 0, 255).astype(np.uint8)[:, :, :3], "RGB").save(
        path, quality=92
    )
    gap = hole - photo_r
    print(f"  hole={hole:.0f} photo={photo_r:.0f} gap={gap:.0f}px ({100*hole/max_r:.1f}%)")


def main() -> None:
    PREVIEW_DIR.mkdir(parents=True, exist_ok=True)

    for name, target_ratio in TARGET_HOLE_BY_FILE.items():
        backup = BACKUP_DIR / name
        src_path = backup if backup.exists() else (FRAMES_DIR / name)
        src = load_rgba(src_path)
        hole, max_r = measure_hole(src)
        regenerated = regenerate_frame(src, target_ratio)
        new_hole, new_max = measure_hole(regenerated)

        Image.fromarray(regenerated, "RGBA").save(FRAMES_DIR / name, optimize=True)
        print(
            f"{name}: {100 * hole / max_r:.1f}% -> {100 * new_hole / new_max:.1f}% "
            f"(target {100 * target_ratio:.0f}%)"
        )
        make_preview(regenerated, PREVIEW_DIR / name.replace(".png", "_preview.jpg"))


if __name__ == "__main__":
    main()
