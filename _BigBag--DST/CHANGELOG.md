# 1.7.1 — 2026-10-24

## r14：经典与新版大背包制作互换

- 在容器/服装制作分类新增“大背包：改为新版”和“大背包：改为经典”，各消耗相反款式背包1个，不额外收费、无需科技；原有基础材料配方保留。
- 使用原生容器制作规则：先卸下包；包内物品消耗前掉落地面，产出新包，名称与颜色不继承。配方简介明确提示，不做物品或名字迁移。
- 制造补料明确排除这两条配方，必须实际提供来源包；不新增面板按钮、热键或物品操作，不改变打开/关闭。
- 远行包仍为猪皮4、蜘蛛丝8、绳索4、二本科技。
- 64项回归、41项Lua语法检查通过，含原生Builder.RemoveIngredients及Container.DropEverything的64格/超量堆叠落地路径。渲染、输入和游戏内制作仍需验收，未上传Steam。

## r13：紧凑边距、可见分区框、外观比例

- 三种侧栏均使用原版底板完整九宫格切片，经典可见544×544、新版544×632、远行288×696；紧贴格子/标题/按钮收窄留白。原版格子尺寸、槽位、颜色、存档保持不变。
- 远行包维持四列八行，在六个分区边界留约4像素窄缝；边框在普通格子外侧，不再被完全遮住；放大格子仍绘制在框线上方。整合布局同步增加远行包格间距，保持12+20和原生导航，三个包整合背板边距缩紧。
- 新版大背包背负帧仅压短下半深色部分约30%，保留上盖、肩部锚点；背面/侧面与相关背带部件配套调整。
- 新版大背包落地帧放大20%，远行包放大28%，保留地面接触阴影及接触点；不对整个人物或物品实体统一缩放。
- 61项回归、41个Lua语法检查通过；官方贴图编译、帧号/时长/背负锚点、地面接触点和离线原生动画/布局核对完成。仍需游戏内验收，未上传Steam。

## r12：颜色标记移到切色按钮

- 远行包和新版大背包的当前颜色色条放到切换颜色按钮内部上沿，移除名称旁的色条；保留颜色名称，色条不拦截点击，随按钮收起/展开。
- 不改动颜色、外观、存档及整合布局。

## r11：原版底板完整切片、灰白远行包普通背带

- 底板使用未修改的原版bigbagbg.tex，改为0/56/540/596完整区域九宫格切片，保留原角部及透明羽化；可见尺寸补偿20像素透明外沿。撤回重绘底板，未新增替代背景纹理。
- 远行包采用用户参考的灰白圆顶双肩包、前置拉链袋，无商标/标签；简化为平涂底色及少量灰色阴影，不使用概念图式分面上色。
- 按原版普通背包的swap_body原生12帧制作：0–5独立背带，6–9包体，10侧面、13落地；背带不交叉，包体帧不融合背带。保留原生编号、时长、画布锚点及透明边距。
- 独立swap_roomcar_expeditionbag_gray build与灰白图标；不覆盖新版大背包已有外观。新远行包默认原色，已有颜色/名称/32格内容保留。
- 59项回归、41个Lua语法检查通过；贴图编译、色彩中性、像素往返、3张正面背带各两个独立部分及离线原生动画检查通过。尚待游戏内显示验收，未上传Steam。

## r10：分区框不再挡住放大格子

- 远行包侧栏、整合布局均将六色分区框放到格子和物品下层、背板上层，放大格子时允许格子覆盖分区线。
- 分区框及线条不拦截鼠标；保留原生鼠标/手柄放大效果、分类、位置、存档与r9功能。
- 58项回归、41个Lua语法检查通过；新增原生ItemSlot.Highlight/DeHighlight下侧栏/整合布局层级检查。实际渲染仍待游戏内验收。

## r9：完整背板、悬停命名与新版外观/颜色

- 新版大背包和远行包继续使用九宫格切片，背板分别扩为576×660、304×706，覆盖名称与底部控件；同步更新拖动/屏幕适配边界。
- 名称移除常驻的[命名]/[Rename]后缀，保留TextButton悬停高亮，增加点击重命名提示；收起后仍只显示展开按钮。
- 新版大背包采用此前远行包的14帧外观与物品栏/配方/小地图图标，增加五种颜色标记。原色为默认；背负、背带与落地外观随色变化，颜色写入独立color字段。
- 卸下新版包清理两个装备符号的颜色；兼容没有color字段的旧新版包，64格和Named原生记录无需转换；经典外观、颜色功能和存档行为保持原样。
- 远行包暂保留当前外观和原有颜色记录；灰白新外观尚未制作。不包含OC玩偶。
- 57项回归、41个Lua语法检查通过；尚待游戏内外观/悬停/保存重载验收。

