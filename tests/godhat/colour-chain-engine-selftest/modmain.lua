local G=GLOBAL
local count=0
local function check(n,v)G.assert(v,n);count=count+1;print("[ORACLE_COLOUR] PASS "..n)end
local function step(fn)
    local ok,e=G.xpcall(fn,G.debug.traceback)
    if not ok then print("[ORACLE_COLOUR] FAIL "..G.tostring(e));G.TheSim:Quit()end
end
local function later(t,fn)G.TheWorld:DoTaskInTime(t,function()step(fn)end)end
local x,y,z,player
local C=G.require("oraclecolours")
local S=G.require("oraclecontainment")
local staff,guard={},{}
local function makeplayer()
    local p=G.SpawnPrefab("wilson");p.userid="KU_ORACLE_COLOUR_TEST"
    p.Transform:SetPosition(x,y,z);p.components.health:SetInvincible(true);return p
end
local function bind(s)
    local g,n=nil,0
    for pet in G.pairs(s.components.petleash:GetPets())do g=pet;n=n+1 end
    check("one guardian per staff",n==1 and g.components.follower.leader==s)
    g:StopBrain();g.entity:SetCanSleep(false);return g
end
local function collect(p)
    local a=p.components.inventory:GetItemInSlot(1)
    staff[1]=a;guard[1]=bind(a)
    for i=2,3 do staff[i]=guard[i-1].components.container:GetItemInSlot(1);guard[i]=bind(staff[i])end
end
local function verify(p)
    collect(p)
    local colours={2,3,6}
    for i=1,3 do
        check("pair colour retained "..i,C.Get(staff[i])==colours[i] and C.Get(guard[i])==colours[i])
        local r,g,b,a=guard[i].AnimState:GetMultColour()
        local er,eg,eb,ea=C.RGBA(staff[i])
        check("actual guardian tint matches staff "..i,G.math.abs(r-er)<.005 and G.math.abs(g-eg)<.005 and G.math.abs(b-eb)<.005 and a==ea)
        check("chain health retained "..i,G.math.abs(guard[i].components.health.currenthealth-(43000+i*100))<.1)
        check("chain storage retained "..i,guard[i].components.container:GetItemInSlot(2).components.stackable:StackSize()==i+2)
        check("chain gear retained "..i,guard[i].components.inventory:GetEquippedItem(G.EQUIPSLOTS.HANDS).prefab=="spear")
        check("own staff rejected "..i,not guard[i].components.container:CanTakeItemInSlot(staff[i],3))
        if i>1 then check("native follower follows parent guardian "..i,guard[i].components.follower:GetLeader()==guard[i-1])end
    end
    check("ancestor staff would close cycle",not guard[3].components.container:CanTakeItemInSlot(staff[1],3))
    check("root holder traverses guardian chain",S.RootHolder(staff[3])==p)
end
local function finish()print("[ORACLE_COLOUR] COMPLETE "..count);G.TheSim:Quit()end
local function legacyload()
    local guardrecord={prefab="spider_god",id=90001,x=x,y=y,z=z,data={
        health={health=32123},inventory={equip={hands={prefab="spear"}}},
        container={items={
            [2]={prefab="goldnugget",data={stackable={stack=4}}},
            [3]={prefab="spider_god_bone",id=90002,x=x,y=y,z=z,
                data={leader={followers={90001}}}},
        }},
    }}
    local newents={}
    local g=G.SpawnSaveRecord(guardrecord,newents)
    for _,entry in G.pairs(newents)do entry.entity:LoadPostPass(newents,entry.data)end
    local s=newents[90002].entity
    check("legacy save adopts original guardian",s._godpet==g and g.persists==false)
    check("legacy save ejects own staff from container",s.components.inventoryitem.owner==nil and g.components.container:GetItemInSlot(3)==nil)
    local a,b,c=s.Transform:GetWorldPosition()
    check("legacy load places staff on nearby land",G.TheWorld.Map:IsPassableAtPoint(a,b,c)
        and not G.TheWorld.Map:IsOceanAtPoint(a,b,c) and s:GetDistanceSqToInst(g)<9)
    check("legacy conversion preserves health and gear",g.components.health.currenthealth==32123
        and g.components.inventory:GetEquippedItem(G.EQUIPSLOTS.HANDS).prefab=="spear")
    check("legacy conversion preserves storage",g.components.container:GetItemInSlot(2).components.stackable:StackSize()==4)
    s:Remove()
