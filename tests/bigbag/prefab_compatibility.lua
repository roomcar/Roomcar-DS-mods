-- Real DST Container/Stackable/Named, with the mod's actual prefab constructors.
package.path="_BigBag--DST/scripts/?.lua;"..assert(arg[1]).."/?.lua;"..package.path
require("class")
TUNING={STACK_SIZE_MEDITEM=40,ROOMCAR_BIGBAG={WALKSPEED=.75}}
MAXUINT=4294967295;EQUIPSLOTS={BODY="body"}
Vector3=function(x,y,z)return {x=x,y=y,z=z or 0}end
TheWorld={ismastersim=true};GetGameModeProperty=function()return false end
TheNet={GetNetIdForUser=function(_,id)return id end}
STRINGS={NAMES={BIGBAG="大背包",ROOMCAR_BIGBAG_NEW="大背包-新版"}}
local definitions={params={}}
definitions.widgetsetup=function(c,id)
    c:SetNumSlots(id=="roomcar_expeditionbag" and 32 or 64);c.type="pack";c.issidewidget=true;c.widget={slotpos={}};c.itemtestfn=function(_,i)return not i:HasTag("bigbag")end
    if id=="roomcar_expeditionbag"then c.itemtestfn=require("expedition_data").ItemTest end
end
package.loaded.containers=definitions
local Container=require("components/container")
local Stackable=require("components/stackable")
local Named=require("components/named")
local noop=function()end
local function calls()return setmetatable({},{__index=function()return noop end})end
local constructors={container=Container,named=Named}
constructors.preserver=function()
    return {SetPerishRateMultiplier=function(self,n)self.multiplier=n end}
end
constructors.inventoryitem=function(inst)
    return {cangoincontainer=true,SetOnPutInInventoryFn=noop,SetOnDroppedFn=noop,
        ChangeImageName=function(self,n)self.imagename=n end,
        OnRemoved=function(self)self.owner=nil end,OnPutInInventory=function(self,owner)self.owner=owner end}
end
constructors.equippable=function()
    return {SetOnEquip=function(self,fn)self.onequipfn=fn end,SetOnUnequip=function(self,fn)self.onunequipfn=fn end,SetOnEquipToModel=noop}
end
CreateEntity=function()
    local inst={entity=calls(),AnimState=calls(),MiniMapEntity=calls(),components={},replica={},tags={}}
    inst.replica.container={SetCanBeOpened=noop,SetSkipOpenSnd=noop,SetSkipCloseSnd=noop,WidgetSetup=noop}
    inst.replica.named={SetName=function(_,n,a)inst.netname,inst.author=n,a end}
    function inst:AddTag(t)self.tags[t]=true end
    function inst:HasTag(t)return self.tags[t]end
    function inst:ListenForEvent(event,fn)self.listeners=self.listeners or {};self.listeners[event]=fn end
    function inst:PushEvent(event,data)if self.listeners and self.listeners[event] then self.listeners[event](self,data)end end
    function inst:DoTaskInTime(_,fn)self.pending=fn;return {}end
    function inst:IsValid()return true end
    function inst:GetPosition()return {x=0,y=0,z=0}end
    function inst:AddComponent(n)self.components[n]=constructors[n] and constructors[n](self) or {}end
    return inst
end
MakeInventoryPhysics=noop;MakeInventoryFloatable=noop;Asset=function(...)return {...}end
Prefab=function(id,fn,assets)return {name=id,fn=fn,assets=assets}end
local classic=dofile("_BigBag--DST/scripts/prefabs/bigbag.lua")
local modern=dofile("_BigBag--DST/scripts/prefabs/roomcar_bigbag_new.lua")
local function spawn(def)local b=def.fn();b.prefab=def.name;return b end
net_tinybyte=function()local value=0;return {set=function(_,n)value=n end,value=function()return value end}end
local expedition=dofile("_BigBag--DST/scripts/prefabs/roomcar_expeditionbag.lua")
local function item(prefab,count,custom)
    local i=CreateEntity();i.prefab=prefab;i.persists=true
    i.replica.stackable={SetStackSize=noop,SetMaxSize=noop,SetIgnoreMaxSize=noop}
    i:AddComponent("inventoryitem");i.components.stackable=Stackable(i);i.components.stackable.maxsize=40
    i.components.stackable:SetStackSize(count);i.custom=custom
    function i:GetSaveRecord()return {prefab=self.prefab,data={stackable=self.components.stackable:OnSave(),custom=self.custom}}end
    return i
