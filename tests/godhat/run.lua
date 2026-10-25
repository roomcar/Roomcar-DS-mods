-- Run with the repository test runner (Lua 5.1); no game installation is mutated.
local root = assert(arg[1])
package.path = root .. "/scripts/?.lua;" .. package.path
local tests = 0
local function test(name, fn)
    fn()
    tests = tests + 1
    print("PASS " .. name)
end
local function noop() end
Class = Class or function(ctor)
    local c={};c.__index=c
    return setmetatable(c,{__call=function(cls,...)
        local self=setmetatable({},cls);ctor(self,...);return self
    end})
end
net_entity = net_entity or function()
    return {set=function(self,v)self.v=v end,value=function(self)return self.v end}
end
package.preload.prefabutil = function() return {} end
package.preload.recipe = function() return {} end
package.preload.modutil = function() return {} end
TUNING = { ARMORRUINS = 100, INSULATION_LARGE = 100, PIG_LOYALTY_MAXTIME = 100,
    ROOMCAR_GODHAT_LIGHT = true, ROOMCAR_GODHAT_GIVE = true, ROOMCAR_GODHAT_WALKSPEED = 1.5 }
EQUIPSLOTS = { HEAD = "head", BODY = "body", HANDS = "hands" }
TheWorld = { ismastersim = true, state = { isnight = false }, HasTag = function() return false end }
TheNet = { IsDedicated = function() return false end, GetPVPEnabled = function() return false end }
STRINGS = { NAMES = {}, RECIPE_DESC = {}, CHARACTERS = {} }
for _, name in ipairs({ "GENERIC", "WX78", "WEBBER" }) do STRINGS.CHARACTERS[name] = { DESCRIBE = {} } end
Asset = function(kind, path) return { kind = kind, path = path } end
Prefab = function(name, fn, assets, prefabs) return { name = name, fn = fn, assets = assets, prefabs = prefabs } end
MakeInventoryPhysics, MakeHauntableLaunch = noop, noop
GetTime = function() return 50 end
net_smallbyte = function()return {set=function(self,v)self.v=v end,value=function(self)return self.v or 0 end}end
local nextguid = 0
local function entity()
    nextguid = nextguid + 1
    local inst = { GUID = nextguid, components = {}, replica = {}, events = {}, tasks = {}, tags = {} }
    function inst:IsValid() return not self.removed end
    function inst:HasTag(tag) return self.tags[tag] == true end
    function inst:AddTag(tag) self.tags[tag] = true end
    function inst:RemoveTag(tag) self.tags[tag] = nil end
    function inst:ListenForEvent(event, fn, source)
        source = source or self
        source.events[event] = source.events[event] or {}
        table.insert(source.events[event], { receiver = self, fn = fn })
    end
    function inst:RemoveEventCallback(event, fn, source)
        source = source or self
        for i = #(source.events[event] or {}), 1, -1 do
            local entry = source.events[event][i]
            if entry.receiver == self and entry.fn == fn then table.remove(source.events[event], i) end
        end
    end
    function inst:PushEvent(event, data)
        local entries = {}
        for _, entry in ipairs(self.events[event] or {}) do table.insert(entries, entry) end
        for _, entry in ipairs(entries) do entry.fn(entry.receiver, data) end
    end
    function inst:DoTaskInTime(delay, fn, ...)
        local args = {...}
        local task = { delay = delay, Cancel = function(self) self.cancelled = true end }
        task.Run = function() if not task.cancelled then fn(self, unpack(args)) end end
        table.insert(self.tasks, task)
        return task
    end
    function inst:DoPeriodicTask(delay, fn, initial, ...)
        local task = self:DoTaskInTime(delay, fn, ...)
        task.periodic = true
        return task
    end
    inst.AnimState = setmetatable({}, { __index = function() return noop end })
    inst.Transform = { GetWorldPosition = function() return 0,0,0 end, SetFourFaced=noop, SetScale=noop }
    inst.DynamicShadow = { SetSize=noop }
    inst.SetStateGraph,inst.SetBrain = noop,noop
    inst.entity = { AddTransform = noop, AddAnimState = noop, AddSoundEmitter = noop,
        AddMiniMapEntity = function() inst.MiniMapEntity = { SetIcon = noop, SetCanUseCache=noop } end,
        AddLightWatcher=noop, AddDynamicShadow=noop,
        AddNetwork = noop, SetPristine = noop,
        AddLight = function()
            inst.Light = { SetRadius = noop, SetFalloff = noop, SetIntensity = noop, SetColour = function(self,r,g,b)self.colour={r,g,b}end,
                Enable = function(self, value) self.enabled = value end }
        end }
    function inst:GetPosition() return {Get=function() return 0,0,0 end} end
    function inst:AddComponent(name)
        local c = { inst = self }
        self.components[name] = c
        if name == "oracle_recruitment" then
            self.components[name] = require("components/oracle_recruitment")(self)
        elseif name == "petleash" then
            if NATIVE_PETLEASH ~= nil then
                self.components[name] = assert(loadstring(NATIVE_PETLEASH))()(self)
            else
                c.pets={};c.maxpets=1;c.OnSave=noop
                function c:SetPetPrefab(v)self.petprefab=v end
                function c:SetMaxPets(v)self.maxpets=v end
                function c:SetOnSpawnFn(v)self.onspawn=v end
                function c:SetOnDespawnFn(v)self.ondespawn=v end
                function c:GetPets()return self.pets end
                function c:IsPet(p)return self.pets[p]~=nil end
                function c:AttachPet(p)
                    local n=0;for _ in pairs(self.pets)do n=n+1 end
                    if n>=self.maxpets then return false end
                    self.pets[p]=p;p.persists=false;self.inst.components.leader:AddFollower(p);return true
                end
                function c:DetachPet(p)self.pets[p]=nil end
                function c:SpawnPetAt(x,y,z)
                    local p=SpawnPrefab(self.petprefab)
                    if p~=nil then self:AttachPet(p);p.Physics:Teleport(x,y,z);self.onspawn(self.inst,p)end
                    return p
                end
            end
        elseif name == "equippable" then
            c.SetOnEquip = function(self, fn) self.equip = fn end
            c.SetOnUnequip = function(self, fn) self.unequip = fn end
        elseif name == "instrument" then
            c.SetOnHeardFn = function(self, fn) self.onhear = fn end
            c.SetOnPlayedFn = function(self, fn) self.onplay = fn end
        elseif name == "inventoryitem" then
            c.GetGrandOwner = function(self)return self.owner end
            c.ChangeImageName = function(self, image) self.image = image end
            c.SetOnPutInInventoryFn = function(self, fn) self.onput = fn end
        elseif name == "leader" then
            c.followers = {}
            c.AddFollower = function(self, follower)
                self.followers[follower] = true
                follower.components.follower.leader = self.inst
            end
        elseif name == "trader" then
            c.SetAcceptTest = function(self, fn) self.test=fn end
            c.SetOnAccept = function(self, fn) self.onaccept=fn end
        else
            c.InitCondition, c.SetThermics, c.SetInsulation, c.SetEffectiveness, c.RecordViews = noop,noop,noop,noop,noop
            c.MakeChatter, c.Say, c.SetSlowMultiplier, c.SetTriggersCreep = noop,noop,noop,noop
            c.SetKeepTargetFunction, c.SetDefaultDamage, c.SetAttackPeriod = noop,noop,noop
            c.SetRetargetFunction = function(self,period,fn) self.retarget=fn end
            c.AddRandomLoot, c.WidgetSetup, c.SetMaxHealth = noop,noop,noop
            c.DropEverything = function(self) self.dropped=true end
        end
    end
    return inst
