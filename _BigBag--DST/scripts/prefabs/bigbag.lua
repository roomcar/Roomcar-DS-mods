local util = require("bigbag_util")
local config = TUNING.ROOMCAR_BIGBAG
local assets = {
    Asset("ANIM", "anim/backpack.zip"),
    Asset("ANIM", "anim/swap_bigbag.zip"),
    Asset("ATLAS", "images/inventoryimages/bigbag.xml"),
    Asset("IMAGE", "images/inventoryimages/bigbag.tex"),
}

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_body", "swap_bigbag", "swap_body")
    if inst.Light ~= nil then inst.Light:Enable(true) end
    inst.components.container:Open(owner)
    util.RefreshContents(inst)
    owner:PushEvent("refreshcrafting")
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
    owner.AnimState:ClearOverrideSymbol("backpack")
    if inst.Light ~= nil then inst.Light:Enable(false) end
    inst.components.container:Close()
    owner:PushEvent("refreshcrafting")
end

local function onputininventory(inst)
    -- A carried spare bag must not leave its old container panel open.
    if not inst.components.equippable:IsEquipped() then
        inst.components.container:Close()
    end
end

local function ondropped(inst)
    inst.components.container:Close()
    if inst.Light ~= nil then inst.Light:Enable(false) end
end

local function onitemget(inst, data)
    -- Defer past GiveItem/OnLoad so stack size and saved item data are final.
    -- Coalesce multiple insertions, including sorting, into one task.
    if not inst._bigbag_sorting and inst._refresh_task == nil and (config.FRESH or config.STACK) then
        inst._refresh_task = inst:DoTaskInTime(0, function()
            inst._refresh_task = nil
            util.RefreshContents(inst)
        end)
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()
    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("backpack1")
    inst.AnimState:SetBuild("swap_bigbag")
    inst.AnimState:PlayAnimation("anim")
    inst.MiniMapEntity:SetIcon("bigbag.tex")
    inst:AddTag("backpack")
    inst:AddTag("bigbag")
    inst:AddTag("fridge")
    inst:AddTag("nocool")
    inst:AddTag("umbrella")
    inst.foleysound = "dontstarve/movement/foley/krampuspack"

    if config.LIGHT then
        inst.entity:AddLight()
        inst.Light:Enable(false)
        inst.Light:SetRadius(.25)
        inst.Light:SetFalloff(.5)
        inst.Light:SetIntensity(.25)
        inst.Light:SetColour(1, 1, 1)
    end
    MakeInventoryFloatable(inst, "small", .2, nil, nil, nil, { bank = "backpack1", anim = "anim" })
    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/bigbag.xml"
    inst.components.inventoryitem.cangoincontainer = true
    inst.components.inventoryitem:SetOnPutInInventoryFn(onputininventory)
    inst.components.inventoryitem:SetOnDroppedFn(ondropped)

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BACK or EQUIPSLOTS.BODY
    inst.components.equippable.walkspeedmult = config.WALKSPEED
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable:SetOnEquipToModel(function() inst.components.container:Close() end)

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("bigbag")
    inst.components.container.onopenfn = util.RefreshContents
    inst.components.container.onclosefn = util.RefreshContents
    inst:ListenForEvent("itemget", onitemget)

    if config.FRESH then
        -- Explicit continuous preservation, even while the UI is collapsed.
        inst:AddComponent("preserver")
        inst.components.preserver:SetPerishRateMultiplier(0)
    end
    -- Container and inventoryitem keep the game's normal save/load behaviour.
    -- No custom slot serialization, stack conversion, or item destruction.
    return inst
end

return Prefab("bigbag", fn, assets)
