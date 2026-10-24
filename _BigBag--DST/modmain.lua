local G = GLOBAL
local containers = G.require("containers")

PrefabFiles = { "bigbag", "roomcar_bigbag_new", "roomcar_expeditionbag" }
Assets = {
    Asset("ANIM", "anim/swap_roomcar_expeditionbag_gray.zip"),
    Asset("ATLAS", "images/inventoryimages/roomcar_expeditionbag_gray.xml"),
    Asset("IMAGE", "images/inventoryimages/roomcar_expeditionbag_gray.tex"),
    Asset("ATLAS", "minimap/roomcar_expeditionbag_gray.xml"),
    Asset("IMAGE", "minimap/roomcar_expeditionbag_gray.tex"),
    Asset("ATLAS", "images/bigbagbg_nine.xml"),
    Asset("ANIM", "anim/swap_roomcar_expeditionbag.zip"),
    Asset("ATLAS", "images/inventoryimages/roomcar_expeditionbag.xml"),
    Asset("IMAGE", "images/inventoryimages/roomcar_expeditionbag.tex"),
    Asset("ATLAS", "minimap/roomcar_expeditionbag.xml"),
    Asset("IMAGE", "minimap/roomcar_expeditionbag.tex"),
    Asset("ANIM", "anim/swap_bigbag.zip"),
    Asset("ATLAS", "images/inventoryimages/bigbag.xml"),
    Asset("IMAGE", "images/inventoryimages/bigbag.tex"),
    Asset("ATLAS", "images/bigbagbg.xml"),
    Asset("ATLAS", "images/bigbagbg_compact.xml"),
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
-- Stale or hand-edited client/server options must not produce an invisible HUD.
for _, key in ipairs({ "UI_SCALE", "UI_X", "UI_Y", "UI_DRAG_KEY" }) do
    local value = config[key]
    if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge
        or (key == "UI_SCALE" and value <= 0)
        or (key == "UI_DRAG_KEY" and (value < 0 or value > 9 or value % 1 ~= 0)) then
        config[key] = defaults[key]
    end
end
G.TUNING.ROOMCAR_BIGBAG = config
G.TUNING.ROOMCAR_BIGBAG_LANG = config.LANG
modimport("strings.lua")

AddMinimapAtlas("minimap/bigbag.xml")
AddMinimapAtlas("minimap/roomcar_expeditionbag.xml")
AddMinimapAtlas("minimap/roomcar_expeditionbag_gray.xml")
RegisterInventoryItemAtlas("images/inventoryimages/roomcar_expeditionbag_gray.xml", "roomcar_expeditionbag_gray.tex")
RegisterInventoryItemAtlas("images/inventoryimages/roomcar_expeditionbag.xml", "roomcar_expeditionbag.tex")
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
-- The original identity, indices and native save format must never change.
containers.params.roomcar_bigbag_new = params
local classic = {
    widget = {
        slotpos = params.widget.slotpos,
        bgatlas = "images/bigbagbg.xml", bgimage = "bigbagbg.tex",
        pos = G.Vector3(-200, -60, 0),
    },
    issidewidget = true, type = "pack", openlimit = 1,
    itemtestfn = params.itemtestfn,
}
containers.params.bigbag = classic
AddRecipe2("roomcar_bigbag_new", recipe[1], recipe[2], {
    atlas = "images/inventoryimages/roomcar_expeditionbag.xml", image = "roomcar_expeditionbag.tex",
}, { "CLOTHING", "CONTAINERS" })
-- Alternative recipes keep both ordinary recipes intact. Native crafting
-- empties ingredient containers onto the ground before consuming the old bag.
AddRecipe2("roomcar_bigbag_to_new", { Ingredient("bigbag", 1) }, G.TECH.NONE, {
    product = "roomcar_bigbag_new", no_deconstruction = true,
    atlas = "images/inventoryimages/roomcar_expeditionbag.xml", image = "roomcar_expeditionbag.tex",
}, { "CLOTHING", "CONTAINERS" })
AddRecipe2("roomcar_bigbag_to_classic", { Ingredient("roomcar_bigbag_new", 1) }, G.TECH.NONE, {
    product = "bigbag", no_deconstruction = true,
    atlas = "images/inventoryimages/bigbag.xml", image = "bigbag.tex",
}, { "CLOTHING", "CONTAINERS" })
containers.MAXITEMSLOTS = math.max(containers.MAXITEMSLOTS, 64)

local expedition = G.require("expedition_data")
containers.params[expedition.PREFAB] = {
    widget = expedition.MakeWidget(-170 + config.UI_X, -40 + config.UI_Y),
    issidewidget = true, type = "pack", openlimit = 1, usespecificslotsforitems = true,
    itemtestfn = expedition.ItemTest, GetSpecificSlotForItem = expedition.FindSlot,
}
AddRecipe2(expedition.PREFAB, {
    Ingredient("pigskin", 4), Ingredient("silk", 8), Ingredient("rope", 4),
}, G.TECH.SCIENCE_TWO, {
    atlas = "images/inventoryimages/roomcar_expeditionbag_gray.xml", image = "roomcar_expeditionbag_gray.tex",
}, { "CLOTHING", "CONTAINERS" })
AddComponentPostInit("inventory", function(self)
    G.require("expedition_container").GuardEquipment(self)
end)
AddModRPCHandler("roomcar_bigbag", "color", function(player, inst)
    if not G.require("bigbag_naming").CanEdit(player, inst)
        or (inst.prefab ~= expedition.PREFAB and inst.prefab ~= "roomcar_bigbag_new")
        or inst.SetBagColor == nil or inst.roomcar_bagcolor == nil then return end
    local now = G.GetTime()
    if inst._lastcolor ~= nil and now - inst._lastcolor < .3 then return end
    inst._lastcolor = now
    inst:SetBagColor(inst.roomcar_bagcolor:value() % #expedition.colors + 1)
end)

AddModRPCHandler("roomcar_bigbag", "sort", function(player, inst)
    if player == nil or player:HasTag("playerghost") or player:HasTag("busy")
        or inst == nil or not inst:IsValid() or (inst.prefab ~= "bigbag" and inst.prefab ~= "roomcar_bigbag_new")
        or inst.components.container == nil or not inst.components.container:IsOpenedBy(player) then
        return
    end
    local now = G.GetTime()
    if inst._bigbag_lastsort ~= nil and now - inst._bigbag_lastsort < .5 then return end
    inst._bigbag_lastsort = now
    G.require("bigbag_util").Sort(inst)
end)

AddModRPCHandler("roomcar_bigbag", "rename", function(player, inst, text)
    G.require("bigbag_naming").Rename(player, inst, text)
end)

modimport("scripts/bigbag_crafting.lua")
if not G.TheNet:IsDedicated() then
    modimport("scripts/bigbag_ui.lua")
end
