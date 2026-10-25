local assets = {
    Asset("ANIM", "anim/roomcar_oracle_scepter.zip"),
    Asset("ATLAS", "images/inventoryimages/oracle_scepter.xml"),
    Asset("IMAGE", "images/inventoryimages/oracle_scepter.tex"),
}
local Containment = require("oraclecontainment")
local function Eye(inst, open)
    inst.isOpenEye = open or nil
    inst.components.inventoryitem:ChangeImageName(open and "spider_god_bone" or "spider_god_bone_closed")
    inst.AnimState:PlayAnimation(open and "idle_loop" or "dead", true)
end
local function Alive(pet)
    return pet ~= nil and pet:IsValid() and pet.components.health ~= nil
        and not pet.components.health:IsDead() and pet.components.follower ~= nil
end
local function FindPet(inst)
    for pet in pairs(inst.components.petleash:GetPets()) do
        if Alive(pet) then return pet end
    end
    -- Adopt pre-petleash saves after the native leader's LoadPostPass.
    for pet in pairs(inst.components.leader.followers) do
        if pet.prefab == "spider_god" and Alive(pet) then return pet end
    end
end
local StartRespawn
local function StopRespawn(inst)
    if inst.respawntask ~= nil then inst.respawntask:Cancel(); inst.respawntask = nil end
    inst.respawntime = nil
end
local function Bind(inst, pet)
    pet = pet or FindPet(inst)
    if not Alive(pet) then return false end
    if pet.components.follower.leader ~= nil and pet.components.follower.leader ~= inst then return false end
    Containment.EjectLegacyStaff(pet)
    local leash = inst.components.petleash
    if not leash:IsPet(pet) and not leash:AttachPet(pet) then return false end
    if inst._godpet ~= pet then
        if inst._godpet ~= nil then inst:RemoveEventCallback("death", inst._onpetdeath, inst._godpet) end
        inst._godpet = pet
        inst:ListenForEvent("death", inst._onpetdeath, pet)
    end
    require("oraclecolours").Set(pet, require("oraclecolours").Get(inst))
    Eye(inst, true)
    return true
end
local function Holder(inst)
    return Containment.RootHolder(inst) or inst
end
local function Near(inst)
    local pt = Holder(inst):GetPosition()
    local offset = FindWalkableOffset(pt, math.random() * 2 * PI, 3, 12, true)
    return offset ~= nil and pt + offset or pt
end
local function Respawn(inst)
    StopRespawn(inst)
    if inst._oracle_removing or Bind(inst) then return end
    local pt = Near(inst)
    local pet = inst.components.petleash:SpawnPetAt(pt:Get())
    if Bind(inst, pet) then require("oracleeffects").GuardArrive(pet)
    else StartRespawn(inst, 5) end
end
StartRespawn = function(inst, delay)
    StopRespawn(inst)
    delay = math.max(0, delay or 0)
    inst.respawntime = GetTime() + delay
    inst.respawntask = inst:DoTaskInTime(delay, Respawn)
    Eye(inst, false)
end
local function Fix(inst)
    if inst.fixtask ~= nil then inst.fixtask:Cancel(); inst.fixtask = nil end
    if inst._oracle_removing then return end
    if Bind(inst) then
        StopRespawn(inst)
        if inst._oracle_arrival and Holder(inst):HasTag("player") then
            inst._godpet.Physics:Teleport(Near(inst):Get())
            inst._oracle_arrival = nil
            require("oracleeffects").GuardArrive(inst._godpet)
        end
    elseif inst.respawntask == nil and (inst.components.inventoryitem.owner ~= nil or inst.respawntime ~= nil) then
        StartRespawn(inst, inst.respawntime ~= nil and inst.respawntime - GetTime() or 0)
    end
end
local function ScheduleFix(inst)
    if inst.fixtask == nil then inst.fixtask = inst:DoTaskInTime(1, Fix) end
end
local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform(); inst.entity:AddAnimState(); inst.entity:AddNetwork()
    MakeInventoryPhysics(inst)
    inst:AddTag("chester_eyebone")
    inst:AddTag("nonpotatable")
    -- No irreplaceable: player despawn and shard migration must retain the staff.
    inst.AnimState:SetBank("roomcar_oracle_scepter")
    inst.AnimState:SetBuild("roomcar_oracle_scepter")
    inst.AnimState:PlayAnimation("dead", true)
    require("oraclecolours").Prepare(inst)
    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/oracle_scepter.xml"
    inst.components.inventoryitem:SetOnPutInInventoryFn(ScheduleFix)
    inst.components.inventoryitem:ChangeImageName("spider_god_bone_closed")
    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = function() return inst.respawntask ~= nil and "WAITING" or nil end
    inst:AddComponent("leader")
    inst:AddComponent("petleash")
    inst.components.petleash:SetPetPrefab("spider_god")
    inst.components.petleash:SetMaxPets(1)
    inst.components.petleash:SetOnSpawnFn(Bind)
    local savepets = inst.components.petleash.OnSave
    inst.components.petleash.OnSave = function(self)
        -- Also adopt legacy followers if a save happens before the delayed fix.
        Bind(inst)
        return savepets(self)
    end
    inst.components.petleash:SetOnDespawnFn(function(_, pet)
        if pet.components.container ~= nil then pet.components.container:Close() end
        if not inst.is_snapshot_user_session then require("oracleeffects").GuardDepart(pet) end
        pet:Remove()
    end)
    -- Embedded exactly once, never saved again by leader GUID references.
    inst.components.leader.OnSave = function() end
    inst._onpetdeath = function()
        local pet = inst._godpet
        if pet ~= nil then
            inst:RemoveEventCallback("death", inst._onpetdeath, pet)
            inst.components.petleash:DetachPet(pet)
            inst._godpet = nil
        end
        if not inst._oracle_removing then StartRespawn(inst, 0) end
    end
    inst.OnSave = function(_, data)
        if inst.respawntime ~= nil then data.respawntimeremaining = math.max(0, inst.respawntime - GetTime()) end
    end
    inst.OnLoad = function(_, data)
        inst._oracle_arrival = true
        if data ~= nil and data.respawntimeremaining ~= nil then inst.respawntime = GetTime() + data.respawntimeremaining end
    end
    inst.OnLoadPostPass = Fix
    inst.OracleFixBond = Fix
    inst:ListenForEvent("onremove", function()
        inst._oracle_removing = true
        StopRespawn(inst)
        if inst.fixtask ~= nil then inst.fixtask:Cancel(); inst.fixtask = nil end
    end)
    require("oraclecolours").Attach(inst)
    MakeHauntableLaunch(inst)
    ScheduleFix(inst)
    return inst
end
require("oracle_strings").Apply()
return Prefab("spider_god_bone", fn, assets, {"spider_god", "spawn_fx_small", "shadow_teleport_out", "shadow_puff"})
