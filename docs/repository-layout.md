# 仓库与外部工作目录

制定日期：2026-10-28。

仓库：`C:\Works\Roomcar-DS-mods`。
外部工作目录：`C:\Works\Roomcar-DS-mods-workbench`，与仓库平级，不建立Git仓库，不以软链接或Git子模块挂回仓库。

2026-10-28已按此结构执行归档、当前源归位和工具输出路径调整。原图和既有派生动画没有修改；幽灵、界面、生产声音仍未完成。迁移清单位于外部 records/migrations/2026-10-28-layout-migration/。

## 仓库里放什么

仓库保存让别人能继续开发、重建并交付Mod的必要文件：代码、实际使用的源素材、确定采用的游戏资源、构建工具、测试、简明设计和验收状态。不能以减少Git文件数为理由把唯一原稿、表情、挂点或生产依赖移到仓库外。

```text
Roomcar-DS-mods/
├─ _BigBag--DS/                   现有独立Mod，路径保持
├─ _BigBag--DST/
├─ _GodHat--DST/
├─ _PowerSword--DS/
├─ _PowerSword--DST/
├─ _Ordinary--DST/                普通系列：仅实际使用的运行资源
│  ├─ modmain.lua、modinfo.lua
│  ├─ scripts/                   prefab、组件、配置与游戏文案
│  ├─ anim/                      游戏使用的动画ZIP，必须跟踪
│  ├─ images/、bigportraits/      游戏使用的TEX/XML
│  └─ sound/                     游戏使用的FEV/FSB（以后接入时）
├─ assets/
│  ├─ mod_art/                   现有已采用的公共图标/边框源素材
│  ├─ ordinary_series/           现有帽子/头环批准源图与挂点，保持路径
│  └─ characters/                已建立：角色源素材统一入口
│     └─ blue_boy/               蓝发少年；与显示名称“蓝本”解耦
│        ├─ README.md            当前基准、来源、使用和验证状态
│        ├─ manifest.json        唯一素材清单与SHA256
│        ├─ originals/           用户提供的原始底盘等，不覆盖原文件
│        ├─ art/
│        │  ├─ head/source.zip   当前头底/表情/头发/帽下/狼尾/既有骨相
│        │  ├─ body/source.zip   当前四色服装；先保留原有107张
│        │  ├─ ghost/           以后采用的幽灵素材，当前没有合格成品
│        │  └─ ui/              以后采用的头像、选角、名字图等
│        ├─ registration/        符号索引、原生挂点、方向和层序映射
│        └─ audio/              以后采用的声音源与FMOD工程
│           ├─ wav/
│           ├─ roomcar_blueprint_voice.fdp
│           └─ events.json
├─ tools/
│  ├─ deploy_bigbag.py           既有工具保持
│  ├─ mod_art/                   既有生产构建工具保持
│  ├─ ordinary_series/           现有普通系列构建/验证保持
│  └─ characters/blue_boy/       已建立：实际保留的音频/验证工具
├─ tests/                        现有bigbag、expedition、godhat、ordinary保持
├─ docs/
│  ├─ repository-layout.md       本文
│  └─ ordinary/                 当前范围、接口、简明材料清单和验收状态
├─ .gitignore
└─ README.md、LICENSE等既有文件
```

现有六个Mod根目录不统一改名，也不整体搬入新`mods/`目录。这样不会因整理而改变现有部署、构建和测试路径。

当前普通系列的28项成品/源素材/工具/测试/忽略配置应保留。已跟踪的神谕素材、背包测试等既有成果也全部保持。

角色的`head`中包含已经做好的雷击头部、骨相刘海与骨相狼尾；不再另造一套“雷击新版”取代它们。`manifest.json`用用途字段关联雷击资源，避免同一分件在多个目录里各存一份可编辑版本。旧版全身雷击审阅图作为验证证据放在外部`review`，不能误把其中用于参照的官方身体当成自制角色源图。

