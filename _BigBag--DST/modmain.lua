local G = GLOBAL
local containers = G.require("containers")

PrefabFiles = { "bigbag" }
Assets = {
    Asset("ANIM", "anim/swap_bigbag.zip"),
    Asset("ATLAS", "images/inventoryimages/bigbag.xml"),
    Asset("IMAGE", "images/inventoryimages/bigbag.tex"),
    Asset("ATLAS", "images/bigbagbg.xml"),
    Asset("IMAGE", "images/bigbagbg.tex"),
    Asset("ATLAS", "minimap/bigbag.xml"),
    Asset("IMAGE", "minimap/bigbag.tex"),
}

local defaults = {
    LANG = 0, GIVE = false, STACK = false, FRESH = false, REPAIR = true,
    LIGHT = false, RECIPE = 3, WALKSPEED = .75, UI_SCALE = .8,
    UI_X = 0, UI_Y = 0, AUTOHIDE = true, UI_DRAG_KEY = 1,
}
local config = {}
for key, default in pairs(defaults) do
    local value = GetModConfigData(key)
    if value == nil then value = default end
    config[key] = value
end
G.TUNING.ROOMCAR_BIGBAG = config
G.TUNING.ROOMCAR_BIGBAG_LANG = config.LANG
modimport("strings.lua")

AddMinimapAtlas("minimap/bigbag.xml")
RegisterInventoryItemAtlas("images/inventoryimages/bigbag.xml", "bigbag.tex")

local Ingredient = G.Ingredient
local recipes = {
    { { Ingredient("cutgrass", 1) }, G.TECH.NONE },
    { { Ingredient("pigskin", 5) }, G.TECH.SCIENCE_ONE },
    { { Ingredient("goldnugget", 10), Ingredient("pigskin", 10) }, G.TECH.SCIENCE_TWO },
    { { Ingredient("goldnugget", 20), Ingredient("pigskin", 10), Ingredient("nightmarefuel", 5) }, G.TECH.MAGIC_ONE },
    { { Ingredient("goldnugget", 40), Ingredient("pigskin", 10), Ingredient("nightmarefuel", 20) }, G.TECH.MAGIC_TWO },
}
local recipe = recipes[config.RECIPE] or recipes[3]
if config.FRESH and config.STACK then
    table.insert(recipe[1], Ingredient("purplegem", 1))
end
AddRecipe2("bigbag", recipe[1], recipe[2], {
    atlas = "images/inventoryimages/bigbag.xml", image = "bigbag.tex",
}, { "CLOTHING", "CONTAINERS" })

-- Register just our container; do not replace the global widgetsetup function.
-- Keep all 64 slots and their original indices for existing saves.
local params = {
    widget = {
        slotpos = {}, bgatlas = "images/bigbagbg.xml", bgimage = "bigbagbg.tex",
        pos = G.Vector3(-170 + config.UI_X, -40 + config.UI_Y, 0),
        buttoninfo = {
            text = config.LANG == 1 and "整理" or "Sort",
            position = G.Vector3(-100, -310, 0),
            fn = function(inst, doer)
                if G.TheWorld.ismastersim then
                    if inst.components.container:IsOpenedBy(doer) then
                        G.require("bigbag_util").Sort(inst)
                    end
                else
                    G.SendModRPCToServer(G.GetModRPC("roomcar_bigbag", "sort"), inst)
                end
            end,
        },
    },
    issidewidget = true, type = "pack", openlimit = 1,
    itemtestfn = function(container, item)
        return not item:HasTag("bigbag")
    end,
}
for column = 0, 7 do
    for row = 0, 7 do
        table.insert(params.widget.slotpos, G.Vector3(column * 66 - 231, row * 66 - 231, 0))
    end
end
containers.params.bigbag = params
containers.MAXITEMSLOTS = math.max(containers.MAXITEMSLOTS, 64)

AddModRPCHandler("roomcar_bigbag", "sort", function(player, inst)
    if player == nil or player:HasTag("playerghost") or player:HasTag("busy")
        or inst == nil or not inst:IsValid() or inst.prefab ~= "bigbag"
        or inst.components.container == nil or not inst.components.container:IsOpenedBy(player) then
        return
    end
    local now = G.GetTime()
    if inst._bigbag_lastsort ~= nil and now - inst._bigbag_lastsort < .5 then return end
    inst._bigbag_lastsort = now
    G.require("bigbag_util").Sort(inst)
end)

modimport("scripts/bigbag_crafting.lua")
if not G.TheNet:IsDedicated() then
    modimport("scripts/bigbag_ui.lua")
end
