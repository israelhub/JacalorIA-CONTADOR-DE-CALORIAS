---
name: avatar-background-style
description: >-
  Cria novos fundos de perfil (avatar backgrounds) do Jacaloria no estilo
  aprovado (sky/pantano): quadrado 1:1, flat vector, glow central com anéis
  concêntricos e elementos decorativos em anel perto do centro, cantos calmos.
  Use quando o usuário pedir para criar/gerar novos fundos de avatar, fundos de
  perfil, avatar backgrounds ou itens de fundo para a loja.
---

# Estilo de Fundos de Avatar (Jacaloria)

## Regras de composição (obrigatórias)

- **Quadrado 1:1** (o banner do perfil recorta com `BoxFit.cover` para ~598/177; NÃO gerar faixa ultra-larga).
- **Centro**: glow suave e claro onde o avatar circular + moldura ficam, com anéis concêntricos brancos finos e quebrados (como `pantano.png`).
- **Elementos temáticos em ANEL ao redor do centro** — perto de onde fica a moldura. NUNCA concentrar detalhes nos cantos/bordas extremas (eles são cortados ou ficam longe da moldura).
- **Cantos e bordas extremas**: apenas gradiente suave, quase vazios.
- **Estilo**: flat vector, gradientes suaves, formas arredondadas, círculos translúcidos, linhas onduladas finas, bokeh, névoa leve. Sem fotorealismo, personagens, texto ou watermark.

## Workflow

1. Gerar com `GenerateImage`, `aspect_ratio: "1:1"`, passando como `reference_image_paths`:
   - `frontend/assets/images/avatar_backgrounds/sky.png`
   - `frontend/assets/images/avatar_backgrounds/pantano.png`

2. Usar este template de prompt (trocar apenas a linha do tema):

```
Square 1:1 avatar profile BACKGROUND in EXACT flat vector style of sky/pantano references: soft smooth gradients, rounded flat shapes, subtle translucent geometric circles, thin wavy lines, soft bokeh orbs, gentle mist.

CRITICAL COMPOSITION (not a wide banner):
- Soft bright glow in the CENTER where a circular avatar+frame will sit
- Faint thin white concentric broken circle rings in the center (like pantano) as avatar zone guide
- Put ALL decorative theme elements CLOSE to that central circle — in a ring around the avatar zone — NOT in the far corners
- Extreme corners and far edges stay soft, calm, almost empty gradient
- Theme <TEMA>: <paleta e elementos, sempre "hugging the mid-ring around the center">
- Full-bleed soft background, no letterbox, no borders, no photorealism, no characters, no text, no watermark.
```

3. Pós-processar: converter para RGB e redimensionar para **1254×1254** (tamanho de `sky.png`), salvar em `frontend/assets/images/avatar_backgrounds/<id>.png` com `optimize=True` (Pillow, LANCZOS).

4. Registrar o item novo:
   - Frontend: `frontend/lib/features/avatar_frames/models/avatar_background_catalog.dart` (`AvatarBackgroundItem` com id, nome, descrição PT-BR e assetPath).
   - Backend: `backend/src/missions/constants/store-catalog.seed.ts` (`category: 'avatar_background'`, `priceGold` ~120, `sortOrder` seguindo os existentes). O seed é upsertado no startup, sem migração manual.
   - **`itemKey` é UNIQUE em toda a loja** — NÃO reutilizar o id de uma moldura (ex.: moldura `soft_pink` + fundo `pink_blush`).
   - `pubspec.yaml` já inclui a pasta inteira — não precisa alterar.

5. Verificar: abrir a imagem gerada e conferir que os detalhes estão no anel central (não nos cantos) e que o estilo bate com `sky`/`pantano`.

## Exemplos de linha de tema que funcionaram

- FIRE/EMBER: "warm crimson→orange→gold gradient. Soft stylized flame shapes and ember blobs hugging the mid-ring around the center, floating tiny spark circles near the avatar zone."
- ROYAL: "soft deep purple→lavender→warm gold gradient. Soft flat gold crown silhouettes, rounded gem shapes, soft coin circles hugging the mid-ring — flat soft vector, NOT metallic chrome."
- BAMBOO GROVE: "soft mint-to-teal green gradient. Soft stylized flat bamboo stalks and rounded leaves framing the mid-ring like pantano reeds hugging the circle. Soft misty layered hills behind."