end
CreateEntity = entity
net_bool = function()
    return { set = function(self, v) self.v = v end, value = function(self) return self.v or false end }
end
local function player()
    local p = entity()
    p:AddComponent("leader")
    p.components.combat = { damagemultiplier = 1, attackrange = 2, hitrange = 3, ShareTarget = noop }
    p.components.temperature = { SetTemperature = function(self, v) self.current = v end,
        SetTemp = function() error("must not lock temperature") end }
    p.components.health = { currenthealth = 100, maxhealth = 100, IsDead = function(self) return self.currenthealth <= 0 end,
        SetPercent = function(self,v) self.currenthealth = self.maxhealth * v end,
        DoDelta = function(self,v) self.currenthealth = self.currenthealth + v end }
    p.components.hunger = { current = 100, max = 100, SetPercent = noop, DoDelta = noop }
    p.components.sanity = { current = 100, max = 100, SetPercent = noop, DoDelta = noop }
    return p
end
local hatprefab = dofile(root .. "/scripts/prefabs/godhat.lua")
local function equip(p)
    local hat = hatprefab.fn()
    hat.components.equippable.equip(hat, p)
    return hat
end

test("dedicated server equip never touches camera or player vision", function()
    TheCamera = nil
    local p = player()
    local hat = equip(p)
    assert(p.components.combat.damagemultiplier == 10001)
    hat.components.equippable.unequip(hat, p)
    assert(p.components.combat.damagemultiplier == 1)
    assert(p.components.temperature.current == 25)
end)
test("circlet physical light remains white after wear and replicated updates", function()
    local hat=equip(player())
    hat.Light.colour={.2,.1,.8};hat.task.Run()
    assert(hat.Light.colour[1]==1 and hat.Light.colour[2]==1 and hat.Light.colour[3]==1)
    hat.Light.colour={.3,.1,.9};hat:PushEvent("godhatequippeddirty")
    assert(hat.Light.colour[1]==1 and hat.Light.colour[2]==1 and hat.Light.colour[3]==1)
end)

