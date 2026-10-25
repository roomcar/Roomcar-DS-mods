local require = GLOBAL.require

print("Loading Oracle Series mod...")

--------------------------------------------------------------------------------------------------------------------------
-- [Prefab Files]

PrefabFiles = {
    "spider_god",
    "spider_god_bone",
    "godhat",
}

--------------------------------------------------------------------------------------------------------------------------
-- [Assets]

Assets =
{
    Asset("ANIM", "anim/player_channelcast_oh_basic.zip"),
    Asset("ATLAS", "images/oracle_container_bg_nine.xml"),
    Asset("IMAGE", "images/oracle_container_bg.tex"),
    Asset("ANIM", "anim/hat_ruins.zip"),
    Asset("ANIM", "anim/roomcar_godhat_oracle.zip"),
    -- Asset("ANIM", "anim/hat_winter.zip"),
    -- Asset("ATLAS", "images/inventoryimages.xml"),
    Asset("IMAGE", "images/inventoryimages.tex"),
    Asset("ATLAS", "images/inventoryimages/godhat.xml"),
    -- Asset("IMAGE", "minimap/minimap_atlas.tex"),
    -- Asset("ATLAS", "minimap/minimap_data.xml"),
}

--------------------------------------------------------------------------------------------------------------------------
-- [TUNING]

TUNING.ROOMCAR_GODHAT_LANG = GetModConfigData("LANG")
TUNING.ROOMCAR_GODHAT_GIVE = GetModConfigData("GIVE")
TUNING.ROOMCAR_GODHAT_LIGHT = GetModConfigData("LIGHT")
TUNING.ROOMCAR_GODHAT_RECIPE = GetModConfigData("RECIPE")
TUNING.ROOMCAR_GODHAT_PUNISH = GetModConfigData("PUNISH")
TUNING.ROOMCAR_GODHAT_WALKSPEED = GetModConfigData("WALKSPEED")

--------------------------------------------------------------------------------------------------------------------------
-- [Miniap Icon]

-- AddMinimapAtlas("minimap/godhat.xml")

-- AddMinimapAtlas("minimap/minimap_data.xml")

--------------------------------------------------------------------------------------------------------------------------
-- [Global Strings]

local Ingredient = GLOBAL.Ingredient

--------------------------------------------------------------------------------------------------------------------------
-- [Custom Recipe]

local rcp
local tec = GLOBAL.TECH.SCIENCE_TWO
local RcpType = TUNING.ROOMCAR_GODHAT_RECIPE

local RcpVC = {Ingredient("cutgrass", 1)}
local RcpC = {Ingredient("goldnugget", 5)}
local RcpN = {Ingredient("goldnugget", 10), Ingredient("nightmarefuel", 5)}
local RcpE = {Ingredient("purplegem", 2), Ingredient("goldnugget", 10), Ingredient("nightmarefuel", 10)}
local RcpVE = {Ingredient("purplegem", 6), Ingredient("goldnugget", 50), Ingredient("nightmarefuel", 20)}

rcp = RcpN -- Safe default for older worlds with missing configuration.

if RcpType == 1 then
    rcp = RcpVC
    tec = GLOBAL.TECH.NONE
elseif  RcpType == 2 then
    rcp = RcpC
    tec = GLOBAL.TECH.SCIENCE_ONE
elseif  RcpType == 3 then
    rcp = RcpN
    tec = GLOBAL.TECH.SCIENCE_TWO
elseif  RcpType == 4 then
    rcp = RcpE
    tec = GLOBAL.TECH.MAGIC_ONE
elseif  RcpType == 5 then
    rcp = RcpVE
    tec = GLOBAL.TECH.MAGIC_TWO
end

AddRecipe2("godhat", rcp, tec, {
    atlas = "images/inventoryimages/godhat.xml", image = "godhat.tex",
}, {"CLOTHING", "ARMOUR", "MAGIC"})
AddRecipe2("spider_god_bone", rcp, tec, {
    atlas = "images/inventoryimages/oracle_scepter.xml", image = "spider_god_bone.tex",
}, {"TOOLS", "MAGIC"})

