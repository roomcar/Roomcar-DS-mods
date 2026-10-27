# Roomcar DS / DST Mods

各Mod保持独立目录：_BigBag--DS、_BigBag--DST、_GodHat--DST、_PowerSword--DS、_PowerSword--DST、_Ordinary--DST。

- `assets/`：当前使用的源素材、原稿和挂点。蓝发少年统一入口是`assets/characters/blue_boy/manifest.json`。
- `tools/`：实际使用的构建、音频和验证工具。
- `tests/`：现有测试和必要样本。
- `docs/repository-layout.md`：仓库与外部工作目录分工。
- `docs/ordinary/character-assets.md`：蓝发少年范围与未完成项。

历史稿、参考输出、详细审阅图、研究/会话记录存放于仓库同级`Roomcar-DS-mods-workbench`。可通过`ROOMCAR_WORKBENCH`指定本机外部工作根目录。源码仓库不依赖旧会话目录来定位当前已保全素材。

蓝发少年尚未接入可玩角色，技能暂停。已完成的服装、头部和雷击基准不得因整理目录而重画或替换。

图像存储：仓库PNG已转为无损WebP；紧密关联的源图按用途打包，每包≤32 MB。`assets/image-assets.json`记录转换与包索引，`python tools/image_packages.py verify`核验全部图像及ZIP。
