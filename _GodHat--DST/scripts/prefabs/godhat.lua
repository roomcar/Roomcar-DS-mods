require "prefabutil"
require "recipe"
require "modutil"


local assets=
{
    Asset("ANIM", "anim/hat_ruins.zip"),
    Asset("ANIM", "anim/roomcar_godhat_oracle.zip"),
    Asset("ATLAS", "images/inventoryimages.xml"),
    Asset("ATLAS", "images/inventoryimages/godhat.xml"),
}

local prefabs =
{
    "tornado",
    "wendy_sanityaura_buff_on_fx", "wendy_sanityaura_buff_off_fx",
    "battlesong_attach", "battlesong_detach",
}

-------------------------------------------------------------------------------

local lang = TUNING.ROOMCAR_GODHAT_LANG

local function giveitems(owner, data)
    local inventory = owner.components.inventory
    local recipe = data ~= nil and data.recipe or nil
    if inventory == nil or recipe == nil or recipe.ingredients == nil then return end
    for _, ingredient in ipairs(recipe.ingredients) do
        local has, count = inventory:Has(ingredient.type, ingredient.amount)
        if not has then
            for i = 1, math.max(0, ingredient.amount - (count or 0)) do
                local item = SpawnPrefab(ingredient.type)
                if item ~= nil then inventory:GiveItem(item) end
            end
        end
    end
end

local function PeriodicTaskContent(inst, owner)
    if not owner:IsValid() or inst._wearer ~= owner then return end
    if inst.Light ~= nil then inst.Light:SetColour(1, 1, 1) end
    local c = owner.components
    if c.health ~= nil and c.health:IsDead() then return end
    if c.health ~= nil and c.health.currenthealth < c.health.maxhealth then c.health:SetPercent(1) end
    if c.sanity ~= nil and c.sanity.current < c.sanity.max * .85 then c.sanity:SetPercent(1) end
    if c.hunger ~= nil and c.hunger.current < c.hunger.max * .85 then c.hunger:SetPercent(1) end
    if c.moisture ~= nil then c.moisture:SetPercent(0) end
    if c.temperature ~= nil then c.temperature:SetTemperature(25) end
    -- Visual night vision is local, but darkness immunity must also exist on the server.
    if c.grue ~= nil then
        if TheWorld:HasTag("cave") or TheWorld.state.isnight then
            c.grue:AddImmunity("roomcar_godhat")
        else
            c.grue:RemoveImmunity("roomcar_godhat")
        end
    end
end

local function onplay(inst, musician)
    if musician.components.moisture ~= nil then musician.components.moisture:SetPercent(0) end
    if musician.components.temperature ~= nil then musician.components.temperature:SetTemperature(25) end
end

local function onhear(inst, musician)
    local c = inst.components
    if inst == musician or inst.prefab == "spider_god" or inst:HasTag("spider_god")
        or inst:HasTag("player") or inst:HasTag("epic")
        or c.combat == nil or c.follower == nil or c.follower.neverexpire
        or musician.components.leader == nil
        or (c.health ~= nil and c.health:IsDead())
        or (c.follower.leader ~= nil and c.follower.leader ~= musician)
        or (c.follower.cached_player_leader_userid ~= nil
            and c.follower.cached_player_leader_userid ~= musician.userid)
        or (c.rider ~= nil and c.rider:IsBeingRidden())
        or (c.freezable ~= nil and c.freezable:IsFrozen())
        or (c.pinnable ~= nil and c.pinnable:IsStuck()) then return end
    local wasenemy = c.combat:TargetIs(musician) or c.combat:IsRecentTarget(musician)
    musician.components.leader:AddFollower(inst)
    if c.follower.leader ~= musician then return end
    musician:PushEvent("makefriend")
    if c.oracle_recruitment == nil then inst:AddComponent("oracle_recruitment") end
    local fresh = c.oracle_recruitment.state == nil
    c.oracle_recruitment:Recruit(musician, wasenemy)
    if fresh then require("oracleeffects").Recruited(inst) end
    if c.talker ~= nil then c.talker:Say(require("oracle_strings").Text("遵从神谕！", "Heed the oracle!")) end
end

local function OnBlocked(owner)
    if owner.SoundEmitter ~= nil then owner.SoundEmitter:PlaySound("dontstarve/wilson/hit_nightarmour") end
end

local function OnAttacked(owner, data)
    if owner.components.combat == nil or data == nil or data.attacker == nil then return end
    owner.components.combat:ShareTarget(data.attacker, 60, function(dude)
        return dude.components.combat ~= nil and dude.components.health ~= nil
            and not dude.components.health:IsDead() and dude.components.follower ~= nil
            and dude.components.follower.leader == owner
    end, 10)
end

local function onequip(inst, owner)
    if inst._wearer == owner then return end
    inst._wearer = owner
    if inst._equipped ~= nil then inst._equipped:set(true) end
    if inst.Light ~= nil then
        inst.Light:SetColour(1, 1, 1)
        inst.Light:Enable(true)
    end
    if TUNING.ROOMCAR_GODHAT_GIVE then owner:ListenForEvent("cantbuild", giveitems) end
    owner.AnimState:OverrideSymbol("swap_hat", "roomcar_godhat_oracle", "swap_hat")
    owner.AnimState:Show("HAT")
    owner.AnimState:Hide("HAIR_HAT")
    owner.AnimState:Show("HAIR_NOHAT")
    owner.AnimState:Show("HAIR")
    owner.AnimState:Show("HEAD")
    owner.AnimState:Hide("HEAD_HAT")
    owner.AnimState:Hide("HEAD_HAT_NOHELM")
    owner.AnimState:Hide("HEAD_HAT_HELM")
    require("oracleeffects").Equip(owner, true)
    PeriodicTaskContent(inst, owner)
    inst.task = inst:DoPeriodicTask(1, PeriodicTaskContent, nil, owner)
    owner:ListenForEvent("blocked", OnBlocked)
    owner:ListenForEvent("attacked", OnAttacked)
    local combat = owner.components.combat
    inst._combatbonuses = {}
    if combat ~= nil then
        for key, delta in pairs({ damagemultiplier = 10000, attackrange = 40, hitrange = 40 }) do
            if combat[key] ~= nil then
                combat[key] = combat[key] + delta
                inst._combatbonuses[key] = delta
            end
        end
    end
