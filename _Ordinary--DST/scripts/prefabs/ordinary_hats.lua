local defs = require("ordinary_definitions")
local atlas = "images/inventoryimages/ordinary_hats.xml"

local function onequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("headbase_hat")
    owner.AnimState:OverrideSymbol("swap_hat", inst.prefab, "swap_hat")
    owner.AnimState:Show("HAT")
    if inst:HasTag("open_top_hat") then
        owner.AnimState:Hide("HAIR_HAT")
        owner.AnimState:Show("HAIR_NOHAT")
        owner.AnimState:Show("HAIR")
        if owner.isplayer then
            owner.AnimState:Show("HEAD")
            owner.AnimState:Hide("HEAD_HAT")
            owner.AnimState:Hide("HEAD_HAT_NOHELM")
            owner.AnimState:Hide("HEAD_HAT_HELM")
        end
    else
        owner.AnimState:Show("HAIR_HAT")
        owner.AnimState:Hide("HAIR_NOHAT")
        owner.AnimState:Hide("HAIR")
        if owner.isplayer then
            owner.AnimState:Hide("HEAD")
            owner.AnimState:Show("HEAD_HAT")
            owner.AnimState:Show("HEAD_HAT_NOHELM")
            owner.AnimState:Hide("HEAD_HAT_HELM")
        end
    end
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_hat")
    owner.AnimState:ClearOverrideSymbol("headbase_hat")
    owner.AnimState:Hide("HAT")
    owner.AnimState:Hide("HAIR_HAT")
    owner.AnimState:Show("HAIR_NOHAT")
    owner.AnimState:Show("HAIR")
    if owner.isplayer then
        owner.AnimState:Show("HEAD")
        owner.AnimState:Hide("HEAD_HAT")
        owner.AnimState:Hide("HEAD_HAT_NOHELM")
        owner.AnimState:Hide("HEAD_HAT_HELM")
    end
end

local function makehat(def)
    local assets = {
        Asset("ANIM", "anim/" .. def.name .. ".zip"),
        Asset("ATLAS", atlas),
        Asset("IMAGE", "images/inventoryimages/ordinary_hats.tex"),
    }
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()
        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank(def.name)
        inst.AnimState:SetBuild(def.name)
        inst.AnimState:PlayAnimation("idle")
        inst:AddTag("hat")
        if def.open_top then
            inst:AddTag("open_top_hat")
        end
        MakeInventoryFloatable(inst)
        inst.components.floater:SetBankSwapOnFloat(false, nil, {bank = def.name, anim = "idle"})
        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")
        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.atlasname = atlas
        inst.components.inventoryitem.imagename = def.name
        inst:AddComponent("tradable")
        inst:AddComponent("equippable")
        inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
        inst.components.equippable:SetOnEquip(onequip)
        inst.components.equippable:SetOnUnequip(onunequip)
        MakeHauntableLaunch(inst)
        return inst
    end
    return Prefab(def.name, fn, assets)
end

local prefabs = {}
for _, def in ipairs(defs) do
    prefabs[#prefabs + 1] = makehat(def)
end
return unpack(prefabs)