end
SpawnSaveRecord=function(record)
    local i=item(record.prefab,1,record.data.custom);i.components.stackable:OnLoad(record.data.stackable);return i
end
local passed=0
local function test(name,fn)fn();passed=passed+1;print("PASS "..name)end
test("original entity identity, components and constructor preserve native serialization",function()
    assert(classic.name=="bigbag" and modern.name=="roomcar_bigbag_new")
    for _,def in ipairs({classic,modern})do
        local b=spawn(def);assert(b.components.container:GetNumSlots()==64)
        assert(b.components.named and b.components.inventoryitem.imagename==(def==modern and "roomcar_expeditionbag" or "bigbag"))
        assert(b.components.equippable.walkspeedmult==.75)
        if def==classic then assert(b.OnSave==nil and b.OnLoad==nil and b.roomcar_bagcolor==nil)
        else assert(b.roomcar_bagcolor:value()==1 and b.OnSave and b.OnLoad) end
        assert(b:HasTag("bigbag") and b:HasTag("backpack"))
        assert(require("bigbag_util").GetEquippedBag({equipslots={body=b}})==b)
        assert(require("expedition_data").IsBag(b))
    end
end)
test("1.5 and 1.7 native records survive classic load/save, sparse slots, overstack and custom metadata",function()
    for _,version in ipairs({"1.5","1.7"})do
        local record={prefab="bigbag",data={container={items={
            [1]={prefab="berries",data={stackable={stack=3},custom={fresh=.25,skin="kept"}}},
            [64]={prefab="twigs",data={stackable={stack=999},custom={unique="slot64",charges=7}}},
        }}}}
        if version=="1.7" then record.data.named={name="矿石备用包",name_author_netid="KU_test"} end
        local b=spawn(classic);b.components.container:OnLoad(record.data.container,{})
        b.components.named:OnLoad(record.data.named)
        assert(b.prefab==record.prefab and b.components.container:GetItemInSlot(2)==nil)
        local x=b.components.container:GetItemInSlot(64)
        assert(x.components.stackable:StackSize()==999 and x.custom.unique=="slot64" and x.custom.charges==7)
        local save=b.components.container:OnSave()
        assert(save.items[1].data.custom.fresh==.25 and save.items[1].data.custom.skin=="kept")
        assert(save.items[64].data.stackable.stack==999 and save.items[2]==nil)
        local named=b.components.named:OnSave()
        if version=="1.7" then assert(b.name=="矿石备用包" and named.name_author_netid=="KU_test") else assert(named==nil)end
        local c=spawn(classic);c.components.container:OnLoad(save,{});c.components.named:OnLoad(named)
        assert(c.components.container:GetItemInSlot(64).components.stackable:StackSize()==999)
    end
end)
test("all 64 entities retain slot ordering and independent names across modern save/load",function()
    local b=spawn(modern)
    for n=1,64 do assert(b.components.container:GiveItem(item("twigs",n*20,{index=n}),n))end
    b.components.named:SetName("新包","KU_new")
    local c=spawn(modern);c.components.container:OnLoad(b.components.container:OnSave(),{})
    c.components.named:OnLoad(b.components.named:OnSave())
    for n=1,64 do local i=c.components.container:GetItemInSlot(n);assert(i.custom.index==n and i.components.stackable:StackSize()==n*20)end
    assert(c.name=="新包" and c.author=="KU_new")
    local player={userid="KU_new",IsValid=function()return true end,HasTag=function()return false end}
    c.components.inventoryitem.owner=player;c.components.container.IsOpenedBy=function()return true end
    assert(require("bigbag_naming").CanEdit(player,c))
end)
test("both 64-slot bags refresh on actual Container itemget when enabled and preserve without shrinking stacks",function()
    local config=TUNING.ROOMCAR_BIGBAG
    config.FRESH=true;config.STACK=true;config.REPAIR=true
    for _,def in ipairs({classic,modern})do
        local b=spawn(def);assert(b.components.preserver.multiplier==0)
        local food=item("berries",3);local fresh,repair=.15,.2
        food.components.perishable={SetPercent=function(_,n)fresh=n end}
        food.components.finiteuses={SetPercent=function(_,n)repair=n end}
        assert(b.components.container:GiveItem(food,64));assert(b.pending and b._refresh_task)
        b.pending();assert(fresh==1 and repair==1 and food.components.stackable:StackSize()==40)
        food.components.stackable:SetStackSize(999);require("bigbag_util").RefreshContents(b)
        assert(food.components.stackable:StackSize()==999)
    end
    config.FRESH=false;config.STACK=false;config.REPAIR=true
    for _,def in ipairs({classic,modern})do
        local b=spawn(def);assert(b.components.preserver==nil)
        local food=item("berries",3);local fresh=.15
        food.components.perishable={SetPercent=function()error("disabled freshness changed")end}
        assert(b.components.container:GiveItem(food,1));assert(b.pending==nil)
        require("bigbag_util").RefreshContents(b);assert(fresh==.15 and food.components.stackable:StackSize()==3)
    end
end)
test("Expedition fits real native player pockets but cannot be nested in containers",function()
    local Inventory=require("components/inventory")
    local b=spawn(expedition)
    local pocket={maxslots=15,GetItemInSlot=function()end}
    assert(b.components.inventoryitem.cangoincontainer and b.components.inventoryitem.canonlygoinpocket)
    assert(Inventory.CanTakeItemInSlot(pocket,b,1) and Inventory.CanTakeItemInSlot(pocket,b,15))
    assert(not Inventory.CanTakeItemInSlot(pocket,b,16))
    assert(not spawn(classic).components.container:CanTakeItemInSlot(b,1))
    assert(not spawn(modern).components.container:CanTakeItemInSlot(b,1))
    assert(not b.components.container:CanTakeItemInSlot(spawn(expedition),29))
    assert(b.components.equippable.walkspeedmult==1 and b.components.preserver==nil)
end)
test("Expedition 32 old slot records, names and colour survive the new layout without conversion",function()
    local b=spawn(expedition)
    local saved={items={}}
    for i=1,32 do saved.items[i]={prefab="twigs",data={stackable={stack=i*20},custom={index=i}}} end
    b.components.container:OnLoad(saved,{})
    b.components.named:OnLoad({name="远行补给",name_author_netid="KU_test"})
    b:OnLoad({color=4})
    local roundtrip=b.components.container:OnSave()
    for i=1,32 do assert(roundtrip.items[i].data.custom.index==i and roundtrip.items[i].data.stackable.stack==i*20)end
    assert(b.name=="远行补给" and b.roomcar_bagcolor:value()==4)
end)
test("client constructors provide the network entity and leave server components to the master",function()
    TheWorld.ismastersim=false
    for _,def in ipairs({classic,modern,expedition})do
        local b=spawn(def);assert(b.components.container==nil and b:HasTag("backpack"))
        if def==modern or def==expedition then assert(b.roomcar_bagcolor~=nil)end
    end
end)

