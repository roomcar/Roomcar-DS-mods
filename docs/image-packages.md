# 源图包的使用

四组包：head（角色头部）、body（角色服装）、ordinary（帽子图层）、mod-art（模组图标图层）。每包不超过32,000,000字节。

验证：`python tools/image_packages.py verify`。角色语义清单另由`python tools/characters/blue_boy/verify_sources.py`核验。

提取：`python tools/image_packages.py extract head`。默认输出到仓库外的workbench/drafts/image-packages/head；可通过--output指定另一个仓库外目录。已有不同内容不会覆盖。

候选打包：`python tools/image_packages.py pack --input <解包并编辑的目录> --output <新的候选ZIP路径>`。输出不可覆盖现有包，超过32MB会拒绝写入；按用途拆成更小的完整包，不创建不能单独打开的分卷。候选采用前需更新对应manifest及image-assets.json的哈希，避免把未经确认的修改直接当成当前源。

WebP使用lossless=True、quality=100、method=6、exact=True；保留透明像素RGB、Alpha、尺寸以及源ICC。原PNG的DPI/色度等元数据另记在image-assets.json，原始文件在外部转换前快照。SVG不栅格化，直接原字节打包。

官方纹理转换器需要PNG时在外部build中暂存。Mod运行的TEX、XML、动画包和原版内部资源标识不改动。原有工坊预览现在是WebP；发布流程若要求PNG，应在外部导出临时PNG，不把PNG放回仓库。
