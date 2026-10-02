-- Run on an isolated dedicated server, never on a player's live world.
local data=require("expedition_data")
local created={}
local function spawn(name)
    local item=assert(SpawnPrefab(name),name)
    created[#created+1]=item
    return item
end
local function check(value,message) assert(value,message) end
local ok,err=pcall(function()
    local original=TUNING.ROOMCAR_BIGBAG
    local saved={STACK=original.STACK,FRESH=original.FRESH,REPAIR=original.REPAIR,LIGHT=original.LIGHT}
    original.STACK,original.FRESH,original.REPAIR,original.LIGHT=true,true,true,true
    local bag=spawn(data.PREFAB)
    for k,v in pairs(saved) do original[k]=v end
    check(bag.components.equippable.walkspeedmult==1,"unexpected speed penalty")
    check(bag.components.preserver==nil and bag.Light==nil and not bag:HasTag("fridge"),"inherited power options")
    local c=bag.components.container
    check(c:GetNumSlots()==32,"slot count")
    local samples={"hambat","tentaclespike","footballhat","footballhat","beefalohat","armorwood",
        "goldenaxe","goldenpickaxe","goldenshovel","hammer","cane","umbrella",
        "lantern","minerhat","heatrock","sewing_kit","baconeggs","perogies","taffy","bandage",
        "cutgrass","twigs","log","rocks","flint","goldnugget","lightbulb","nightmarefuel",
        "reviver","icestaff","amulet","silk"}
    for slot,name in ipairs(samples) do
        local item=spawn(name)
        if item.components.stackable then item.components.stackable:SetStackSize(slot==28 and 999 or 8) end
        check(c:GiveItem(item,slot,nil,false),"rejected "..name.." in "..slot)
    end
    check(not c:CanTakeItemInSlot(spawn("axe"),3),"tool accepted in head slot")
    check(not c:CanTakeItemInSlot(spawn("bigbag"),29),"nested Big Bag")
    check(not c:CanTakeItemInSlot(spawn(data.PREFAB),29),"nested Expedition Bag")
    check(c:CanTakeItemInSlot(c:GetItemInSlot(14),3),"mining hat must also fit head slot")
    local food=c:GetItemInSlot(17)
    food.components.perishable:SetPercent(.35)
    bag:SetBagColor(4)
    bag.components.named:SetName("洞穴远行包")
    local restored=assert(SpawnSaveRecord(bag:GetSaveRecord()))
    created[#created+1]=restored
    for slot,name in ipairs(samples) do
        local v=restored.components.container:GetItemInSlot(slot)
        check(v and v.prefab==name,"roundtrip slot "..slot)
    end
    check(restored.roomcar_bagcolor:value()==4 and restored.components.named.name=="洞穴远行包","name/color roundtrip")
    check(restored.components.container:GetItemInSlot(28).components.stackable:StackSize()==999,"overstack roundtrip")
    check(math.abs(restored.components.container:GetItemInSlot(17).components.perishable:GetPercent()-.35)<.001,"freshness changed")
    print("EXPEDITION_PASS: 32 classified slots, normal powers, name/color/contents save roundtrip")
    -- Spoilage must stay in its original slot even when every other slot is full.
    c:GetItemInSlot(1).components.perishable:Perish()
    check(c:GetItemInSlot(1) and c:GetItemInSlot(1).prefab=="spoiled_food","ham bat rot dropped")
    c:GetItemInSlot(27).components.perishable:Perish()
    check(c:GetItemInSlot(27) and c:GetItemInSlot(27).prefab=="spoiled_food","fuel rot dropped")
    local rotcopy=assert(SpawnSaveRecord(bag:GetSaveRecord()));created[#created+1]=rotcopy
    check(rotcopy.components.container:GetItemInSlot(1).prefab=="spoiled_food","saved rot ejected")
    print("EXPEDITION_PASS: full-bag spoilage and saved category changes preserve contents")
    local automatic=spawn(data.PREFAB).components.container
    local pairs_to_check={{"goldenaxe",7},{"hammer",8},{"minerhat",13},{"lantern",14},{"lightbulb",27},{"nightmarefuel",28},{"cutgrass",21},{"bandage",20}}
    for _,entry in ipairs(pairs_to_check) do
        local item=spawn(entry[1])
        check(automatic:GetSpecificSlotForItem(item)==entry[2],"automatic destination "..entry[1])
        check(automatic:GiveItem(item,nil,nil,false),"automatic give "..entry[1])
    end
    local more=spawn("lightbulb");more.components.stackable:SetStackSize(10)
    check(automatic:GiveItem(more,nil,nil,false),"merge failed")
    check(automatic:GetItemInSlot(27).components.stackable:StackSize()==11,"merge count")
    local ore=spawn("goldnugget");ore.components.stackable:SetStackSize(999)
    check(automatic:GiveItem(ore,nil,nil,false),"overstack insertion")
    check(ore.components.stackable:StackSize()==999,"overstack shrank")
    print("EXPEDITION_PASS: automatic destinations, occupied slots, stacks, overflow")
    -- Real native inventory/controller equipment routing, with full pockets.
    local crafter=spawn("wilson")
    local builder=crafter.components.builder
    local recipe=assert(AllRecipes[data.PREFAB])
    check(recipe.level.SCIENCE==2,"recipe technology")
    for name,count in pairs({pigskin=4,silk=8,rope=4}) do
        local material=spawn(name);material.components.stackable:SetStackSize(count)
        crafter.components.inventory:GiveItem(material)
    end
    builder:UnlockRecipe(data.PREFAB)
    check(builder:DoBuild(data.PREFAB),"native crafting failed")
    local product=assert(crafter.components.inventory:GetOverflowContainer()).inst
    created[#created+1]=product
    check(product.prefab==data.PREFAB,"wrong crafting product")
    check(not crafter.components.inventory:Has("pigskin",1),"ingredients not consumed")
    local naming=require("bigbag_naming")
    check(naming.CanEdit(crafter,product),"owner cannot edit")
    check(not naming.CanEdit(spawn("wilson"),product),"non-owner can edit")
    product.components.container:Close()
    check(not naming.CanEdit(crafter,product),"closed bag can be edited")
    print("EXPEDITION_PASS: native recipe, ingredient consumption and edit ownership")
    local player=spawn("wilson")
    player.components.health:SetInvincible(true)
    local inv=player.components.inventory
    inv:Open()
    local swapbag=spawn(data.PREFAB)
    inv:Equip(swapbag)
    local sc=swapbag.components.container
    for i=1,inv.maxslots do check(inv:GiveItem(spawn("flint"),i),"fill pocket") end
    -- Use non-stackables to guarantee genuinely full player pockets.
    for i=1,inv.maxslots do
        local v=inv:GetItemInSlot(i)
        if v then inv:RemoveItem(v,true);v:Remove() end
        check(inv:GiveItem(spawn("axe"),i),"fill equipment pocket")
    end
    local cane=spawn("cane");inv:Equip(cane)
    local sword=spawn("spear");check(sc:GiveItem(sword,1,nil,false))
    local pc=player.components.playercontroller
    local originalcontroller=pc and pc.isclientcontrollerattached
    if pc then pc.isclientcontrollerattached=true end
    check(inv:Equip(sword)==true,"weapon swap failed")
    check(cane.components.inventoryitem.owner==swapbag and sc:GetItemSlot(cane)==11,"cane did not return to travel slot")
    for slot=11,12 do
        local v=sc:GetItemInSlot(slot)
        if v then sc:RemoveItem(v,true);v:Remove() end
        check(sc:GiveItem(spawn("umbrella"),slot,nil,false))
    end
    for slot=29,32 do check(sc:GiveItem(spawn("axe"),slot,nil,false)) end
    local held=inv:Unequip(EQUIPSLOTS.HANDS);held:Remove()
    local stranded=spawn("cane");inv:Equip(stranded)
    local replacement=spawn("spear");check(sc:GiveItem(replacement,1,nil,false))
    check(inv:Equip(replacement)==false,"unsafe full-bag swap should fail")
    check(inv:GetEquippedItem(EQUIPSLOTS.HANDS)==stranded and sc:GetItemInSlot(1)==replacement,"failed swap moved items")
    if pc then pc.isclientcontrollerattached=originalcontroller end
    local old=spawn("bigbag");inv:Equip(old)
    check(not sc:IsOpenedBy(player) and old.components.container:IsOpenedBy(player),"old/new bag swap lifecycle")
    print("EXPEDITION_PASS: native equip return, full-bag rejection, old/new bag lifecycle")
end)
for i=#created,1,-1 do if created[i]:IsValid() then created[i]:Remove() end end
if not ok then print("EXPEDITION_FAIL",err) else print("EXPEDITION_ENGINE_DONE") end
