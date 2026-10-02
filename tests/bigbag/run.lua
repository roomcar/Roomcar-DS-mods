-- Run from repository root with Lua 5.1; arg[1] is the matching DST scripts dir.
local dst = assert(arg[1], "Pass the DST scripts directory")
package.path = "_BigBag--DST/scripts/?.lua;" .. dst .. "/?.lua;" .. package.path
require("class")
TUNING = { STACK_SIZE_MEDITEM = 40, ROOMCAR_BIGBAG = { GIVE = true } }
MAXUINT = 4294967295
GetGameModeProperty = function() return false end
package.loaded.containers = {}
local Stackable = require("components/stackable")
local Container = require("components/container")
local util = require("bigbag_util")
local supply = require("bigbag_supply")
local passed = 0
local function test(name, fn)
    fn()
    passed = passed + 1
    print("PASS " .. name)
end
local function eq(a, b) assert(a == b, tostring(a) .. " ~= " .. tostring(b)) end
local function item(prefab, count, limit)
    local inst = { prefab = prefab, components = {}, replica = {}, events = {} }
    function inst:PushEvent(name, data) self.events[#self.events + 1] = {name, data} end
    function inst:ListenForEvent() end
    function inst:IsValid() return not self.removed end
    function inst:Remove() self.removed = true end
    function inst:HasTag() return false end
    function inst:GetPosition() return {x=0,y=0,z=0} end
    inst.replica.stackable = {SetStackSize=function() end,SetMaxSize=function() end,SetIgnoreMaxSize=function() end}
    inst.components.inventoryitem = {
        cangoincontainer = true, OnRemoved = function(self) self.owner = nil end,
        OnPutInInventory = function(self, owner) self.owner = owner end,
    }
    if count then
        inst.components.stackable = Stackable(inst)
        inst.components.stackable.maxsize = limit or 40
        inst.components.stackable:SetStackSize(count)
    end
    return inst
end
local function bag()
    local inst = item("bigbag")
    inst.replica.container = { SetCanBeOpened=function()end,SetSkipOpenSnd=function()end,SetSkipCloseSnd=function()end }
    inst.components.container = Container(inst)
    inst.components.container:SetNumSlots(64)
    return inst
end

test("fill is monotonic, including overstacked saves", function()
    for _, count in ipairs({1,40,999}) do
        local v=item("cutgrass", count)
        util.FillStack(v)
        eq(v.components.stackable:StackSize(),math.max(count,40))
    end
end)
test("infinite and invalid stack maxima cannot corrupt saves", function()
    for _, limit in ipairs({math.huge,0,-1}) do
        local v=item("cutgrass",8,limit)
        util.FillStack(v)
        eq(v.components.stackable:StackSize(),8)
    end
    local v=item("cutgrass",8);v.components.stackable:SetIgnoreMaxSize(true)
    util.FillStack(v);eq(v.components.stackable:StackSize(),40)
end)
test("disabled options do not mutate quantities or durability", function()
    TUNING.ROOMCAR_BIGBAG={STACK=false,FRESH=false}
    local b=bag();local v=item("berries",999)
    v.components.perishable={SetPercent=function()error("unexpected freshness write")end}
    b.components.container:GiveItem(v,64);util.RefreshContents(b)
    eq(v.components.stackable:StackSize(),999)
end)
test("freshness and durability are independent", function()
    local v=item("berries",1)
    local fresh,repair=0,0
    v.components.perishable={SetPercent=function()fresh=fresh+1 end}
    v.components.finiteuses={SetPercent=function()repair=repair+1 end}
    util.RefreshItem(v,false);eq(fresh,1);eq(repair,0)
    util.RefreshItem(v,true);eq(fresh,2);eq(repair,1)
    util.RefreshItem(item("nonperishable"),true)
end)
test("sorting preserves entity identity, stack sizes, and all 64 slots", function()
    local b=bag();local c=b.components.container
    local original={}
    for n=1,64 do
        local v=item(n%2==0 and "berries" or "twigs",n*20)
        v.custom_save_data="unique-"..n
        original[v]=n*20;c:GiveItem(v,n)
    end
    util.Sort(b)
    local count=0
    for n=1,64 do
        local v=c:GetItemInSlot(n)
        assert(original[v]);eq(v.components.stackable:StackSize(),original[v]);assert(v.custom_save_data)
        count=count+1
        if n>1 then assert(c:GetItemInSlot(n-1).prefab<=v.prefab) end
    end
    eq(count,64)
end)
test("vanilla container serialization preserves sparse slot 64 and oversized stacks", function()
    local b=bag();local c=b.components.container
    local v=item("twigs",999);v.persists=true
    function v:GetSaveRecord()return {prefab=self.prefab,stack=self.components.stackable:OnSave()}end
    c:GiveItem(v,64)
    local saved=c:OnSave()
    SpawnSaveRecord=function(data)
        local restored=item(data.prefab,1)
        restored.components.stackable:OnLoad(data.stack)
        return restored
    end
    local restored=bag().components.container
    restored:OnLoad(saved,{})
    eq(restored:GetItemInSlot(64).components.stackable:StackSize(),999)
    eq(restored:GetItemInSlot(1),nil)
end)

local spawned, clock, counts = {}, 10, {cutgrass=3}
GetTime=function()return clock end
RoundBiasedUp=function(x)return math.floor(x+.5)end
CanPrototypeRecipe=function()return true end
SpawnPrefab=function(prefab)local v=item(prefab,1);spawned[#spawned+1]=v;return v end
local player=item("wilson")
local equipped=bag()
local inventory={equipslots={body=equipped}}
function inventory:IsOpenedBy()return true end
function inventory:Has(prefab,amount)local n=counts[prefab]or 0;return n>=amount,n end
function inventory:GiveItem(v)counts[v.prefab]=(counts[v.prefab]or 0)+v.components.stackable:StackSize()end
player.components.inventory=inventory
local builder={inst=player,ingredientmod=1,accessible_tech_trees={}}
function builder:KnowsRecipe()return true end
function builder:CanLearn()return true end
function builder:IsBuildBuffered()return false end
function builder:HasCharacterIngredient()return false end
function builder:HasTechIngredient()return false end
local recipe={name="test",ingredients={{type="cutgrass",amount=10}},character_ingredients={},tech_ingredients={}}
test("supplies generate only missing materials on the server", function()
    TUNING.ROOMCAR_BIGBAG={GIVE=true}
    supply.Supply(builder,recipe);eq(counts.cutgrass,10);eq(#spawned,1)
    supply.Supply(builder,recipe);eq(#spawned,1)
end)
test("unequipped bags and character costs never grant supplies", function()
    clock=11;counts.cutgrass=0;inventory.equipslots={}
    supply.Supply(builder,recipe);eq(counts.cutgrass,0)
    inventory.equipslots={body=equipped};recipe.character_ingredients={{type="health",amount=20}}
    supply.Supply(builder,recipe);eq(counts.cutgrass,0)
    recipe.character_ingredients={};recipe.tech_ingredients={{type="test"}}
    supply.Supply(builder,recipe);eq(counts.cutgrass,0)
    recipe.tech_ingredients={}
end)
test("unknown recipes cannot receive materials", function()
    builder.KnowsRecipe=function()return false end
    builder.CanLearn=function()return false end
    supply.Supply(builder,recipe);eq(counts.cutgrass,0)
end)
print(string.format("%d tests passed (official Container and Stackable implementations)",passed))