require("oracle_strings").Apply()
local containers = require("containers")
containers.params.spider_god = GLOBAL.deepcopy(containers.params.shadowchester)
containers.params.spider_god.widget.oracle_equipment = true
local Containment = require("oraclecontainment")
containers.params.spider_god.itemtestfn = function(container, item) return not Containment.WouldCycle(container.inst, item) end
AddComponentPostInit("container", Containment.WrapContainer)


AddModRPCHandler("RoomcarOracle", "Equipment", function(player, guid, index, removeonly)
    if type(guid) ~= "number" or type(index) ~= "number" then return end
    local guard = GLOBAL.Ents[guid]
    require("oraclesentinel_equipment").HandleClick(player, guard, index, removeonly == true)
end)

AddModRPCHandler("RoomcarOracle", "Colour", function(player, guid)
    if type(guid) ~= "number" then return end
    require("oraclecolours").HandleClick(player, GLOBAL.Ents[guid])
end)
AddPlayerPostInit(function(inst)
    if not GLOBAL.TheWorld.ismastersim then return end
    local oldload=inst.OnLoad
    inst.OnLoad=function(player,data,...)
        if oldload~=nil then oldload(player,data,...)end
        Containment.RegisterMigrationPets(player)
    end
end)

if not GLOBAL.TheNet:IsDedicated() then
    AddClassPostConstruct("widgets/itemtile", require("oraclecolours").AttachTile)
    AddClassPostConstruct("widgets/containerwidget", function(self)
        local oldopen, oldclose = self.Open, self.Close
        self.Close = function(widget, ...)
            if widget.oracle_container_background ~= nil then
                widget.oracle_container_background:Kill()
                widget.oracle_container_background = nil
            end
            if widget.oracle_equipment_panel ~= nil then
                widget.oracle_equipment_panel:Kill()
                widget.oracle_equipment_panel = nil
            end
            return oldclose(widget, ...)
        end
        self.Open = function(widget, container, doer, ...)
            if widget._oracle_native_background_hidden then
                widget.bganim:Show()
                widget._oracle_native_background_hidden = nil
            end
            oldopen(widget, container, doer, ...)
            if widget.isopen and container.prefab == "spider_god" then
                widget.bganim:Hide()
                widget.bgimage:Hide()
                widget._oracle_native_background_hidden = true
                local Background = require("widgets/oraclecontainerpanel")
                widget.oracle_container_background = widget:AddChild(Background())
                -- Five equally spaced rows: 12 storage slots plus 3 equipment
                -- buttons. The atlas is cropped for this exact 1:1 layout.
                widget.oracle_container_background:SetSize(256, 398)
                widget.oracle_container_background:SetPosition(0, -37.5, 0)
                widget.oracle_container_background:SetClickable(false)
                widget.oracle_container_background:MoveToBack()
                local Panel = require("widgets/oracleequipmentpanel")
                widget.oracle_equipment_panel = widget:AddChild(Panel(widget.owner, container,
                    function(guid, index, removeonly)
                        SendModRPCToServer(MOD_RPC.RoomcarOracle.Equipment, guid, index, removeonly)
                    end, function(guid)
                        SendModRPCToServer(MOD_RPC.RoomcarOracle.Colour, guid)
                    end))
                for i, button in ipairs(widget.oracle_equipment_panel.buttons) do
                    if widget.inv[9 + i] ~= nil then
                        widget.inv[9 + i]:SetFocusChangeDir(GLOBAL.MOVE_DOWN, button)
                        button:SetFocusChangeDir(GLOBAL.MOVE_UP, widget.inv[9 + i])
                    end
                end
                local colour=widget.oracle_equipment_panel.colourbutton
                colour:SetFocusChangeDir(GLOBAL.MOVE_DOWN, widget.inv[3])
                widget.inv[3]:SetFocusChangeDir(GLOBAL.MOVE_UP, colour)
            end
        end
    end)
end

print("Oracle Series mod DONE")

AddPlayerPostInit(require("godhatvisuals").Attach)
AddMinimapAtlas("minimap/godhat.xml")

require("oracleperformance").Install(AddStategraphPostInit)
AddPlayerPostInit(require("oracleeffects").AttachPlayer)