test("duplicate equip and unequip cannot accumulate combat bonuses", function()
    local p = player()
    local hat = equip(p)
    hat.components.equippable.equip(hat,p)
    assert(p.components.combat.attackrange == 42)
    hat.components.equippable.unequip(hat,p)
    hat.components.equippable.unequip(hat,p)
    assert(p.components.combat.attackrange == 2 and p.components.combat.hitrange == 3)
    assert(hat.task == nil)
end)
test("missing character hunger sanity temperature components are safe", function()
    local p = player()
    p.components.hunger, p.components.sanity, p.components.temperature = nil,nil,nil
    TUNING.ROOMCAR_GODHAT_PUNISH = true
    local hat = equip(p)
    hat.components.equippable.unequip(hat,p)
    assert(p.components.health.currenthealth == 50)
    TUNING.ROOMCAR_GODHAT_PUNISH = false
end)
test("remove while equipped cancels tasks and restores bonuses without punishment", function()
    local p = player()
    local hat = equip(p)
    local task = hat.task
    TUNING.ROOMCAR_GODHAT_PUNISH = true
    hat:PushEvent("onremove")
    assert(task.cancelled and p.components.health.currenthealth == 100)
    assert(p.components.combat.attackrange == 2)
    TUNING.ROOMCAR_GODHAT_PUNISH = false
end)
test("fatal punishment cleans bonuses before reentrant unequip", function()
    local p = player()
    local hat = equip(p)
    p.components.health.currenthealth = 20
    p.components.health.DoDelta = function(self, v)
        self.currenthealth = self.currenthealth + v
        hat.components.equippable.unequip(hat,p)
    end
    TUNING.ROOMCAR_GODHAT_PUNISH = true
    hat.components.equippable.unequip(hat,p)
    assert(p.components.health.currenthealth == -30 and p.components.combat.attackrange == 2)
    TUNING.ROOMCAR_GODHAT_PUNISH = false
end)
test("client light exists before master-only components and follows replicated state", function()
    TheWorld.ismastersim = false
    local hat = hatprefab.fn()
    assert(hat.Light ~= nil and not hat.Light.enabled and hat.components.equippable == nil)
    hat._equipped:set(true); hat:PushEvent("godhatequippeddirty")
    assert(hat.Light.enabled)
    hat._equipped:set(false); hat:PushEvent("godhatequippeddirty")
    assert(not hat.Light.enabled)
    TheWorld.ismastersim = true
end)
test("recruitment calls combat methods correctly and replaces only its own task", function()
    local p = player()
    local hat = hatprefab.fn()
    local mob = entity()
    mob.components.follower = { maxfollowtime = 10, AddLoyaltyTime = function(self,t)self.targettime=GetTime()+t end }
    local combat = { target = p }
    combat.TargetIs = function(self,t) assert(self == combat); return self.target == t end
    combat.IsRecentTarget = function(self,t) assert(self == combat); return false end
    combat.DropTarget = function(self) assert(self == combat); self.target = nil end
    mob.components.combat = combat
    local unrelated = mob:DoPeriodicTask(1, noop)
    mob.task = unrelated
    hat.components.instrument.onhear(mob,p,hat)
    assert(combat.target == nil and mob.components.follower.leader == p)
    local first = mob._roomcar_godhat_peacetask
    hat.components.instrument.onhear(mob,p,hat)
    assert(first.cancelled and not unrelated.cancelled)
    assert(mob.components.follower.maxfollowtime == 1000)
    mob.components.follower.leader = nil
    mob:PushEvent("stopfollowing")
    assert(mob._roomcar_godhat_peacetask == nil)
end)
test("malformed cantbuild event is harmless and material top-up gives only shortage", function()
    local p = player()
    local hat = equip(p)
    p:PushEvent("cantbuild")
    local given = 0
    p.components.inventory = { Has = function() return false,3 end, GiveItem = function() given = given+1 end }
    SpawnPrefab = function() return {} end
    p:PushEvent("cantbuild", { recipe = { ingredients = {{type="goldnugget",amount=5}} } })
    assert(given == 2)
    hat.components.equippable.unequip(hat,p)
end)