## r8：三种背包整合布局与九宫格底板

- 经典大背包与新版共用上方20+20、下方24的整合布局；只把背包格子缩为原尺寸80%，人物物品栏与装备栏不缩放。
- 远行包改为上方12格（原1–12，战斗/工具）、下方20格（原13–32），保留六色整区边框及原槽位编号/类别。侧栏仍4×8。
- 三种整合布局都保留原生InvSlot及手柄选取，横向不跳排、纵向可跨人物栏；适配小屏及HUD/手柄放大，分区边框同步更新。
- 使用原生NineSlice与原贴图九个UV切片；四角保持比例，边框厚度不被横纵拉扁，只延展中段。覆盖整合背景、新版/远行包侧栏；经典侧栏仍为原始正方形。
- 保留r6做菜展开/收起修复和r7远行包外观，不包含OC玩偶、不修改容器或存档格式。
- 51项自动回归、40个Lua语法检查通过，尚待游戏内实际显示及物理手柄验收。

## r7：远行包新外观合入测试

- 合入已制作的远行包独立14帧贴图、原生背带/背负/侧身/落地态及独立物品栏、制作栏、小地图图标。
- 独立build，不替换经典与新版大背包；保留32格、原生存档、名称和已选颜色。
- 保留r6做菜不自动隐藏和收起只留展开按钮的修复；不包含OC玩偶。

## r6：做菜时保持展开；收起仅留展开按钮

- 新版大背包与远行包检测到打开的 stewer 锅具时，不再因自动隐藏收起；覆盖侧栏和整合布局，也优先于同时打开的制作菜单/其他容器。
- 使用客户端可见的 stewer 标签，支持原生烹饪锅、便携烹饪锅及使用同标签的模组锅具；不改服务器容器或食材传输。
- 手动收起仍有效；收起时隐藏名称、整理、拖动改键、复位、颜色按钮、颜色标记、分区边框、格子和背景，仅保留展开按钮；展开时恢复。
- 经典大背包保持原样。存档、配方、物品规则及贴图不变；OC 玩偶候选不合入本次补丁。
- 44项自动回归、39个Lua语法检查通过。使用实际游戏 Lua UI/容器代码与模拟渲染、输入，尚待游戏内连续放食材和显示验收。

## r4：远行包紧凑布局及随身栏修复

- 远行包侧栏改为原尺寸4列×8行；两个6格区各2×3，三个4格区各4×1，材料区4×2。
- 六色整区边框取代常驻分类小字，保留空槽轮廓与悬停说明；按钮在底部紧凑两排。
- 修正cangoincontainer=false连人物随身栏一起拒绝的问题，改用cangoincontainer=true与canonlygoinpocket=true，允许随身携带，仍禁止塞进容器。
- 保持32个槽位顺序、内容、名称及颜色存档结构；撤下已无用途的旧UI缩放选项。
- 总40项自动回归、39个Lua语法检查通过，包含原生Inventory随身栏准入及32格旧记录往返。

## r4：新版整合布局40+24与手柄选格

- 新版第1–20格在最上排，21–40格在其下；人物物品栏/装备栏保持原位；41–64格回到原生第二行。
- 复用所有原生InvSlot、容器引用及槽位编号，不重新排序物品或存档数据。
- 手柄左右选择限制在当前排，上下沿用原生几何搜索，支持跨人物栏与背包排；隐藏内容时焦点回到人物栏。
- 小屏幕、HUD或手柄背包放大时，背包格子与背景等比适配，避免24格底排两端出界。经典与远行包的布局不变。
- 38项自动回归与38个Lua语法检查通过，包括原生CursorNav/GetClosestWidget下64格全部可达、跨排、行尾和缩放。物理手柄操作仍待作者实际验证。

## r3：背景可见性修复

- 修正r2底图透明留白缩入格子下方的问题；新增独立裁边图集复用原贴图，面板560×544，露出可见窄边。
- 格子、名称、四按钮的位置与大小不变；经典及远行包仍使用原图集。

## r2：作者实测后的调整

