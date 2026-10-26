# 可复用图标素材

- `game-frame-white.png`：最终采用的白／灰材质边框，保留黑色线条；中间与外部透明，1254×1254。
- `game-backplate-purple.png`：获准的亮中心紫色底板；其透明通道也用于重新生成其他颜色的底板。
- `oracle-circlet.png`、`oracle-staff.png`：最终独立透明装备图层。
- `native-portrait-bg.png`：128×128原版图标模板参考。来源为已安装DST的 `data/databundles/images.zip` → `images/ui.xml` → `portrait_bg.tex`，供校验比例与明暗关系；原版资源版权归Klei Entertainment。
- `workshop-frame-purple.png`：从Roomcar既有工坊封面提取、保留纹理与圆角抗锯齿的紫色边框，512×512；不是游戏内厚边框。

处理入口及使用说明见 `tools/mod_art/README.md`。颜色、布局和测量记录集中在 `tools/mod_art/oracle.json`。插画与白框由本项目的图像生成流程制作；工坊边框来自Roomcar自己的旧封面。原始导出与完整制作记录保留在发布资料目录，不复制到仓库。

## frame-prompt.txt

```text
Generate ONE high-resolution square WHITE FRAME LAYER with genuine alpha transparency. The supplied image is a native Don't Starve Together portrait frame GEOMETRY reference only. Recreate its exact familiar proportions and shape: narrow inset rectangular portrait border, slightly softened square corners, a slim material band between BLACK INNER AND OUTER INK OUTLINES, with native hand-drawn line character. The entire LARGE CENTRAL OPENING MUST BE FULLY TRANSPARENT, not white, not parchment, not checkered pixels; the small area outside the frame must also be transparent. Only the frame ring is visible.
The frame's material band is WHITE and LIGHT NEUTRAL GRAY ONLY, with BLACK contour lines. No brown, gold, purple or any color. White/light gray material is a neutral tint mask which will be recolored by code while preserving black outlines. Clean high-resolution edges, fine clear black ink with subtle natural stroke variation, moderate delicate hand-rendered shading in gray. Preserve reference shape and black inner/outer contours; do not redesign into a futuristic double neon line, perfectly mechanical CAD frame, ornate fantasy frame, carved timber, thick border or splintered/chipped brush strokes. No dirt, scratches, spatter, noise, shadows cast over the central opening, text, figures, equipment, paper backplate, background scene or floating marks.
Frame centered and occupying most of the canvas with about 3percent outer transparent margin. Material band about 2-3percent canvas width, not heavy. Small softened squared corners consistent with reference. Treat this as a reusable editable art layer. True transparent PNG with empty transparent center is CRITICAL.
```

## items-prompt.txt

```text
Generate a NEW TRANSPARENT equipment sprite sheet for a Don't Starve Together mod icon, TWO equal square cells side by side, overall 2:1 landscape. TRUE alpha transparent background, no background color, no floor, shadow, frame, label, text or extras. LEFT CELL contains exactly ONE COMPLETE ORACLE CIRCLET, tilted naturally to reveal the round black band and front ivory eye jewel, and nothing else. RIGHT CELL contains exactly ONE COMPLETE UPRIGHT ORACLE ARCANE STAFF and nothing else. Keep generous transparent gutter between cells so each object can be extracted as an independent layer.
Reference1 exact circlet design: charcoal/black narrow band with gold fittings, angular ivory front frame around lavender vertical slit pupil gem, one small ivory diamond crest, side ivory accents. Reference2 top LEFT complete upright staff is the staff design: black/charcoal shaft with ivory inlays, small gold rings/collar, upright ivory pointed eye frame with lavender active vertical slit pupil, ivory diamond crest and butt. Ignore the loose head parts and other copies in reference2.
Use native hand-drawn Don't Starve ink, refined naturally variable pen pressure, selective delicate short strokes in shadows, subtly uneven contour rhythm and slight natural taper of long forms. The staff must be structurally straight with head and shaft aligned, but its edges must LOOK HAND-DRAWN rather than ruler-made parallel lines; collars and inlays are individually hand-rendered, not duplicated geometric shapes. Don't bend or kink the staff. Both objects clean ivory with broad muted gray shading, matte charcoal, restrained antique gold and lavender jewel. No dirty scratches, cracks, gray smudges, dense crosshatching, speckles, photographic metal shine or 3D gloss. No sterile uniform thick vector contour, CAD, plastic clipart or app icon style. Follow original angular handmade equipment identity. Full circlet and full staff visible in their respective square cells with safe padding. No background or cast shadow at all, true transparent PNG. This is a fresh generation of two cutout art layers, not an edit.
```
