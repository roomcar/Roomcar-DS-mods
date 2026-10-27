# 普通系列素材构建

从仓库根目录运行（Python3，依赖 Pillow）：

```powershell
python tools/ordinary_series/build_assets.py --converter "C:/Program Files (x86)/Steam/steamapps/common/Don't Starve Mod Tools/mod_tools/tools/bin/TextureConverter.exe"
```

只读取 assets/ordinary_series/ 的三张批准素材和挂点记录，生成 _Ordinary--DST/ 的四个动画包、共享库存图集和模组图标。不生成新插画，不逐行扭曲图片。构建临时文件默认写入仓库同级 Roomcar-DS-mods-workbench/build/ordinary_series/；可用 --work-root 或 ROOMCAR_WORKBENCH 指定外部工作根目录。--mod-dir 可把验证构建输出到独立目录，默认仍输出到 _Ordinary--DST/。

动画文件使用官方 Mod Tools buildanimation.py 记载的 BILD6 / ANIM4格式；纹理由已安装的官方 TextureConverter 以ARGB、OpenGL、预乘透明及mipmap编译。swap_hat含正侧背三个帧，地面idle独立使用item符号。高分辨率源像素只裁透明边距，符号几何由批准画布反算。

库存与地面展示使用现有正面素材缩放，不引入额外造型。重新构建后可用 validate_assets.py 检查动画符号、纹理与原始批准佩戴位置的往返对应。

验证已有资源：`python tools/ordinary_series/validate_assets.py`。使用验证构建时可同样传入`--mod-dir`。

三张帽子源图从assets/ordinary_series/hat_layers.zip内的无损WebP直接读取。模组预览图输出为modicon.webp；转换器需要的PNG只在外部WORK目录生成，运行TEX和动画数据保持原格式。