local visuals = dofile(root .. "/scripts/godhatvisuals.lua")
test("camera and night vision apply only to local wearer and restore prior settings", function()
    local p, remote = player(), player()
    ThePlayer = p
    TheCamera = { zoomstep=3,mindist=8,maxdist=55,mindistpitch=21,maxdistpitch=62,distancetarget=35 }
    local equipped = { prefab = "godhat" }
    p.replica.inventory = { GetEquippedItem = function() return equipped end }
    remote.replica.inventory = p.replica.inventory
    local sources = { anothermod = true }
    p.components.playervision = {
        PushForcedNightVision = function(self,source,priority,cc,blend,ambient,nocc) assert(cc==nil and nocc==true); sources[source]=true end,
        PopForcedNightVision = function(self,source) sources[source]=nil end }
    visuals.Update(remote)
    assert(TheCamera.maxdist == 55)
    visuals.Update(p)
    assert(TheCamera.maxdist == 180 and TheCamera.distancetarget == 80)
    TheWorld.state.isnight = true; visuals.Update(p)
    assert(sources.roomcar_godhat and sources.anothermod)
    equipped = nil; visuals.Update(p)
    assert(TheCamera.maxdist == 55 and TheCamera.distancetarget == 35)
    assert(not sources.roomcar_godhat and sources.anothermod)
    TheWorld.state.isnight = false
end)
test("dedicated server never starts client visuals", function()
    TheNet.IsDedicated = function() return true end
    local p = player()
    visuals.Attach(p)
    assert(#p.tasks == 0)
    TheNet.IsDedicated = function() return false end
end)
test("server retains darkness immunity even with lighting disabled, and removes only its own source", function()
    local p = player()
    local immunity = { anothermod=true }
    p.components.grue = {
        AddImmunity=function(self,key) immunity[key]=true end,
        RemoveImmunity=function(self,key) immunity[key]=nil end }
    TheWorld.state.isnight = true
    TUNING.ROOMCAR_GODHAT_LIGHT = false
    local hat = equip(p)
    assert(hat.Light == nil and immunity.roomcar_godhat)
    hat.components.equippable.unequip(hat,p)
    assert(not immunity.roomcar_godhat and immunity.anothermod)
    TUNING.ROOMCAR_GODHAT_LIGHT = true
    TheWorld.state.isnight = false
end)

local boneprefab = dofile(root .. "/scripts/prefabs/spider_god_bone.lua")
local pets = {}
local function pet()
    local p = entity()
    p.prefab = "spider_god"
    require("oraclecolours").Prepare(p)
    p.components.health = { IsDead = function() return p.dead == true end }
    p.components.follower = { SetLeader = function(self,leader)
        self.leader = leader; leader.components.leader.followers[p] = true end }
    p.Physics = { Teleport = noop }; p.FacePoint = noop
    table.insert(pets,p)
    return p
end
local position = { Get = function() return 0,0,0 end }
setmetatable(position, { __add = function() return position end })
PI = math.pi
FindWalkableOffset = function() return position end
SpawnPrefab = function(name) assert(name == "spider_god"); return pet() end
local function bone()
    local b = boneprefab.fn()
    b.GetPosition = function() return position end
    b.components.inventoryitem.owner = player()
    return b
end
test("two bones summon separate pets and never steal followers", function()
    local a,b = bone(),bone()
    a.fixtask.Run(); a.respawntask.Run()
    b.fixtask.Run(); b.respawntask.Run()
    assert(a._godpet ~= b._godpet)
    assert(a._godpet.components.follower.leader == a and b._godpet.components.follower.leader == b)
    assert(a.isOpenEye and b.isOpenEye)
end)
test("pet death schedules one replacement and ignores the still-existing corpse", function()
    local b = bone()
    b.fixtask.Run(); b.respawntask.Run()
    local old = b._godpet
    old.dead = true; old:PushEvent("death")
    assert(not b.isOpenEye and b.respawntask ~= nil)
    b.respawntask.Run()
    assert(b._godpet ~= old and b.isOpenEye)
end)
test("loaded leader binding is reused without spawning duplicate", function()
    local b = bone()
    local existing = pet()
    existing.components.follower:SetLeader(b)
    local count = #pets
    b.fixtask.Run()
    assert(b._godpet == existing and #pets == count and b.isOpenEye)
    b.components.inventoryitem.onput(b)
    b.fixtask.Run()
    assert(#existing.events.death == 1)
end)
test("failed spawn retries and saved respawn delay survives load", function()
    local b = bone()
    b:OnLoad({ respawntimeremaining=12 })
    b.fixtask.Run()
    assert(b.respawntask.delay == 12)
    local data = {}; b:OnSave(data)
    assert(data.respawntimeremaining == 12)
    local spawn = SpawnPrefab
    SpawnPrefab = function() return nil end
    b.respawntask.Run()
    assert(b.respawntask.delay == 5 and not b.isOpenEye)
    SpawnPrefab = spawn
    FindWalkableOffset = function() return position end
end)
package.preload["brains/spider_godbrain"] = function() return {} end
MakeCharacterPhysics, MakeHauntablePanic = noop,noop
Vector3 = function() return {} end
SpringCombatMod = function(value) return value end
local spiderprefab = dofile(root .. "/scripts/prefabs/spider_god.lua")
test("pet death drops container and inventory before shadow stategraph removes it", function()
    local p = spiderprefab.fn()
    local task = p.task
    p:PushEvent("death")
    assert(p.components.container.dropped and p.components.inventory.dropped and task.cancelled)
end)
test("pet target filter accepts hounds OR monsters, and invalid attackers are ignored", function()
    local p = spiderprefab.fn()
    FindEntity = function(inst,range,predicate,must,cant,oneof)
        assert(#must==1 and must[1]=="_combat")
        assert(oneof[1]=="hound" and oneof[2]=="monster")
    end
    p.components.combat.retarget(p)
    p:PushEvent("attacked")
    local attacker = entity(); attacker.removed=true
    p:PushEvent("attacked",{attacker=attacker})
end)
print("TOTAL " .. tests .. " tests passed")

