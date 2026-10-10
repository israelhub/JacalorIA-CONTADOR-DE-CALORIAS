---
name: avatar-frame-style
description: >-
  Cria novas molduras de avatar (avatar frames) do Jacaloria no padrão aprovado
  do cat_ears: furo central ~73% do canvas, anel sólido grosso (~8% do canvas)
  com brilho glossy, enfeites por fora do anel, contorno branco estilo sticker.
  Inclui scripts de medição e pós-processamento (recorte de fundo,
  centralização do furo). Use quando o usuário pedir para criar/gerar/refazer
  molduras de avatar, avatar frames ou bordas de foto de perfil.
---

# Estilo de Molduras de Avatar (Jacaloria)

## Geometria de referência (medida do `cat_ears.png`)

| Métrica | Valor alvo |
|---|---|
| Furo central / canvas | **~0.72–0.73** |
| Espessura do anel sólido / canvas | **~8%** (grosso, nunca linha fina) |
| Canvas final | 1024×1024 RGBA, furo centralizado |

Erros que já aconteceram e devem ser evitados:
- Anel fino demais (1–3% do canvas) → moldura "estreita" e destoante.
- Furo pequeno (~0.62) por margem transparente ou enfeites esparramados → foto de perfil fica menor que nas outras molduras.
- RGB residual em pixels com alpha 0 (fundo “apagado” só no alpha) → no iOS/Impeller e no downscale vira halo / mancha de fundo; no Android parece ok. O `process_frame.py` zera isso via `sanitize_straight_alpha`.
- Franja semi-transparente esbranquiçada/cinza nas bordas (soft_pink / soft_blue / royal_gold) → no Safari iOS parece “fundo não cortado”. Rodar `defringe_frames.py` (o `process_frame.py` já chama no final).

## Regras de estilo

- Anel circular GROSSO com gradiente temático e brilhos brancos glossy (como o anel arco-íris do `cat_ears`).
- Enfeites temáticos ficam **por fora / por cima** do anel grosso (como orelhas/rabo/patinha do gato) — nunca substituem o anel.
- Contorno branco fino "sticker" em volta de tudo.
- Flat vector kawaii de mobile game, sem fotorealismo, personagens, texto, watermark, nem foto dentro do furo.

## Workflow

1. Gerar com `GenerateImage`, `aspect_ratio: "1:1"`, passando como `reference_image_paths`:
   - `frontend/assets/images/avatar_frames/cat_ears.png`
   - `frontend/assets/images/avatar_frames/panda.png`

2. Template de prompt (trocar apenas o bloco THEME):

```
Circular avatar FRAME border PNG asset for a mobile app, EXACT same proportions and art style as the cat-ears reference frame.

CRITICAL GEOMETRY (must match cat-ears reference exactly):
- Square 1:1 canvas
- LARGE central circular HOLE for the avatar photo taking about 66% of canvas width (NOT larger, NOT 75%+)
- THICK solid decorative RING around the hole — ring thickness about 8% of canvas width (same visual weight as the cat-ears rainbow ring). Do NOT make a thin wire-like ring.
- Decorations sit OUTSIDE / on top of this thick ring and may extend toward canvas edges, like cat ears/whiskers/tail do
- Even small margin from outermost decorations to canvas edge
- Clean sticker cutout look

THEME: <tema>. The THICK ring is <gradiente/material> with glossy white highlight streaks like the cat-ears ring gloss. <enfeites> as outer decorations only (outside the thick ring), not replacing the ring. White clean outline stroke around everything like cat-ears sticker style. Cute flat vector kawaii mobile-game UI, soft gradients, no photorealism, no characters, no text, no watermark, no photo inside the hole.
```

3. Pós-processar (recorta fundo branco/preto/xadrez, centraliza o furo e casa a fração do furo com o `cat_ears`):

```bash
python .cursor/skills/avatar-frame-style/scripts/process_frame.py <entrada.png> frontend/assets/images/avatar_frames/<id>.png
```

Requer `pillow`, `numpy`, `scipy`. O script imprime `hole_frac` e espessura do anel — **só aceitar se hole_frac ficar em 0.70–0.74 e anel ~7–9%**.

4. Validar contra as outras molduras:

```bash
python .cursor/skills/avatar-frame-style/scripts/measure_frames.py
```

5. Registrar:
   - `frontend/lib/features/avatar_frames/models/avatar_frame_catalog.dart` (novo `AvatarFrameItem`).
   - `backend/src/missions/constants/store-catalog.seed.ts` (`category: 'avatar_frame'`).
   - **`itemKey` é UNIQUE em toda a loja** — NÃO reutilizar o id de um fundo (ex.: moldura `soft_pink` + fundo `pink_blush`, como `fire_streak`/`ember_blaze`).
   - `frontend/lib/shared/widgets/framed_avatar.dart` → `_effectiveFramedAvatarScale`: com furo ~0.73, usar escala **0.8** (mesmo caso do `cat_ears_soft`).