end
local function reload(payload)
    print("[ORACLE_COLOUR] PHASE disk chain reload")
    -- A full native player record exercises the real OnPreLoad/OnLoad migration
    -- hooks, including collection of pets inside another pet's container.
    player=G.SpawnSaveRecord(payload.player)
    player.userid="KU_ORACLE_COLOUR_TEST";player.Transform:SetPosition(x,y,z)
    check("all nested guardians registered for migration",player.migrationpets~=nil and #player.migrationpets==3)
    verify(player)
    later(1.4,function()
        for i=1,3 do check("nested guardian arrives near root owner "..i,guard[i]:GetDistanceSqToInst(player)<49)end
        local n=0;for _,ent in G.pairs(G.Ents)do
            if ent.prefab=="spider_god" and not ent.components.health:IsDead()then n=n+1 end
        end
        check("exactly three living guardians after reload",n==3)
        legacyload()
        finish()
    end)
end
local function fresh()
    player=makeplayer()
    for i=1,3 do staff[i]=G.SpawnPrefab("spider_god_bone");player.components.inventory:GiveItem(staff[i],i)end
    later(2,function()
        for i=1,3 do guard[i]=bind(staff[i])end
        local colours={1,3,6}
        for i=1,3 do
            C.Set(staff[i],colours[i]);guard[i].components.health:SetCurrentHealth(43000+i*100)
            local item=G.SpawnPrefab("goldnugget");item.components.stackable:SetStackSize(i+2)
            guard[i].components.container:GiveItem(item,2)
            guard[i].components.inventory:Equip(G.SpawnPrefab("spear"))
        end
        check("closed container rejects colour RPC",not C.HandleClick(player,guard[1]))
        guard[1].components.container:Open(player)
        check("button cycles bound pair",C.HandleClick(player,guard[1])and C.Get(staff[1])==2 and C.Get(guard[1])==2)
        check("other pairs retain independent colours",C.Get(staff[2])==3 and C.Get(guard[3])==6)
        check("button is rate limited",not C.HandleClick(player,guard[1]))
        guard[1].components.container:Close()
        -- Construct the old invalid layout bypassing UI admission. The bond fix
        -- must recover the item to walkable ground rather than delete it.
        player.components.inventory:RemoveItem(staff[1],true)
        local box=guard[1].components.container
        local old=box.CanTakeItemInSlot;box.CanTakeItemInSlot=function()return true end
        box:GiveItem(staff[1],3);box.CanTakeItemInSlot=old
        staff[1]:OracleFixBond()
        check("legacy own staff ejected",staff[1].components.inventoryitem.owner==nil and box:GetItemInSlot(3)==nil)
        local sx,sy,sz=staff[1].Transform:GetWorldPosition()
        check("ejected staff lands nearby on ground",G.TheWorld.Map:IsPassableAtPoint(sx,sy,sz)
            and not G.TheWorld.Map:IsOceanAtPoint(sx,sy,sz) and staff[1]:GetDistanceSqToInst(guard[1])<9)
        player.components.inventory:GiveItem(staff[1],1)
        for i=2,3 do
            player.components.inventory:RemoveItem(staff[i],true)
            check("different staff admitted "..i,guard[i-1].components.container:CanTakeItemInSlot(staff[i],1))
            guard[i-1].components.container:GiveItem(staff[i],1)
        end
        verify(player)
        local bag=G.SpawnPrefab("backpack")
        local d=G.SpawnPrefab("spider_god_bone")
        bag.components.container:GiveItem(d,1)
        check("unrelated staff bag accepted as guardian equipment",G.require("oraclesentinel_equipment").Accept(guard[3],bag))
        guard[3].components.inventory:Equip(bag)
        check("unrelated staff allowed inside equipped bag",bag.components.container:CanTakeItemInSlot(d,2))
        check("ancestor staff blocked in descendant equipped bag",not bag.components.container:CanTakeItemInSlot(staff[1],2))
        bag:Remove()
        local saved=player:GetSaveRecord();saved.data.migration={worldid="oracle-source",portalid=1}
        check("nested chain serialized without recursion",saved.data.inventory.items[1].data.petleash~=nil)
        local gone={guard[1],guard[2],guard[3],staff[1],staff[2],staff[3]}
        player:OnDespawn();player:Remove()
        later(.1,function()
            for i,v in G.ipairs(gone)do check("chain entity removed with owner "..i,not v:IsValid())end
            G.TheSim:SetPersistentString("oracle_colour_payload",G.DataDumper({player=saved},nil,true),false,function(ok)
                check("colour chain record saved to disk",ok)
                print("[ORACLE_COLOUR] FIRST_PHASE_COMPLETE "..count);G.TheSim:Quit()
            end)
        end)
    end)
end
AddSimPostInit(function()
    if not G.TheWorld.ismastersim then return end
    later(2,function()
        for _,e in G.pairs(G.Ents)do if e.prefab=="multiplayer_portal"or e.prefab=="cave_exit"then x,y,z=e.Transform:GetWorldPosition();break end end
        G.assert(x,"spawn point")
        G.TheSim:GetPersistentString("oracle_colour_payload",function(ok,data)step(function()
            if ok and data~=""then reload(G.assert(G.loadstring(data))())else fresh()end
        end)end)
    end)
end)
