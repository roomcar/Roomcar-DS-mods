--------------------------------------------------------------------------------------------------------------------------
name = " A Big Bag (大背包) 1.6"
author = "Roomcar"
version = "1.6.0-dev"
description = "64-slot backpack with compact UI, sorting and controller layout. Optional item duplication, preservation and crafting supplies.\n64格大背包：紧凑界面、整理、手柄布局。可选复制物品、持续保鲜、制造补料。\n堆满+保鲜同时开启时，配方额外需要1个紫宝石。"

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
		hover = "While equipped, crafting generates missing ordinary materials. Works for remote players and caves. Tech and character costs still apply. / 装备时制造自动补齐普通材料，支持客机和洞穴，不绕过科技和角色消耗。",
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
        name = "UI_SCALE",
        label = "Panel Size (侧栏大小)",
        hover = "Mouse side panel only. Storage stays at 64 slots. / 调整鼠标侧栏大小，容量始终64格。",
        options = {{description = "60%", data = .6}, {description = "80%", data = .8}, {description = "100%", data = 1}},
        default = .8,
    },
    {
        name = "UI_X",
        label = "Panel X (侧栏左右)",
        options = {{description = "Left / 左", data = -100}, {description = "Default / 默认", data = 0}, {description = "Right / 右", data = 60}},
        default = 0,
    },
    {
        name = "UI_Y",
        label = "Panel Y (侧栏上下)",
        options = {{description = "Down / 下", data = -80}, {description = "Default / 默认", data = 0}, {description = "Up / 上", data = 80}},
        default = 0,
    },
    {
        name = "AUTOHIDE",
        label = "Auto Hide Panel (自动收起)",
        hover = "Hide the bag panel while another container or cookbook is open. Contents remain available for crafting. / 打开其他容器或食谱时暂时收起，材料仍可用于制造。",
        options = {{description = "Off / 关", data = false}, {description = "On / 开", data = true}},
        default = true,
    },

}



--------------------------------------------------------------------------------------------------------------------------
