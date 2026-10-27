# 蓝发少年：当前保全素材

图像内容、尺寸、透明通道和原有挂点保持。PNG现以无损WebP存储；SVG字节原样保留。完整索引为manifest.json（schema 2），用path与member共同定位ZIP成员。

- art/head/source.zip：64张SVG和64张无损WebP，含头底、表情、鼓腮、普通/帽下头发、独立刘海、狼尾和既有雷击骨相。
- art/body/source.zip：原有107张四色服装SVG和107张无损WebP。没有混入被否定的新服装或骨相。
- originals/：用户原始头底SVG保持独立原文件。
- registration/：原有符号/挂点/映射和5个派生动画bin，内容不变。

各包均不超过32,000,000字节。查看清单：python tools/image_packages.py verify。提取头部用于编辑：python tools/image_packages.py extract head；默认解压到外部workbench/drafts/image-packages/head。SVG与WebP对应关系保留原文件名，使用分目录存放。

角色仍未接入游戏。幽灵、界面和生产音频没有合格成品；C拨弦只确定方向，技能暂停。历史原PNG、雷击和服装完整审阅图保留在外部workbench归档及转换前快照，不因转换而重画。