SVG、人工完成/已确认的无损PNG以及当前不能完全一致重建的PNG都属于应保全源素材。能够从既定源文件无差异重建的中间PNG、图集和临时TEX才放到外部`build`。迁移前不能仅看扩展名删PNG或ZIP：Mod的动画ZIP必须保留，重复下载打包ZIP则应归档。

`registration`与`manifest`均使用仓库相对路径。绝对旧路径只用于来源记录，不能成为正式构建的唯一依赖。来源、内容确认、编译结果、游戏内验证分别记录，不把“编译通过”写成“用户已确认”。

## 仓库外放什么

```text
Roomcar-DS-mods-workbench/
├─ README.md                     分工、入口与归档规则
├─ workspace.json                本机仓库/工作目录路径
├─ incoming/                     新收到、尚未分类的文件，保留原名与来源
├─ drafts/
│  └─ ordinary/blue_boy/
│     ├─ art/                    未确认的新图稿
│     └─ voice/                  A/B试作、C选定方向的待验收制作
├─ archive/
│  └─ ordinary/blue_boy/
│     ├─ versions/               旧版本源、预览、脚本、元数据作为整组保留
│     └─ rejected/               明确被否定的稿件，禁止当成当前基准
├─ reference/
│  ├─ game/                     官方原始资源抽取/反编译/分件考察
│  ├─ mods/                     其他Mod角色参考，记录来源
│  └─ art/                      造型参考、比较输入、概念图
├─ build/
│  ├─ mod_art/                  可重建中间文件与缓存
│  ├─ ordinary_series/
│  └─ blue_boy/
├─ review/
│  └─ ordinary/
│     ├─ items/                 帽子/头环的截图、逐帧和测试产物
│     └─ blue_boy/              无损审阅图、压缩预览、动画和详细检查日志
├─ records/
│  ├─ conversations/            原始会话JSONL及带过程导出
│  ├─ investigations/           大型源码摘录、枚举报告、一次性研究脚本
│  └─ migrations/               每次整理的原路径→新路径→哈希→状态清单
└─ backups/
   └─ migrations/               搬迁前可恢复快照；不当作日常素材入口
```

外部目录不是垃圾桶。`archive`和`backups`保留不可替代历史；`reference`保存参考；只有确定可重建且无独有内容的`build`才可以按需重建。没有自动删除策略。

## 已执行的归位规则

|现有位置|归位规则|
|---|---|
|`_Ordinary--DST/`、`assets/ordinary_series/`、`tools/ordinary_series/`、`tests/ordinary/`|原位保留|
|已跟踪的其他Mod、`assets/mod_art/`、现有测试/工具|原位保留|
|`assets/blue_boy_head/concepts/`、`svg_v1/`、`svg_redraw_front/`|整组进入外部`archive/ordinary/blue_boy/versions/`，保留原版本名与来源|
|`assets/blue_boy_head/user_base_v6/`|先保全整组旧版本；用户原稿、当前仍在用的表情/挂点与最新来源核对后收入仓库唯一角色目录，不把旧包全部当作最新版本|
|上一会话的最新狼尾头部、旧版雷击、四色服装|作为必须保全的原有基准；先复制并核验，再从中建立仓库当前源清单；不重画、不改变比例、挂点、路径内容|
|`output/character-art/blue-boy-heads/`|293项先整体保全到外部历史目录并核验；之后按内容索引到`reference`或`review`，不凭扩展名批量丢弃|
|`tools/character_art/`|早期生成/重绘工具随版本留档；只有确认用于当前构建的工具才整理进入仓库`tools/characters/blue_boy/`|
|`assets/blueprint_voice/prototype_v1/`|完整保留到外部`drafts/.../voice/`。整套仍是A；C只确定了音色方向，不把A或后续C成品自动当成验收通过|
|`tools/character_audio/`|整理为唯一实际使用的音频生成入口；重复旧脚本随声音试作留档|
|`docs/ordinary/basic-character-audit/`|简明材料/状态说明留仓库；大型原生源码摘录、全量调用枚举移外部`records/investigations/`；必要的紧凑映射可随正式构建保留|
|已暂停的技能设计和目录|完整移外部`archive/.../versions/`的设计记录；仓库当前范围文档只保留“技能暂停”的状态说明|
|本会话被否定的服装、雷击、鬼魂候选|原封进入外部`archive/.../rejected/`，明确禁止作为素材来源；声音方向状态单列，不能被美术稿标记隐式批准|
|会话JSONL、完整对话、详细工具执行记录|外部`records/conversations/`，仓库只留简短交接与材料索引|
|现有`output/mod-art/`、`output/ordinary-series/`等|先修改并验证工具的输出参数，再迁往外部`build`/`review`，不会先搬空导致构建失效|

