--------------------------------------------------------------------------------------------------------------------------
name = " A Big Bag 大背包 · 64 + 32"
author = "Roomcar"
version = "1.7.1"
description = "64-slot Big Bags with Classic and New UI variants, exchangeable through crafting, plus a 32-slot classified Expedition Bag. Hold F1 to move side panels. Improved integrated layouts with controller support. Big Bags offer optional duplication, preservation and crafting supplies; Expedition Bag follows normal rules.\n64格大背包，经典与新版界面任选，可通过制作互换；另有32格分类远行包。支持F1移动侧栏，优化整合模式界面，支持手柄。大背包可选复制补满、保鲜回鲜和制造补料；远行包保持正常规则。"

api_version = 10
dst_compatible = true
all_clients_require_mod = true
client_only_mod = false
server_filter_tags = {"bigbag-roomcar's mod", "roomcar", "bigbag"}

forumthread = ""
icon_atlas = "bigbagicon.xml"
icon = "bigbagicon.tex"

priority = 0

configuration_options = {
	{
		name = "LANG",
		label = "Language (语言)",
		hover = "Change display language.",
		options = {
			{ description = "English", data = 0, },
			{ description = "简体中文", data = 1, },
		},
		default = 0,
	},
	{
		name = "STACK",
		label = "Duplicate to Full Stack (复制补满)",
		hover = "Creates extra items up to the stack limit. Does not just merge stacks. Off does not undo created items. / 凭空复制至堆叠上限；关闭不会撤回已生成物品。",
		options = {
			{ description = "Off", data = false, },
			{ description = "On", data = true, },
		},
		default = false,
	},
	{
		name = "FRESH",
		label = "Preserve & Refresh (保鲜回鲜)",
		hover = "Restores freshness and stops spoilage inside the bag. Durability repair has its own switch. / 放入后回鲜并停止腐烂；耐久修复另设开关。",
		options = {
			{ description = "Off", data = false, },
			{ description = "On", data = true, },
		},
		default = false,
	},
	{
		name = "RECIPE",
		label = "Recipe (耗材)",
		hover = "Crafting cost and required technology. +1 purple gem when both duplication and preservation are on. / 复制补满与保鲜同时开启时额外需要1个紫宝石。",
		options = {
			{ description = "Very Cheap", data = 1, },
			{ description = "Cheap", data = 2, },
			{ description = "Normal", data = 3, },
			{ description = "Expensive", data = 4, },
			{ description = "More Expensive", data = 5, },
		},
		default = 3,
	},
	{
		name = "WALKSPEED",
		label = "Walk Speed (移速)",
		hover = "Walk speed while taking this bag.",
		options = {
			{ description = "Much Slower", data = 0.5, },
			{ description = "Slower", data = 0.75, },
			{ description = "No Change", data = 1, },
			{ description = "Faster", data = 1.25, },
			{ description = "Much Faster", data = 1.5, },
		},
		default = 0.75,
	},
	{
		name = "LIGHT",
		label = "Light (保命微光)",
		hover = "Let the bag give off light.",
		options = {
			{ description = "Off", data = false, },
			{ description = "On", data = true, },
		},
		default = false,
	},
	{
		name = "GIVE",
		label = "Crafting Supplies (制造补料)",
		hover = "While equipped, crafting generates missing ordinary materials. Supports remote clients. Tech and character costs still apply. / 装备时制造自动补齐普通材料，支持远程客户端，不绕过科技和角色消耗。",
		options = {
			{ description = "Off", data = false, },
			{ description = "On", data = true, },
		},
		default = false,
	},
    {
        name = "REPAIR",
        label = "Repair Durability (修复耐久)",
        hover = "With Preserve & Refresh enabled, also refill tools, fuel and armour. / 需开启保鲜回鲜；同时补满工具耐久、燃料和护甲。",
        options = {{description = "Off / 关", data = false}, {description = "On / 开", data = true}},
        default = true,
    },
    {
        name = "UI_DRAG_KEY",
        label = "Modern Drag Key (新版拖动键)",
        hover = "Point at the side panel, hold this key and move the mouse. New UI / Expedition only; classic always uses F1. / 仅新版大背包与远行包可改键；经典大背包固定F1。",
        options = {
            {description = "Off / 关", data = 0},
            {description = "F1", data = 1}, {description = "F2", data = 2},
            {description = "F3", data = 3}, {description = "F4", data = 4},
            {description = "F5", data = 5}, {description = "F6", data = 6},
            {description = "F7", data = 7}, {description = "F8", data = 8},
            {description = "F9", data = 9},
        },
        default = 1,
    },
    {
        name = "UI_X",
        label = "Modern Panel X (新版侧栏左右)",
        options = {{description = "Left / 左", data = -100}, {description = "Default / 默认", data = 0}, {description = "Right / 右", data = 60}},
        default = 0,
    },
    {
        name = "UI_Y",
        label = "Modern Panel Y (新版侧栏上下)",
        options = {{description = "Down / 下", data = -80}, {description = "Default / 默认", data = 0}, {description = "Up / 上", data = 80}},
        default = 0,
    },
    {
        name = "AUTOHIDE",
        label = "Modern Auto Hide (新版自动收起)",
        hover = "New UI / Expedition: auto-hide for other containers or cookbook; New UI also detects crafting. Stays open while a cooking pot is open. / 仅新版大背包与远行包；其他容器、烹饪书触发，新版额外识别制作菜单。打开锅具时保持展开，便于连续取食材。",
        options = {{description = "Off / 关", data = false}, {description = "On / 开", data = true}},
        default = true,
    },

}



--------------------------------------------------------------------------------------------------------------------------