-- Art integration uses the actual prefab constructor and equip callbacks.
local function ArtBag(def)
    TheWorld.ismastersim=true
    local oldCreate=CreateEntity
    CreateEntity=function()
        local b=oldCreate()
        b.AnimState.SetBuild=function(_,n)b.artbuild=n end
        b.MiniMapEntity.SetIcon=function(_,n)b.artminimap=n end
        return b
    end
    local b=spawn(def or expedition);CreateEntity=oldCreate
    return b
end
local function ArtOwner(b)
    local o={AnimState={},overrides={},colours={},PushEvent=function()end}
    o.AnimState.OverrideSymbol=function(_,s,build,source)o.overrides[s]={build,source}end
    o.AnimState.SetSymbolMultColour=function(_,s,r,g,bl,a)o.colours[s]={r,g,bl,a}end
    o.AnimState.ClearOverrideSymbol=function(_,s)o.overrides[s]=nil end
    b.components.inventoryitem.owner=o
    b.components.equippable.IsEquipped=function()return true end
    b.components.container.Open=function()end;b.components.container.Close=function()end
    return o
end
test("Expedition constructor uses its unique world build, inventory icon and minimap icon",function()
    local b=ArtBag()
    assert(b.artbuild=="swap_roomcar_expeditionbag_gray")
    assert(b.artminimap=="roomcar_expeditionbag_gray.tex")
    assert(b.components.inventoryitem.imagename=="roomcar_expeditionbag_gray")
    assert(b.components.inventoryitem.atlasname=="images/inventoryimages/roomcar_expeditionbag_gray.xml")
    assert(b.roomcar_bagcolor:value()==1)
end)

