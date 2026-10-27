# 蓝发少年当前范围与素材状态

当前范围是无自定义技能的基础角色；技能设计暂停。唯一保全源入口：assets/characters/blue_boy/manifest.json。

已原样归位：用户头底原稿；64张当前头部分件SVG及64张无损WebP（包括既有雷击骨相）；107张四色服装SVG及107张无损WebP；7份符号/挂点/映射记录；5个原有派生动画bin。没有混入被否定的新增服装、骨相或鬼魂。当前仍未完成可玩角色接入。

下一步先以保全源核对真实缺件，禁止把已有成品当作需要重画的内容。此前调查的28个索引是文件清单差集，不能直接推导出28张新画任务。雷击旧图中官方身体只作效果参照，应保留旧效果与来源约束。

幽灵/界面图待完成，C拨弦只选定音色方向；未把A整套或C候选作为已验收生产音频。官方动作音继续可复用；10类角色声音调查见外部records/investigations/2026-10-27-basic-character-audit。

外部工作根目录见docs/repository-layout.md。被否定素材在archive/ordinary/blue_boy/rejected；暂停技能设计在archive/ordinary/blue_boy/versions/2026-10-27-paused-skill-design。完整会话在records/conversations/2026-10-27-handoff-chain。

迁移只核验字节、路径与既有资源；编译成功不等于视觉认可，离线验证不等于游戏实测。主客机、存读档、死亡复活、装备和声音接入的游戏验收仍待角色实现阶段。

2026-10-28存储调整：头部/身体分别以source.zip保存，manifest中的path+member定位成员；仅转换编码、打包，不改图像内容。解包/验证入口见tools/image_packages.py。
