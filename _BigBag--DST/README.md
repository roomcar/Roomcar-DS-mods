# A Big Bag 大背包 · DST

适用于《饥荒联机版》（Don't Starve Together）的 64 格背包 Mod，支持可选的复制补满、保鲜回鲜和制造补料功能。

仓库开发版本：**1.6.0-dev**。测试基线：DST **756039**（Steam build 25643519）。
仓库开发版本与 Steam 创意工坊发布版本可能不同。

## 使用

在制造菜单的「容器」「服装」或「模组」分类中找到大背包，也可搜索名称。
默认普通配方为金块 ×10、猪皮 ×10，需要二本科技。

| 难度 | 材料 | 科技 |
|---|---|---|
| 最易 | 草 ×1 | 无 |
| 容易 | 猪皮 ×5 | 一本 |
| 普通 | 金块 ×10、猪皮 ×10 | 二本 |
| 较难 | 金块 ×20、猪皮 ×10、噩梦燃料 ×5 | 一本魔法 |
| 更难 | 金块 ×40、猪皮 ×10、噩梦燃料 ×20 | 二本魔法 |

**复制补满与保鲜回鲜同时开启时，任何难度都额外需要紫宝石 ×1。**
配方难度在世界的服务器模组配置中选择。

容量固定为 64 格，支持携带多个，但大背包之间不能套娃。默认移速为 0.75 倍，可配置。
装备栏优先使用其他模组提供的 `BACK`，否则使用原版 `BODY`；原版没有独立背包栏。

## 配置与界面

- **复制补满（默认关）**：物品放入、开关或装备背包时复制至该物品的堆叠上限。不是合并已有物品。关闭不会撤回已经生成的数量，且永远不会把高于上限的现有数量减小。无限上限使用原有限定上限；没有有效有限上限时不复制。
- **保鲜回鲜（默认关）**：放入后恢复新鲜，留在包内时停止自然腐烂。不会把已经变成腐烂物的物品变回原食物，也不会抵消敌人直接替换物品的效果。关闭时保留旧版的冰箱标签行为。
- **修复耐久（默认开）**：需同时开启保鲜回鲜；恢复工具、护甲和燃料。可单独关闭，保留纯保鲜。
- **制造补料（默认关）**：装备背包时点击制造，服务器补齐缺少的普通材料，之后走原版制造流程。支持独立服务器与远程客户端的请求；科技、角色、技能、生命/理智等消耗仍按原版检查。只补缺额，不发放已有材料的完整一份。
- **微光（默认关）**：装备时发光，卸下或掉落时关闭。
- **侧栏大小/位置**：鼠标侧栏默认缩至旧版 80%，可改大小与横纵偏移；不改变存储槽数。
- **收起/展开**：只折叠面板，不关闭网络容器，包内材料仍可用于制造。原版右键开关仍是真正的容器开关。
- **自动收起（默认开）**：打开其他容器或食谱时暂时隐藏内容，关闭后恢复；期间手动展开会保持展开，直到本次其他容器/食谱操作结束。
- **整理**：按物品 prefab 分组，稳定排列同类物品；不合并堆叠，不修改耐久、皮肤或身份。通过服务器验证操作者，避免客户端直接改物品。
- **手柄/整合背包**：将原版 64 格单行改成 16×4 网格，沿用原版选格与物品操作。

保留旧版 `bigbag` 标识、64 个槽位和游戏原版容器保存结构，以兼容已有背包存档。支持掉落漂浮，并完善换包、卸下和掉落时的容器关闭逻辑。背包动画沿用本 Mod 原版资源。

## 给背包命名

装备背包后，点击鼠标侧栏顶部的「名称 [命名]」，输入新名字并保存，也可按回车确认。支持中文，最多 20 个 Unicode 字符；清空输入后保存恢复默认名称，取消不修改名称。

每只背包独立命名，名称显示在侧栏标题和原版物品提示中，并随背包同步、存档和转交。只有当前持有并打开背包的玩家可以改名，不能远程修改其他玩家持有的包。旧存档中的未命名背包继续显示默认名称。

命名入口目前在鼠标侧栏；使用整合背包或手柄布局时，可先切回侧栏命名，名称仍会保留。

## 拖动背包界面

鼠标移到背包侧栏上，**按住 F1 并移动鼠标**即可拖动，松开后自动保存位置，无需点击物品。

- 点击面板下方的「拖动 F1」按钮，可依次切换 **F1～F9 / 关闭**。世界配置提供初始按键，面板上的选择优先，仅影响本机玩家。
- 位置与按键保存在客户端，换包或重新进入游戏后仍保留，不写入背包物品或世界存档。
- 拖动时整个面板（包括底部按钮）会限制在屏幕内；重新打开、改变分辨率或 HUD 缩放时重新校正。屏幕空间不足时自动缩小。
- 点击「复位」恢复配置中的默认位置并展开背包。也可按 `~` 打开控制台，确认显示 **本地 / Local**，输入 `d_resetbigbagui()` 后回车。复位保留所选拖动键。
- 拖动适用于鼠标侧栏；手柄与整合背包仍使用底部 16×4 布局。

部分键盘需同时按住 `Fn` 才会向游戏发送 F1～F9；与其他 Mod 快捷键冲突时，可在面板切换按键。

## 开发与部署

需要 Python 3；运行回归测试还需要 Lua 5.1，以及与目标游戏版本对应的 DST Lua 源码。游戏源码不随本仓库分发，仅用于接口对照与测试。