test("modern bag uses the new body, straps, ground build and icons; classic assets remain original",function()
    local b=ArtBag(modern)
    assert(b.artbuild=="swap_roomcar_expeditionbag" and b.artminimap=="roomcar_expeditionbag.tex")
    assert(b.components.inventoryitem.imagename=="roomcar_expeditionbag")
    local o=ArtOwner(b);b.components.equippable.onequipfn(b,o)
    for _,symbol in ipairs({"swap_body","backpack"})do
        assert(o.overrides[symbol][1]=="swap_roomcar_expeditionbag" and o.overrides[symbol][2]==symbol)
    end
    local classicbag=ArtBag(classic)
    assert(classicbag.artbuild=="swap_bigbag" and classicbag.artminimap=="bigbag.tex")
    assert(classicbag.roomcar_bagcolor==nil)
end)

test("modern colour persists independently of native 64-slot/name data and old records default to Natural",function()
    local b=ArtBag(modern)
    local ground
    b.AnimState.SetMultColour=function(_,r,g,blue,a)ground={r,g,blue,a}end
    local o=ArtOwner(b)
    b:SetBagColor(4)
    assert(ground[1]==.55 and ground[2]==.7 and ground[3]==1)
    for _,symbol in ipairs({"swap_body","backpack"})do assert(o.colours[symbol][1]==.55)end
    assert(b.components.container:GiveItem(item("twigs",999,{kept=true}),64))
    b.components.named:SetName("蓝色矿石包","KU_test")
    local saved={};b:OnSave(saved);assert(saved.color==4)
    local restored=ArtBag(modern)
    restored:OnLoad(saved)
    restored.components.container:OnLoad(b.components.container:OnSave(),{})
    restored.components.named:OnLoad(b.components.named:OnSave())
    assert(restored.roomcar_bagcolor:value()==4 and restored.name=="蓝色矿石包")
    assert(restored.components.container:GetItemInSlot(64).components.stackable:StackSize()==999)
    assert(restored.components.container:GetItemInSlot(64).custom.kept)
    restored:OnLoad(nil);assert(restored.roomcar_bagcolor:value()==1)
    restored:OnLoad({color=999});assert(restored.roomcar_bagcolor:value()==1)
    b.components.equippable.onunequipfn(b,o)
    for _,symbol in ipairs({"swap_body","backpack"})do
        assert(o.overrides[symbol]==nil and o.colours[symbol][1]==1 and o.colours[symbol][2]==1 and o.colours[symbol][3]==1)
    end
end)
test("Expedition equips the regular backpack swap_body only, keeping separated non-crossed strap frames",function()
    local b=ArtBag();local o=ArtOwner(b)
    b.components.equippable.onequipfn(b,o)
    assert(o.overrides.swap_body[1]=="swap_roomcar_expeditionbag_gray" and o.overrides.swap_body[2]=="swap_body")
    assert(o.overrides.backpack==nil,"must not apply Krampus auxiliary straps")
    b:OnLoad({color=4})
    for _,s in ipairs({"swap_body"})do
        assert(o.colours[s][1]==.55 and o.colours[s][2]==.7 and o.colours[s][3]==1)
    end
end)

test("new gray Expedition defaults to Natural; saved colours and legacy no-colour records remain loadable",function()
    local b=ArtBag()
    assert(b.roomcar_bagcolor:value()==1)
    b:OnLoad({color=5});assert(b.roomcar_bagcolor:value()==5)
    local saved={};b:OnSave(saved);assert(saved.color==5)
    b:OnLoad(nil);assert(b.roomcar_bagcolor:value()==1)
    b:OnLoad({color=999});assert(b.roomcar_bagcolor:value()==1)
end)
test("Expedition unequip clears both overrides and colour, retaining native slot count and save colour",function()
    local b=ArtBag();local o=ArtOwner(b)
    b.components.equippable.onequipfn(b,o);b:SetBagColor(4)
    b.components.equippable.onunequipfn(b,o)
    for _,s in ipairs({"swap_body","backpack"})do
        assert(o.overrides[s]==nil)
        assert(o.colours[s][1]==1 and o.colours[s][2]==1 and o.colours[s][3]==1)
    end
    assert(b.components.container:GetNumSlots()==32)
    local saved={};b:OnSave(saved);assert(saved.color==4)
end)

print(passed.." prefab/save compatibility tests passed (real DST components; mocked engine entities)")