- 新版大背包格子恢复原版大小（.6），不再受UI_SCALE缩小；此大小选项只作用于远行包。
- 底图改成544×544正方形，只衬托格子；名称在上方，四个按钮紧靠下方并排，背景不覆盖名称/按钮。
- 新版大背包与远行包每次打开先展开；已打开的制作菜单不会使新面板立即折叠，后续打开菜单/容器仍按配置自动收起。
- 已核对作者测试世界FRESH/STACK/GIVE均关闭；配置关闭属于预期不返鲜，未擅自修改世界配置。
- 新增真实Container入包事件触发返鲜/补满回归，两种64格包均通过；总36项自动测试、37个Lua语法检查。
- 原生整合布局只有toprow与bottomrow，没有内置第三排。截图中的重叠问题保留为下一轮布局设计项；本轮没有重新排列整合布局。

## 中文

- 「大背包」按升级前 1.5.0 的 Git 记录恢复正方形底图、原始位置、缩放、8×8 格及原生整合布局；无额外按钮，固定 F1 移动侧栏。
- 新增「大背包-新版」，接续 1.7 的界面、命名、整理、收起、改键、复位与 16×4 整合布局；使用同等配方。
- 保留 `bigbag`、64 格顺序及原生容器 / 命名存档格式；现有 1.5 / 1.7 背包不替换实体、不转换内容。已有命名仍保留。
- 经典位置偏好独立保存；隔离旧隐藏状态；为非数值、无穷及无效缩放配置提供默认值。
- 新版大背包自动收起额外识别正常制作菜单，手动展开仍可临时覆盖自动收起。
- 远行包的布局、分类、命名、颜色和腐败规则不变；每次打开先展开，后续仍沿用既有自动收起检测。

验证：36 项自动回归通过；真实游戏 Lua 组件配合模拟渲染 / 输入。实际游戏画面、旧世界重载、物理手柄和多人尚未完成本轮验收。反馈原话为“显示错误”，没有证据确认是否 Lua 报错，也不宣称已定位所有显示异常。

## English

- Restored the original Big Bag's 1.5 square texture, scale, position, 8x8 grid and native integrated layout. Fixed F1 dragging; no extra buttons.
- Added Big Bag - New UI with the 1.7 controls and 16x4 integrated layout at the same crafting cost.
- Kept the original bigbag identity, 64 slot indices and native container/naming serialization. Existing contents and custom names require no conversion.
- Isolated classic local preferences and stale collapse state; validated numeric UI settings.
- New UI auto-hide now detects the normal crafting menu; Expedition Bag behaviour remains unchanged.

Validation: 36 automated checks using real game Lua implementations with mocked rendering/input. In-game visuals, real old-world reloads, physical controllers and multiplayer remain pending. The reported display issue has no confirmed Lua error or fully established root cause.

# 1.7.0 — 2026-10-22

## 中文

- 新增独立的 32 格远行包，包含六个收纳分区、空槽类别提示与五种颜色标记。
- 两款背包支持独立命名、F1–F9 拖动键切换、面板收起/展开与默认自动收起。
- 64 格大背包支持稳定整理，保留原物品身份、堆叠数量和旧版存储结构。
- 整理复制、保鲜、耐久修复、制造补料与微光配置；复制、保鲜、补料和微光默认关闭。
- 更新制作分类、默认配方说明与中英文介绍。大背包默认 0.75 倍移速；远行包保持正常移速、腐败与耐久。

已知未测范围：本次未重做多人联机实测；真实地表/洞穴往返、实体手柄输入和第三方堆叠/装备栏组合仍待验证。历史丢物、黑屏或断线反馈不宣称已全部解决。

## English

- Added a separate 32-slot Expedition Bag with six storage sections, empty-slot category hints and five saved colour markers.
- Both bags support individual names, F1–F9 drag-key selection, collapse/expand and automatic panel hiding.
- Added stable sorting for Big Bag while preserving item identities, stack quantities and the original 64-slot save structure.
- Clarified duplication, preservation, durability repair, crafting supplies and light options. Duplication, preservation, supplies and light are disabled by default.
- Updated crafting categories, recipe documentation and bilingual descriptions. Big Bag defaults to 0.75× movement speed; Expedition Bag uses normal speed, spoilage and durability.

Not revalidated for this release: multiplayer sessions, actual surface/cave travel, physical controller input and third-party stacking/equipment-slot combinations. This release does not claim to resolve every historical report of lost items, black screens or disconnects.