end

local function onunequip(inst, owner, removing)
    if inst._wearer ~= owner then return end
    inst._wearer = nil
    if not removing then require("oracleeffects").Equip(owner, false) end
    if inst._equipped ~= nil then inst._equipped:set(false) end
    if inst.Light ~= nil then inst.Light:Enable(false) end
    owner:RemoveEventCallback("cantbuild", giveitems)
    owner:RemoveEventCallback("blocked", OnBlocked)
    owner:RemoveEventCallback("attacked", OnAttacked)
    if inst.task ~= nil then inst.task:Cancel(); inst.task = nil end
    owner.AnimState:ClearOverrideSymbol("swap_hat")
    owner.AnimState:Hide("HAT")
    local c = owner.components
    if c.grue ~= nil then c.grue:RemoveImmunity("roomcar_godhat") end
    if c.combat ~= nil then
        for key, delta in pairs(inst._combatbonuses or {}) do
            if c.combat[key] ~= nil then c.combat[key] = c.combat[key] - delta end
        end
    end
    inst._combatbonuses = nil
    -- SetTemperature changes the value once; SetTemp would permanently lock it.
    if c.temperature ~= nil then c.temperature:SetTemperature(25) end
    -- Clean up first: the health penalty can kill the wearer and trigger unequip again.
    if not removing and TUNING.ROOMCAR_GODHAT_PUNISH
        and (c.health == nil or not c.health:IsDead()) then
        if c.hunger ~= nil then c.hunger:DoDelta(-c.hunger.max * .8) end
        if c.sanity ~= nil then c.sanity:DoDelta(-c.sanity.max * .8) end
        if c.health ~= nil then c.health:DoDelta(-c.health.maxhealth * .5) end
    end
end

local function OnEquippedDirty(inst)
    if inst.Light ~= nil then
        inst.Light:SetColour(1, 1, 1)
        inst.Light:Enable(inst._equipped:value())
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

    inst.AnimState:SetBank("ruinshat")
    inst.AnimState:SetBuild("roomcar_godhat_oracle")
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("flute")

    inst:AddTag("hat")
    inst:AddTag("open_top_hat")
    inst:AddTag("umbrella")
    inst:AddTag("waterproofer") --waterproofer (from waterproofer component) added to pristine state for optimization
    -- inst:AddTag("nightvision")
    -- inst:AddTag("show_spoilage")

    inst:AddTag("prototyper")

    inst.MiniMapEntity:SetIcon("godhat.tex")

    if TUNING.ROOMCAR_GODHAT_LIGHT then
        inst.entity:AddLight()
        inst.Light:SetRadius(20)
        inst.Light:SetFalloff(1)
        inst.Light:SetIntensity(.99)
        inst.Light:SetColour(1, 1, 1)
        inst.Light:Enable(false)
    end
    inst._equipped = net_bool(inst.GUID, "godhat.equipped", "godhatequippeddirty")
    inst:ListenForEvent("godhatequippeddirty", OnEquippedDirty)

    inst.entity:SetPristine()

    inst.shouldsayNVon = true
    inst.shouldsayNVoff = false

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("prototyper")
    inst.components.prototyper.trees = {SCIENCE = 9, MAGIC = 9, ANCIENT = 9, SHADOW = 9, CARTOGRAPHY = 0, SCULPTING = 0, ORPHANAGE = 0,}

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/godhat.xml"

    inst:AddComponent("inspectable")

    inst:AddComponent("instrument")
    inst.components.instrument.range = 40
    inst.components.instrument:SetOnHeardFn(onhear)
    inst.components.instrument:SetOnPlayedFn(onplay)

    inst:AddComponent("tradable")

    inst:AddComponent("armor")
    inst.components.armor:InitCondition(TUNING.ARMORRUINS*1000000, 1)

    inst:AddComponent("heater")
    inst.components.heater:SetThermics(false, true)
    inst.components.heater.heat = 25
    inst.components.heater.equippedheat = 25
    inst.components.heater.carriedheat = 25

    inst:AddComponent("insulator")
    inst.components.insulator:SetInsulation(TUNING.INSULATION_LARGE*100)

    inst:AddComponent("waterproofer")
    inst.components.waterproofer:SetEffectiveness(1)

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
    inst.components.equippable.walkspeedmult = TUNING.ROOMCAR_GODHAT_WALKSPEED
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:ListenForEvent("onremove", function()
        if inst._wearer ~= nil and inst._wearer:IsValid() then
            onunequip(inst, inst._wearer, true)
        end
    end)

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = 100

    MakeHauntableLaunch(inst)

    return inst
end

------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------

--local STRINGS=GLOBAL.STRINGS

require("oracle_strings").Apply()

return Prefab("godhat", fn, assets, prefabs)
