local G=GLOBAL
local passed=0
local function check(name,v)
    G.assert(v,name);passed=passed+1;print("[ORACLE_PERSIST] PASS "..name)
end
local function step(fn)
    local ok,err=G.xpcall(fn,G.debug.traceback)
    if not ok then print("[ORACLE_PERSIST] FAIL "..G.tostring(err));G.TheSim:Quit() end
end
local function later(t,fn) G.TheWorld:DoTaskInTime(t,function()step(fn)end) end
local player,staff,guard,hat,creature,record,mobrecord
local x,y,z
local function stop(g)g:StopBrain();g.entity:SetCanSleep(false)end
local function makeplayer()
    local p=G.SpawnPrefab("wilson");p.Transform:SetPosition(x,y,z)
    p.userid="KU_ORACLE_PERSIST_TEST";p.components.health:SetInvincible(true)
    return p
end
local function pet(s)
    local p,n
    n=0;for ent in G.pairs(s.components.petleash:GetPets())do p=ent;n=n+1 end
    check("exactly one bound guardian",n==1 and s._godpet==p and p.components.follower.leader==s)
    stop(p);return p
end
local function verify(s)
    local g=pet(s)
    check("health retained",G.math.abs(g.components.health.currenthealth-43210)<.1)
    for i=1,12 do check("storage retained "..i,g.components.container:GetItemInSlot(i).prefab=="goldnugget"
        and g.components.container:GetItemInSlot(i).components.stackable:StackSize()==i) end
    local inv=g.components.inventory
    check("hand equipment retained",inv:GetEquippedItem(G.EQUIPSLOTS.HANDS).prefab=="spear")
    check("weapon wear retained",G.math.abs(inv:GetEquippedItem(G.EQUIPSLOTS.HANDS).components.finiteuses:GetPercent()-.42)<.001)
    check("body equipment retained",inv:GetEquippedItem(G.EQUIPSLOTS.BODY).prefab=="armorwood")
    check("armour wear retained",G.math.abs(inv:GetEquippedItem(G.EQUIPSLOTS.BODY).components.armor:GetPercent()-.53)<.001)
    check("head equipment retained",inv:GetEquippedItem(G.EQUIPSLOTS.HEAD).prefab=="footballhat")
    check("embedded guardian excluded from world save",g.persists==false)
    local before=g
    for i=1,6 do s:OracleFixBond()end
    check("repeated fixes do not duplicate",pet(s)==before)
    return g
end
local function recruit(m,p)
    hat.components.instrument.onheard(m,p)
end
local function finish()
    print("[ORACLE_PERSIST] COMPLETE "..passed);G.TheSim:Quit()
