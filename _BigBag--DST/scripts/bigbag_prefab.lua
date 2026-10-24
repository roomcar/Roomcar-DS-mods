local util = require("bigbag_util")
local config = TUNING.ROOMCAR_BIGBAG
local color = require("bigbag_color")
local assets = {
    Asset("ANIM", "anim/backpack.zip"),
    Asset("ANIM", "anim/swap_bigbag.zip"),
    Asset("ATLAS", "images/inventoryimages/bigbag.xml"),
    Asset("IMAGE", "images/inventoryimages/bigbag.tex"),
}
local modernassets = {
    Asset("ANIM", "anim/backpack.zip"),
    Asset("ANIM", "anim/swap_roomcar_expeditionbag.zip"),
    Asset("ATLAS", "images/inventoryimages/roomcar_expeditionbag.xml"),
    Asset("IMAGE", "images/inventoryimages/roomcar_expeditionbag.tex"),
}

local function onequip(inst, owner)
    local modern=inst.roomcar_bagcolor~=nil
    local build=modern and "swap_roomcar_expeditionbag" or "swap_bigbag"
    owner.AnimState:OverrideSymbol("swap_body", build, "swap_body")
    if modern then
        owner.AnimState:OverrideSymbol("backpack",build,"backpack")
        color.Set(inst,inst.roomcar_bagcolor:value())
    end
    if inst.Light ~= nil then inst.Light:Enable(true) end
    inst.components.container:Open(owner)
    util.RefreshContents(inst)
    owner:PushEvent("refreshcrafting")
end

local function onunequip(inst, owner)
    if inst.roomcar_bagcolor~=nil then color.ClearOwner(owner) end
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

local function Make(prefab)
    local modern=prefab=="roomcar_bigbag_new"
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()
        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank("backpack1")
        inst.AnimState:SetBuild(modern and "swap_roomcar_expeditionbag" or "swap_bigbag")
        inst.AnimState:PlayAnimation("anim")
        inst.MiniMapEntity:SetIcon(modern and "roomcar_expeditionbag.tex" or "bigbag.tex")
        inst:AddTag("backpack")
        inst:AddTag("bigbag")
        inst:AddTag("fridge")
        inst:AddTag("nocool")
        inst:AddTag("umbrella")
        inst.foleysound = "dontstarve/movement/foley/krampuspack"
        if modern then color.Network(inst) end

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
        inst:AddComponent("named")
        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem:ChangeImageName(modern and "roomcar_expeditionbag" or "bigbag")
        inst.components.inventoryitem.atlasname = modern and "images/inventoryimages/roomcar_expeditionbag.xml" or "images/inventoryimages/bigbag.xml"
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
        inst.components.container:WidgetSetup(prefab)
        inst.components.container.onopenfn = util.RefreshContents
        inst.components.container.onclosefn = util.RefreshContents
        if modern then color.Server(inst,1) end
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

    return Prefab(prefab, fn, modern and modernassets or assets)
end
return Make
