local G=GLOBAL
local count=0
local function check(name,value)
    G.assert(value,name);count=count+1;print("[ORACLE_FX] PASS "..name)
end
local function step(fn)
    local ok,e=G.xpcall(fn,G.debug.traceback)
    if not ok then print("[ORACLE_FX] FAIL "..G.tostring(e));G.TheSim:Quit()end
end
local function later(t,fn)G.TheWorld:DoTaskInTime(t,function()step(fn)end)end
local originalspawn=G.SpawnPrefab
local effects={}
local counts={}
local names={wendy_sanityaura_buff_on_fx=true,wendy_sanityaura_buff_off_fx=true,
    battlesong_attach=true,battlesong_detach=true,spawn_fx_small=true,shadow_teleport_out=true}
G.SpawnPrefab=function(name,...)
    local ent=originalspawn(name,...)
    if names[name]then counts[name]=(counts[name]or 0)+1;effects[name]=ent end
    return ent
end
local player,hat,mob,staff,guard,x,y,z
local P=G.require("oracleperformance")
local function route(item)
    return player.sg.sg.actionhandlers[G.ACTIONS.PLAY].deststate(player,{invobject=item})
end
local function prepare()
    player=G.SpawnPrefab("wilson");player.userid="KU_ORACLE_FX_TEST"
    player.Transform:SetPosition(x,y,z);player.entity:SetCanSleep(false);player.components.health:SetInvincible(true)
    hat=G.SpawnPrefab("godhat");player.components.inventory:GiveItem(hat)
end
local function finish()
    print("[ORACLE_FX] COMPLETE "..count);G.TheSim:Quit()
end
local function guards()
    staff=G.SpawnPrefab("spider_god_bone");player.components.inventory:GiveItem(staff)
    later(1.6,function()
        guard=staff._godpet;G.assert(guard,"guardian spawned")
        guard:StopBrain();guard.entity:SetCanSleep(false)
        check("fresh guardian has native arrival effect",(counts.spawn_fx_small or 0)>0)
        local n=counts.spawn_fx_small
        for i=1,5 do staff:OracleFixBond()end
        staff:GetSaveRecord()
        check("rebinding and saving do not replay arrival",counts.spawn_fx_small==n)
        G.require("oraclecolours").Set(staff,3)
        guard.components.health:SetCurrentHealth(43210)
        local gear=G.SpawnPrefab("spear");guard.components.inventory:Equip(gear)
        local item=G.SpawnPrefab("goldnugget");item.components.stackable:SetStackSize(7);guard.components.container:GiveItem(item,1)
        local record=staff:GetSaveRecord()
        local last={guard.Transform:GetWorldPosition()}
        local old=guard;staff:Remove()
        check("guardian is removed immediately",not old:IsValid())
        local fx=effects.shadow_teleport_out
        check("departure effect survives without guardian",fx~=nil and fx:IsValid() and fx.entity:GetParent()==nil)
        local a,b,c=fx.Transform:GetWorldPosition()
        check("departure effect retains old position",G.math.abs(a-last[1])<.01 and G.math.abs(c-last[3])<.01)
        check("departure is never persisted",fx.persists==false)
        local loaded=G.SpawnSaveRecord(record)
        check("record load is silent before owner placement",counts.spawn_fx_small==n)
        player.components.inventory:GiveItem(loaded)
        later(1.3,function()
            local g=loaded._godpet
            check("owner arrival plays once",counts.spawn_fx_small==n+1)
            loaded:OracleFixBond();loaded:OracleFixBond()
            check("arrival is not replayed by later fixes",counts.spawn_fx_small==n+1)
            check("health remains intact after FX restore",g.components.health.currenthealth==43210)
            check("storage remains intact after FX restore",g.components.container:GetItemInSlot(1).components.stackable:StackSize()==7)
            check("equipment remains intact after FX restore",g.components.inventory:GetEquippedItem(G.EQUIPSLOTS.HANDS).prefab=="spear")
            check("pair tint remains intact after FX restore",G.require("oraclecolours").Get(g)==3)
            local before=counts.shadow_teleport_out
            loaded.is_snapshot_user_session=true;loaded:Remove()
            check("snapshot removal is silent",counts.shadow_teleport_out==before)
            finish()
        end)
    end)
end
local function recruitment()
    player.sg:GoToState("idle")
    mob=G.SpawnPrefab("spider");mob.Transform:SetPosition(x+1,y,z);mob:StopBrain();mob.entity:SetCanSleep(false)
    local instrument=hat.components.instrument
    local a=counts.battlesong_attach or 0
    mob.sg:GoToState("idle")
    local hp=mob.components.health.currenthealth
    local attacked=0;mob:ListenForEvent("attacked",function()attacked=attacked+1 end)
    instrument.onheard(mob,player)
    check("successful recruitment has native attach FX",counts.battlesong_attach==a+1 and mob.components.follower.leader==player)
    check("recruited target plays native hit state",mob.sg.currentstate.name=="hit")
    check("reaction causes no damage or attacked event",mob.components.health.currenthealth==hp and attacked==0)
    check("reaction keeps newly established loyalty",mob.components.follower.leader==player)
    a=counts.battlesong_attach;instrument.onheard(mob,player)
    check("renewal does not repeat recruitment FX",counts.battlesong_attach==a)
    local record=mob:GetSaveRecord();mob:Remove()
    mob=G.SpawnSaveRecord(record);mob:StopBrain()
    check("recruitment reload does not replay capture",counts.battlesong_attach==a)
    later(.2,function()
        local d=counts.battlesong_detach or 0
        if mob.components.follower.leader~=player then mob.components.follower:SetLeader(player)end
        mob.components.follower:SetLeader(nil)
        check("dismissal has native detach FX",counts.battlesong_detach==d+1)
        check("original creature state restored",mob:HasTag("monster")and mob:HasTag("hostile"))
        mob:Remove()
        for _,prefab in G.ipairs({"pigman","hound"})do
            local other=G.SpawnPrefab(prefab);other.Transform:SetPosition(x+2,y,z)
            other:StopBrain();other.sg:GoToState("idle")
            local health=other.components.health.currenthealth
            local hits=0;other:ListenForEvent("attacked",function()hits=hits+1 end)
            instrument.onheard(other,player)
            check(prefab.." recruitment reacts without harming loyalty",other.sg.currentstate.name=="hit"
                and other.components.follower.leader==player and other.components.health.currenthealth==health and hits==0)
            other:Remove()
        end
        guards()
    end)
