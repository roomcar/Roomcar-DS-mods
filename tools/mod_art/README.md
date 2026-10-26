# 模组图标与工坊边框工具

保存神谕系列最终采用的分层素材和可复用处理流程。源素材在 `assets/mod_art/`，生成物输出到已忽略的 `output/mod-art/`。本工具不联网、不生成新插画，不会自动修改模组或发布内容。

从仓库根目录运行：

```sh
python -m pip install -r tools/mod_art/requirements.txt
python tools/mod_art/icon_pipeline.py game --output-dir output/mod-art/oracle
python tools/mod_art/icon_pipeline.py cover --art path/to/unframed-art.png --output output/mod-art/workshop-cover.png
python tools/mod_art/icon_pipeline.py compile --converter path/to/TextureConverter.exe --image output/mod-art/oracle/godhaticon.png --output output/mod-art/oracle/godhaticon.tex
```

`game` 按 `oracle.json` 重现获准的512像素图标：保留黑色墨线、边框形状和透明通道，染色材质部分，再叠加球形渐变底板、秘法杖、头环。修改配置可调整颜色和摆放，不需要重复生成边框。

`cover` 使用原有工坊封面周边像素，保留金色部分原有的明暗纹理和微小圆角覆盖关系；当前保存的是获准的紫色版本。512像素模板的边缘比例为外黑5、彩带3、内黑2，内容范围 `[10,10,502,502)`，按输出分辨率同比缩放。

`compile` 只调用本机官方模组工具中的 TextureConverter；保持实际发布使用的 ARGB、OpenGL、预乘透明和mipmap参数。转换器不随仓库分发。

维护规则：只保留最终采用的素材和一个处理入口。生成物、调试截图、轮次脚本、打包zip和OpenRaster导出不提交。更换插画时保留设计参考；没有明确要求时应全新生成，避免擅自改图。查看预览先压到约200 KB以下。
