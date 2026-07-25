"""Gera o ícone pequeno de notificação Android (ic_notification).

O Android renderiza o small icon como silhueta monocromática (usa só o canal
alpha). Este script recorta o fundo verde do app_icon.png via flood fill a
partir das bordas, transforma o jacaré numa silhueta branca e exporta PNGs
nas densidades padrão para android/app/src/main/res/drawable-*dpi.

Uso: python tools/generate_notification_icon.py
"""

from collections import deque
from pathlib import Path

from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "frontend" / "assets" / "images" / "app_icon.png"
RES_DIR = ROOT / "frontend" / "android" / "app" / "src" / "main" / "res"

# dp de referência: 24. Conteúdo deve ocupar ~22dp com 1dp de respiro por lado.
SIZES = {
    "mdpi": 24,
    "hdpi": 36,
    "xhdpi": 48,
    "xxhdpi": 72,
    "xxxhdpi": 96,
}
TOLERANCE = 60  # distância de cor (soma RGB) aceita como "fundo"
PADDING_RATIO = 0.08
WORK_SIZE = 1024  # tamanho de trabalho (o alvo final é <= 96px)
EDGE_TRIM = 6  # a arte original tem uma moldura acinzentada no perímetro


def build_foreground_mask(img: Image.Image) -> Image.Image:
    """Máscara 0/255 do que NÃO é fundo, via flood fill a partir das bordas."""
    rgb = img.convert("RGB")
    w, h = rgb.size
    px = rgb.load()
    # Amostra o fundo um pouco para dentro, fora da moldura da borda.
    bg = px[w // 2, EDGE_TRIM + 4]

    def is_bg(p):
        return (
            abs(p[0] - bg[0]) + abs(p[1] - bg[1]) + abs(p[2] - bg[2])
            <= TOLERANCE
        )

    visited = bytearray(w * h)
    queue = deque()
    for x in range(w):
        for y in (0, h - 1):
            if not visited[y * w + x] and is_bg(px[x, y]):
                visited[y * w + x] = 1
                queue.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            if not visited[y * w + x] and is_bg(px[x, y]):
                visited[y * w + x] = 1
                queue.append((x, y))

    while queue:
        x, y = queue.popleft()
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < w and 0 <= ny < h:
                idx = ny * w + nx
                if not visited[idx] and is_bg(px[nx, ny]):
                    visited[idx] = 1
                    queue.append((nx, ny))

    # Dentro da figura, recorta os traços escuros neutros (contorno, olhos,
    # narinas, boca) para a silhueta ficar reconhecível como o mascote.
    data = []
    for y in range(h):
        row = y * w
        for x in range(w):
            if visited[row + x]:
                data.append(0)
                continue
            r, g, b = px[x, y]
            hi, lo = max(r, g, b), min(r, g, b)
            is_dark_stroke = hi < 95 and (hi - lo) < 35
            data.append(0 if is_dark_stroke else 255)

    mask = Image.new("L", (w, h), 255)
    mask.putdata(data)
    return mask


def main() -> None:
    src = Image.open(SOURCE).convert("RGB")
    scale = WORK_SIZE / max(src.size)
    if scale < 1:
        src = src.resize(
            (round(src.width * scale), round(src.height * scale)),
            Image.LANCZOS,
        )
    src = src.crop(
        (EDGE_TRIM, EDGE_TRIM, src.width - EDGE_TRIM, src.height - EDGE_TRIM)
    )
    mask = build_foreground_mask(src)

    bbox = mask.getbbox()
    mask = mask.crop(bbox)

    # Enquadra num canvas quadrado com padding uniforme.
    side = max(mask.size)
    pad = int(side * PADDING_RATIO)
    canvas_side = side + 2 * pad
    canvas = Image.new("L", (canvas_side, canvas_side), 0)
    canvas.paste(
        mask,
        ((canvas_side - mask.width) // 2, (canvas_side - mask.height) // 2),
    )
    # Suaviza a borda antes do downscale para evitar serrilhado.
    canvas = canvas.filter(ImageFilter.GaussianBlur(radius=canvas_side / 512))

    for density, size in SIZES.items():
        alpha = canvas.resize((size, size), Image.LANCZOS)
        icon = Image.new("RGBA", (size, size), (255, 255, 255, 0))
        icon.putalpha(alpha)
        out_dir = RES_DIR / f"drawable-{density}"
        out_dir.mkdir(parents=True, exist_ok=True)
        out = out_dir / "ic_notification.png"
        icon.save(out)
        print(f"gerado: {out} ({size}x{size})")


if __name__ == "__main__":
    main()
