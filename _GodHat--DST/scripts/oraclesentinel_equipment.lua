-- Standard humanoid equipment layers without pretending this NPC is a player.
local SLOT_KEYS = {EQUIPSLOTS.HANDS, EQUIPSLOTS.BODY, EQUIPSLOTS.HEAD}

local function Prepare(inst)
    inst._oracle_equipment = {}
    for i = 1, 3 do
        inst._oracle_equipment[i] = net_entity(inst.GUID, "oracle.equipment."..i, "oracleequipmentdirty")
    end
end

local function Refresh(inst)
    local inventory = inst.components.inventory
    if inventory == nil then return end
    if inst._oracle_equipment ~= nil then
        for i, slot in ipairs(SLOT_KEYS) do inst._oracle_equipment[i]:set(inventory:GetEquippedItem(slot)) end
    end
    local hat = inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
    inst.AnimState:ClearOverrideSymbol("headbase_hat")
    if hat == nil or hat:HasTag("open_top_hat") then
        inst.AnimState:Show("HEAD")
        inst.AnimState:Hide("HEAD_HAT")
        inst.AnimState:Hide("HEAD_HAT_HELM")
        inst.AnimState:Hide("HEAD_HAT_NOHELM")
        if hat == nil then inst.AnimState:Hide("HAT") else inst.AnimState:Show("HAT") end
    elseif hat:HasTag("fullhelm_hat") then
        local build = hat:GetSkinBuild() or hat.AnimState:GetBuild()
        inst.AnimState:OverrideSymbol("headbase_hat", build, "swap_hat")
        inst.AnimState:Hide("HEAD")
        inst.AnimState:Hide("HAT")
        inst.AnimState:Show("HEAD_HAT")
        inst.AnimState:Show("HEAD_HAT_HELM")
        inst.AnimState:Hide("HEAD_HAT_NOHELM")
    else
        inst.AnimState:Hide("HEAD")
        inst.AnimState:Show("HEAD_HAT")
        inst.AnimState:Show("HEAD_HAT_NOHELM")
        inst.AnimState:Hide("HEAD_HAT_HELM")
        inst.AnimState:Show("HAT")
    end
    if inventory:GetEquippedItem(EQUIPSLOTS.HANDS) ~= nil then
        inst.AnimState:Show("ARM_carry")
        inst.AnimState:Hide("ARM_normal")
    else
        inst.AnimState:Hide("ARM_carry")
        inst.AnimState:Show("ARM_normal")
    end
end

local function Alive(inst)
    return inst ~= nil and inst:IsValid() and inst.components.health ~= nil
        and not inst.components.health:IsDead()
end

local function ReturnItem(player, item)
    if item == nil or not item:IsValid() then return end
    item.prevcontainer, item.prevslot = nil, nil
    item.components.inventoryitem:OnRemoved()
    local inventory = player.components.inventory
    if inventory:GetActiveItem() == nil and item.components.inventoryitem.cangoincontainer then
        inventory:GiveActiveItem(item)
    else
        inventory:GiveItem(item, nil, player:GetPosition())
    end
end

-- This RPC operates only the player's cursor item. The client never selects
-- arbitrary items or invents equipment. Equipped objects live solely in the
-- native inventory's equip slots; the 12 container slots are untouched.
local function HandleClick(player, inst, index, removeonly)
    local slot = SLOT_KEYS[index]
    if slot == nil or not Alive(player) or not Alive(inst) or inst.prefab ~= "spider_god"
        or player:HasTag("playerghost") or player:HasTag("busy")
        or player.components.inventory == nil or inst.components.inventory == nil
        or inst.components.container == nil or not inst.components.container:IsOpenedBy(player)
        or not player:IsNear(inst, 4) then return false end
    local inventory = inst.components.inventory
    local previous = inventory:GetEquippedItem(slot)
    if previous ~= nil and previous.components.equippable:ShouldPreventUnequipping() then return false end
    local incoming = not removeonly and player.components.inventory:GetActiveItem() or nil
    if incoming ~= nil then
        local equippable = incoming.components.equippable
        if not incoming:IsValid() or incoming.components.inventoryitem == nil
            or incoming.components.inventoryitem.owner ~= player
            or equippable == nil or equippable.equipslot ~= slot
            or equippable:IsRestricted(inst) or incoming:HasTag("heavy") or require("oraclecontainment").WouldCycle(inst,incoming) then return false end
    end
    if previous == nil and incoming == nil then return false end
    if previous ~= nil then
        if inventory:Unequip(slot) ~= previous then return false end
        if not Alive(inst) then ReturnItem(player, previous); Refresh(inst); return false end
    end
    if incoming ~= nil and not inventory:Equip(incoming) then
        if previous ~= nil and previous:IsValid() then inventory:Equip(previous) end
        Refresh(inst)
        return false
    end
    ReturnItem(player, previous)
    Refresh(inst)
    return true
end

local function Accept(inst, item)
    if require("oraclecontainment").WouldCycle(inst,item) then return false end
    local equippable = item ~= nil and item.components.equippable or nil
    if equippable == nil then return false end
    local slot = equippable.equipslot
    return slot == EQUIPSLOTS.HEAD or slot == EQUIPSLOTS.BODY or slot == EQUIPSLOTS.HANDS
end

local function OnAccept(inst, giver, item)
    if not Accept(inst, item) then return end
    local inventory = inst.components.inventory
    local slot = item.components.equippable.equipslot
    local previous = inventory:Unequip(slot)
    if previous ~= nil then
        if giver ~= nil and giver:IsValid() and giver.components.inventory ~= nil then
            giver.components.inventory:GiveItem(previous)
        else
            inventory:GiveItem(previous)
            inventory:DropItem(previous, true, true)
        end
    end
    inventory:Equip(item)
    Refresh(inst)
end

local function Attach(inst)
    inst:ListenForEvent("equip", Refresh)
    inst:ListenForEvent("unequip", Refresh)
    inst:DoTaskInTime(0, Refresh)
    inst:AddComponent("trader")
    inst.components.trader.deleteitemonaccept = false
    inst.components.trader.acceptnontradable = true
    inst.components.trader:SetAcceptTest(Accept)
    inst.components.trader:SetOnAccept(OnAccept)
end

return { Attach=Attach, Prepare=Prepare, Refresh=Refresh, Accept=Accept, OnAccept=OnAccept, HandleClick=HandleClick, SLOT_KEYS=SLOT_KEYS }
