# 蓝发少年工具

verify_sources.py只核对manifest中保全文件的SHA256，不生成图片。patch_hairfront_draw_order.py是原有层序修正工具的原文件副本，只供将来的独立角色动画处理，不全局替换原生动画。

synthesize_voice.py保留既有合成算法，仅把默认输出移到外部drafts/ordinary/blue_boy/voice/generated-时间戳；默认C拨弦，--timbre可显式选reed/flute/pluck，--output可指定输出。支持--work-root或ROOMCAR_WORKBENCH。本次迁移没有重新生成声音，也不表示现有音频获准。

此目录没有新的全角色编译入口，不能把保全源素材冒充已经完成角色接入。不要调用历史/被否定稿件中的构建脚本覆盖当前源。