以下命令均在仓库根目录执行。macOS 默认 Steam 安装位置可直接运行：

```sh
python3 tools/deploy_bigbag.py
```

其他平台或自定义安装位置需要指定目标目录：

```sh
python3 tools/deploy_bigbag.py --destination "/path/to/Don't Starve Together/mods/roomcar_bigbag_dev"
```

请将示例路径替换为实际游戏目录，目标目录名须为 `roomcar_bigbag_dev`。
脚本将本目录同步到开发版目录，保留已有的 `[DEV]` 显示名称；覆盖前自动备份到系统临时目录，并校验复制后的文件。备份位置会输出到终端。测试时只启用开发版，不与原版或其他大背包变体同时启用。

运行回归测试：

```sh
lua5.1 tests/bigbag/run.lua /path/to/DST-scripts
lua5.1 tests/bigbag/ui_position.lua /path/to/DST-scripts
lua5.1 tests/bigbag/naming.lua /path/to/DST-scripts
```

将 `/path/to/DST-scripts` 替换为游戏 Lua 源码目录，其下应包含 `class.lua` 和 `components/`。Lua 可执行文件在部分环境中名为 `lua`，请确认使用的是 5.1 版本。

回归测试使用官方 `Container`、`Stackable` 实现，验证数量不减少、无限上限、关闭可选功能、独立修复、64 格整理与存储、补料缺额和权限条件。
界面测试另外覆盖屏幕边界、缩放、保存位置、延迟读取与复位冲突、按键切换及面板清理。
此外提供以下游戏内测试脚本，仅用于独立测试世界；具体前置条件见脚本注释：

- [`engine.lua`](../tests/bigbag/engine.lua)：在服务器控制台执行，会生成测试物品和测试角色。
- [`client.lua`](../tests/bigbag/client.lua)：在远程客户端的本地控制台执行，验证面板、整理 RPC 和制造 RPC。
- [`client_naming.lua`](../tests/bigbag/client_naming.lua)：验证命名对话框回调、取消、清空复原、中文命名 RPC 和标题同步；会将测试背包命名为「矿石与工具」，供重启存档检查。
- [`client_drag.lua`](../tests/bigbag/client_drag.lua)：在本地控制台执行，使用真实 Widget 坐标与模拟按键/鼠标检查拖动、四边约束、HUD 缩放、点击拦截与手动展开。执行前后会复位位置。
- [`layout.lua`](../tests/bigbag/layout.lua)：临时检查整合布局与方向选格，并恢复原设置。

### 测试状态

以下结果对应上述开发版本与游戏测试基线，测试环境为 macOS、离线独立服务器及独立客户端：

| 检查 | 结果 |
|---|---|
| Lua 5.1 语法、9 项功能回归、6 项界面位置回归、4 项命名回归 | 通过 |
| 客户端拖动：四边约束、实际 HUD 缩放、点击拦截、手动展开 | 通过；使用真实 Widget 与模拟按键/指针 |
| 客户端按钮切换拖动键、本地偏好写入 | 通过 |
| 命名：真实窗口英文输入/回车，中文 RPC、取消、清空复原与标题同步 | 通过；中文流程使用对话框回调测试 |
| 命名：服务器及客户端重启后恢复中文名称 | 通过 |
| 独立服务器：64 格整理、物品身份、保鲜、换包/卸包关闭 | 通过 |
| 存盘并重启：第 64 格的 999 个草 | 数量和槽位保留 |
| 独立服务器：补缺少材料、建筑预制作 | 通过 |
| 独立客户端：64 格同步、收起后仍可读制造材料、食谱自动收起/恢复 | 通过 |
| 独立客户端：整理 RPC、制造 RPC 补料并产出火把 | 通过 |
| 客户端整合布局：16×4 格、跨行方向选格 | 通过；尚无实体手柄输入实测 |

## 兼容性与问题反馈

地表与洞穴之间的实际往返、实体手柄输入，以及第三方堆叠或装备栏 Mod 组合仍待验证。已有的物品丢失、黑屏和断线反馈尚未全部复现，当前测试结果不代表这些情况已全部解决。

反馈问题时，请提供游戏与 Mod 版本、Mod 配置、其他已启用的 Mod、复现步骤，以及相关的客户端或服务器日志。发布日志前，请检查并移除账号标识、服务器密码、令牌等私人信息。下载或订阅异常需与游戏内功能问题区分排查。

## English

64-slot backpack with a compact, collapsible side panel, stable sorting and a 16×4 integrated/controller layout. Point at the side panel and hold F1 while moving the mouse to reposition it. Cycle F1–F9/Off using the panel button; preferences are saved locally. The panel stays within the screen and adapts to smaller displays. Use Reset or the local console command `d_resetbigbagui()` to restore its position. Click the side panel title to name each bag (up to 20 Unicode characters); leave it blank to reset. Names sync to other players and are saved with the item. Find it under Containers, Clothing or Mods. Duplication, preservation and crafting supplies are optional and disabled by default. Repair is separately configurable when preservation is enabled. Duplication never reduces existing stacks. Both duplication and preservation enabled add one purple gem to the selected recipe.

## Links

- [Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=810443397)
- [Source repository](https://github.com/roomcar/Roomcar-DS-mods)
- Author: Roomcar
- License: GPL-3.0, see [LICENSE](LICENSE).