文件命名遵循：生产路径使用稳定功能名，沿用引擎的符号、帧索引及既有文件名；不要在当前源目录堆叠`final/final2/最新版/v3`。版本用Git记录。外部每批历史记录使用`YYYY-MM-DD-简短描述`，例如`2026-10-27-rejected-materials`，并在内部保留原来的目录结构。来源文件名可以保留中文，避免无意义批量改名。

## 迁移如何保证不丢东西

1. 迁移前重新读取Git状态，记录待处理文件的完整路径、大小、SHA256，保留当时的忽略/暂存状态。上次的954项清单是依据，不代表将来的实时状态。
2. 先复制至确定的新路径；核验文件数量和逐文件哈希。文件名冲突立即停该项，不覆盖、不用“同名”判断相同。
3. 用户原稿、最新头部、旧版雷击、107张服装、表情、挂点、层序数据、构建依赖必须进入保全清单；仅在唯一来源已确认后标明哪份是当前源。
4. 更新实际使用的路径引用，执行针对性的构建/加载检查。外部目录可由本机参数或`ROOMCAR_WORKBENCH`环境变量指定，默认取仓库同级目录。普通系列构建、图标工具和角色声音工具已支持此参数；验证构建可单独指定输出目录。
5. 只有副本哈希一致、依赖已处理的条目才可移除旧位置；记录可回退的迁移清单。本次仅在归档副本核验一致、当前源和工具验证完成后移除仓库里的旧位置；上一会话与本会话原始交付路径保留，避免破坏历史链接。
6. 不使用`git clean`、`reset --hard`或全选删除/提交来缩小变化数。按普通系列、角色源、工具/文档等实际成果分组；本次整理不提交Git。

迁移是目录与来源治理，不授权重画或修改任何既有成品。发现缺件时先核实旧资源与实际动画用途，再在外部`drafts`准备补充内容。

## 忽略规则与图片规则

保留Mod运行ZIP的明确白名单。工具输出已改为外部路径；旧output已核验归档，仓库`/output/`统一忽略。保留Python缓存及明确的本机配置忽略；不使用全局`*.png`/`*.wav`忽略掩盖源材料。

生产源图、审核原图维持原尺寸和无损。查看前在外部`review`生成约200KB以内的压缩预览，压缩版不回流覆盖生产文件；动作比较采用同画布、同挂点、同缩放，不逐图居中伪造一致性。

## 2026-10-28：无损WebP与关联图像包

仓库工作区的全部PNG已转为无损WebP；PNG原件保留在外部转换前快照。角色头部、角色服装、帽子图层、模组图标图层分别打包，SVG保持原字节。每包上限32,000,000字节。当前入口以ZIP成员索引为准，上文关于原SVG/PNG来源的描述属于保全来源说明。

源文件读取使用tools/asset_io.py，编辑提取/候选打包/完整核验使用tools/image_packages.py。现有运行TEX、XML和动画ZIP不替换编码；原版符号名如wx78.png属于引擎资源标识，不是仓库PNG文件，不改名。

生产构建若需要PNG，只在仓库外的build目录临时生成。与角色内容无关的独立Mod预览图以单个WebP保留。所有关联素材包在.gitignore中有明确白名单。