end
local function performance()
    player.sg:GoToState("idle")
    check("circlet routes to C animation",route(hat)==P.NAME)
    local flute=G.SpawnPrefab("panflute")
    check("ordinary pan flute keeps native action",route(flute)=="play_flute")
    flute:Remove()
    local riding=player.components.rider.IsRiding
    player.components.rider.IsRiding=function()return true end
    check("mounted circlet keeps native supported action",route(hat)=="play_flute")
    player.components.rider.IsRiding=riding
    local preview,cleared,flattened=false,false,false
    local fake={components={locomotor={Stop=function()end},inventory={GetEquippedItem=function()end}},
        AnimState={Hide=function()end,Show=function()end,PlayAnimation=function()end,PushAnimation=function()end},
        entity={FlattenMovementPrediction=function()flattened=true;return true end},
        sg={statemem={},SetTimeout=function()end,ServerStateMatches=function()return true end,
            GoToState=function(self,name)self.dest=name end},
        PerformPreviewBufferedAction=function()preview=true end,ClearBufferedAction=function()cleared=true end}
    local client=P.ClientState();client.onenter(fake);client.onupdate(fake)
    check("client predicts then yields to matching server state",preview and flattened and fake.sg.dest=="idle"and fake.sg.statemem.matched)
    client.onexit(fake)
    client.ontimeout(fake)
    check("client timeout clears failed prediction",cleared and fake.sg.dest=="idle")
    local playcount=0
    local previous=hat.components.instrument.onplayed
    hat.components.instrument:SetOnPlayedFn(function(inst,p)playcount=playcount+1;previous(inst,p)end)
    local function play()
        player.bufferedaction=G.BufferedAction(player,nil,G.ACTIONS.PLAY,hat)
        player.sg:GoToState(P.NAME)
    end
    play()
    later(.4,function()
        print("[ORACLE_FX] DEBUG state",player.sg.currentstate.name,"anim",G.tostring(player.AnimState:IsCurrentAnimation("channelcast_oh_idle")),"owner",G.tostring(hat.components.inventoryitem:GetGrandOwner()),"player",G.tostring(player),"asleep",player:IsAsleep())
        check("C starts with native channel animation",player.AnimState:IsCurrentAnimation("channelcast_oh_idle"))
        check("effect not applied before native timing",playcount==0)
        player.sg:GoToState("idle");player:ClearBufferedAction()
        later(.8,function()
            check("interrupted windup never recruits",playcount==0)
            play()
            later(1.2,function()
                check("native one-second effect timing retained",playcount==1)
                check("new state is still animating after cast",player.sg.currentstate.name==P.NAME)
                player.sg:GoToState("idle");player:ClearBufferedAction()
                later(.3,function()
                    check("interruption exits action safely",player.sg.currentstate.name=="idle")
                    play()
                    later(4,function()
                        check("normal cast performs exactly once",playcount==2)
                        check("normal cast completes to idle",player.sg.currentstate.name=="idle")
                        -- Full native inventory reload must not replay equip FX.
                        player.components.inventory:Equip(hat)
                        local inv=player.components.inventory:OnSave()
                        player.components.inventory:Unequip(G.EQUIPSLOTS.HEAD)
                        player.components.inventory:RemoveItem(hat,true);hat:Remove()
                        local before=counts.wendy_sanityaura_buff_on_fx or 0
                        local restored=G.SpawnPrefab("wilson");restored.Transform:SetPosition(x,y,z)
                        restored.components.inventory:OnLoad(inv)
                        check("saved equipment load does not replay wear FX",(counts.wendy_sanityaura_buff_on_fx or 0)==before)
                        restored:Remove()
                        hat=G.SpawnPrefab("godhat");player.components.inventory:GiveItem(hat)
                        recruitment()
                    end)
                end)
            end)
        end)
    end)
end
AddSimPostInit(function()
    if not G.TheWorld.ismastersim then return end
    later(2,function()
        for _,e in G.pairs(G.Ents)do if e.prefab=="multiplayer_portal"then x,y,z=e.Transform:GetWorldPosition();break end end
        G.assert(x,"portal exists");prepare()
        later(.2,function()
            player.components.inventory:Equip(hat)
            check("wear uses native Wendy gain effect",counts.wendy_sanityaura_buff_on_fx==1)
            later(.3,function()
                check("wear preserves native equip action",player.sg.currentstate.name=="item_hat")
                player.sg:GoToState("idle")
                local removed=player.components.inventory:Unequip(G.EQUIPSLOTS.HEAD)
                player.components.inventory:GiveItem(removed)
                check("unequip uses native Wendy loss effect",counts.wendy_sanityaura_buff_off_fx==1)
                later(.3,function()performance()end)
            end)
        end)
    end)
end)