end
local function second(payload)
    print("[ORACLE_PERSIST] PHASE disk reload")
    player=makeplayer()
    player.migrationpets={}
    player.components.inventory:OnLoad(payload.inventory)
    staff=player.components.inventory:GetItemInSlot(1)
    guard=verify(staff)
    check("native inventory migration registers guardian",#player.migrationpets==1 and player.migrationpets[1]==guard)
    local portal=G.SpawnPrefab("cave_entrance")
    check("native cave migration allows staff",portal.components.worldmigrator:CanInventoryItemMigrate(staff))
    portal:Remove()
    creature=G.SpawnSaveRecord(payload.mob)
    creature.Transform:SetPosition(x+1,y,z)
    stop(creature)
    later(.2,function()
        local c=creature.components.oracle_recruitment
        check("dynamic recruitment component restored",c~=nil and c.state~=nil)
        check("recruitment refollows matching online owner",creature.components.follower.leader==player)
        check("boosted loyalty limit retained",creature.components.follower.maxfollowtime==payload.limit)
        check("remaining loyalty not reset or clamped",G.math.abs(creature.components.follower.targettime-G.GetTime()-payload.remaining)<2)
        check("friendly tags retained",not creature:HasTag("monster")and not creature:HasTag("hostile"))
        creature.components.follower:SetLeader(nil)
        check("dismiss restores original hostility",creature:HasTag("monster")and creature:HasTag("hostile")and c.state==nil)
        local firstguard=guard
        local bag=G.SpawnPrefab("backpack")
        player.components.inventory:Equip(bag)
        player.components.inventory:RemoveItem(staff,true)
        bag.components.container:GiveItem(staff,1)
        check("staff can travel in owner's backpack",staff.components.inventoryitem:GetGrandOwner()==player)
        local invrecord=player.components.inventory:OnSave()
        player:Remove()
        check("nested staff and guardian removed on logout",not staff:IsValid() and not firstguard:IsValid())
        player=makeplayer();player.migrationpets={}
        player.components.inventory:OnLoad(invrecord)
        staff=player.components.inventory:GetEquippedItem(G.EQUIPSLOTS.BODY).components.container:GetItemInSlot(1)
        guard=verify(staff)
        check("nested migration registers one pet",#player.migrationpets==1 and player.migrationpets[1]==guard)
        later(1.3,function()
            check("arrival follows owner position",guard:GetDistanceSqToInst(player)<36)
            local n=0;for _,ent in G.pairs(G.Ents)do
                if ent.prefab=="spider_god" and ent.components.health~=nil and not ent.components.health:IsDead()then n=n+1 end
            end
            check("no duplicate live guardians after reload",n==1)
            finish()
        end)
    end)
end
local function first()
    print("[ORACLE_PERSIST] PHASE save")
    player=makeplayer();staff=G.SpawnPrefab("spider_god_bone")
    player.components.inventory:GiveItem(staff,1)
    later(2,function()
        guard=pet(staff)
        check("staff stays on player despawn",not staff:HasTag("irreplaceable"))
        guard.components.health:SetCurrentHealth(43210)
        for i=1,12 do local item=G.SpawnPrefab("goldnugget");item.components.stackable:SetStackSize(i);guard.components.container:GiveItem(item,i)end
        local inv=guard.components.inventory
        local spear=G.SpawnPrefab("spear");spear.components.finiteuses:SetPercent(.42);inv:Equip(spear)
        local armour=G.SpawnPrefab("armorwood");armour.components.armor:SetPercent(.53);inv:Equip(armour)
        inv:Equip(G.SpawnPrefab("footballhat"))
        record=staff:GetSaveRecord()
        check("staff saves pet once without leader GUID refs",record.data.petleash~=nil and #record.data.petleash.pets==1 and record.data.leader==nil)
        check("direct storage rejects staff",not guard.components.container:CanTakeItemInSlot(staff,1))
        local bag=G.SpawnPrefab("backpack");local extra=G.SpawnPrefab("spider_god_bone")
        bag.components.container:GiveItem(extra,1)
        check("unrelated nested staff allowed as equipment",G.require("oraclesentinel_equipment").Accept(guard,bag))
        bag.components.container:RemoveItem(extra,true)
        guard.components.inventory:Unequip(G.EQUIPSLOTS.BODY):Remove()
        inv:Equip(bag)
        check("unrelated staff allowed in equipped backpack",bag.components.container:CanTakeItemInSlot(extra,1))
        check("paired staff blocked in equipped backpack",not bag.components.container:CanTakeItemInSlot(staff,1))
        inv:Unequip(G.EQUIPSLOTS.BODY):Remove();extra:Remove()
        armour=G.SpawnPrefab("armorwood");armour.components.armor:SetPercent(.53);inv:Equip(armour)
        hat=G.SpawnPrefab("godhat")
        creature=G.SpawnPrefab("spider");stop(creature)
        creature.Transform:SetPosition(x+1,y,z)
        local original=creature.components.follower.maxfollowtime
        recruit(creature,player)
        check("wild creature recruited",creature.components.follower.leader==player)
        local limit=creature.components.follower.maxfollowtime
        recruit(creature,player)
        check("replay does not multiply loyalty",creature.components.follower.maxfollowtime==limit)
        creature.components.follower:CancelLoyaltyTask()
        creature.components.follower:AddLoyaltyTime(123)
        local mob=creature:GetSaveRecord()
        check("effect state saved as dynamic component",mob.data.oracle_recruitment.add_component_if_missing==true)
        player:OnDespawn()
        check("native despawn keeps staff inventory",staff.components.inventoryitem:GetGrandOwner()==player)
        check("recruitment survives owner despawn",creature.components.oracle_recruitment.state~=nil
            and creature.components.follower.cached_player_leader_userid==player.userid)
        creature.components.oracle_recruitment:Tick()
        check("offline recruit stays peaceful",not creature:HasTag("monster"))
        local inventory=player.components.inventory:OnSave()
        local payload={inventory=inventory,mob=creature:GetSaveRecord(),limit=limit,remaining=123}
        local savedguard,items=guard,{}
        for i=1,12 do items[i]=guard.components.container:GetItemInSlot(i)end
        player:Remove()
        later(.2,function()
            check("staff removed with offline player",not staff:IsValid())
            check("guardian removed with staff",not savedguard:IsValid())
            check("storage removed without dropping",not items[1]:IsValid())
            creature:Remove();hat:Remove()
            local restored=G.SpawnSaveRecord(record)
            verify(restored)
            local legacy=G.SpawnPrefab("spider_god_bone")
            local legacyguard=G.SpawnPrefab("spider_god");stop(legacyguard)
            legacy.components.leader:AddFollower(legacyguard)
            legacy:OracleFixBond()
            check("old world guardian adopted",legacy._godpet==legacyguard and legacyguard.persists==false)
            legacy:OracleFixBond()
            check("old guardian not replaced",pet(legacy)==legacyguard)
            legacy:Remove()
            local old=restored._godpet
            old.components.health:Kill()
            later(.2,function()
                check("death replacement uses single free pet slot",pet(restored)~=old)
                restored:Remove()
                G.TheSim:SetPersistentString("oracle_persistence_payload",G.DataDumper(payload,nil,true),false,function(success)
                    check("disk transfer record written",success)
                    print("[ORACLE_PERSIST] FIRST_PHASE_COMPLETE "..passed)
                    G.TheSim:Quit()
                end)
            end)
        end)
    end)
end
AddSimPostInit(function()
    if not G.TheWorld.ismastersim then return end
    later(2,function()
        for _,ent in G.pairs(G.Ents)do if (ent.prefab=="multiplayer_portal" or ent.prefab=="cave_exit")then x,y,z=ent.Transform:GetWorldPosition();break end end
        G.assert(x,"portal exists")
        G.TheSim:GetPersistentString("oracle_persistence_payload",function(ok,data)step(function()
            if ok and data~=""then second(G.assert(G.loadstring(data))())else first()end
        end)end)
    end)
end)

