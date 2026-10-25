name = "神谕系列 / Oracle Series"
author = "Roomcar"
version = "1.0.3"

description = "[Ver."..version.."]\n" .. [[
神谕头环、秘法杖与随行守卫。守卫含12格储物及手持、身体、头部装备栏。支持中英文与可调配置。
注意：卸下惩罚默认开启，可能致死；可在配置中关闭。

Oracle Circlet, Arcane Staff & Sentinel. Includes 12 storage slots and Hands/Body/Head equipment slots. Chinese/English support and configurable options.
Unequip penalty is ON by default and can be lethal. Disable it in settings if desired.
]]

api_version = 10
dst_compatible = true
all_clients_require_mod = true
client_only_mod = false
server_filter_tags = {"godhat-roomcar's mod", "roomcar", "godhat"}

forumthread = ""
icon_atlas = "godhaticon.xml"
icon = "godhaticon.tex"

priority = 0

configuration_options = {
    {
        name = "LANG",
        label = "Language / 语言",
        hover = "Choose the in-game display language. Auto follows your game language. / 选择游戏内显示语言，自动模式跟随游戏语言。",
        options = {
            { description = "Auto / 跟随游戏", data = -1 },
            { description = "English / 英语", data = 0 },
            { description = "Simplified Chinese / 简体中文", data = 1 },
        },
        default = -1,
    },
    {
        name = "RECIPE",
        label = "Recipe Cost / 制作成本",
        hover = "Adjust costs and technology for both the circlet and staff. Normal: 10 gold + 5 nightmare fuel each, Alchemy Engine. / 调整头环与秘法杖的耗材和科技；普通档每件10金块+5噩梦燃料，炼金引擎解锁。",
        options = {
            { description = "Very Cheap / 极低", data = 1 },
            { description = "Cheap / 较低", data = 2 },
            { description = "Normal / 普通", data = 3 },
            { description = "Expensive / 较高", data = 4 },
            { description = "Very Expensive / 极高", data = 5 },
        },
        default = 3,
    },
    {
        name = "WALKSPEED",
        label = "Movement Speed / 移动速度",
        hover = "Movement speed multiplier while wearing the Oracle Circlet. / 佩戴神谕头环时的移动速度倍率。",
        options = {
            { description = "1.25x / 1.25倍", data = 1.25 },
            { description = "1.5x / 1.5倍", data = 1.5 },
            { description = "2x / 2倍", data = 2 },
            { description = "2.5x / 2.5倍", data = 2.5 },
        },
        default = 1.5,
    },
    {
        name = "LIGHT",
        label = "Illumination / 照明",
        hover = "Let the equipped circlet illuminate its surroundings. Night vision works independently. / 佩戴头环时照亮周围，夜视独立生效。",
        options = {
            { description = "Off / 关", data = false },
            { description = "On / 开", data = true },
        },
        default = true,
    },
    {
        name = "GIVE",
        label = "Crafting Supplies / 制造补料",
        hover = "While wearing the circlet, a failed crafting attempt grants missing ordinary materials; try again afterwards. / 佩戴头环时，制作因普通材料不足而失败会补发所缺材料，之后请再次制作。",
        options = {
            { description = "Off / 关", data = false },
            { description = "On / 开", data = true },
        },
        default = true,
    },
    {
        name = "PUNISH",
        label = "Unequip Penalty / 卸下惩罚",
        hover = "Removing the circlet deducts 80% of max hunger/sanity and 50% of max health. Can be lethal. / 取下头环扣除最大饥饿、理智的80%及最大生命的50%，可能致死。",
        options = {
            { description = "Off / 关", data = false },
            { description = "On / 开", data = true },
        },
        default = true,
    },
}
