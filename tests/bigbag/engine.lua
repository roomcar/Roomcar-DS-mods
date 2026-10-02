-- Execute only in an isolated test world via the dedicated server console.
-- This spawns test entities and writes a save record through the real engine.
local util = require("bigbag_util")
local config = TUNING.ROOMCAR_BIGBAG
local bag = assert(SpawnPrefab("bigbag"))
bag.Transform:SetPosition(0, 0, 0)
local container = bag.components.container
assert(container:GetNumSlots() == 64)
local expected = {}
for slot = 1, 64 do
    local item = SpawnPrefab(slot % 2 == 0 and "cutgrass" or "twigs")
    item.components.stackable:SetStackSize(slot == 64 and 999 or slot)
    expected[item] = item.components.stackable:StackSize()
    assert(container:GiveItem(item, slot))
end
util.Sort(bag)
for slot = 1, 64 do
    local item = container:GetItemInSlot(slot)
    assert(expected[item] == item.components.stackable:StackSize(), "sort changed quantity/identity")
end
local record = bag:GetSaveRecord()
local restored = assert(SpawnSaveRecord(record))
for slot = 1, 64 do
    local a, b = container:GetItemInSlot(slot), restored.components.container:GetItemInSlot(slot)
    assert(a.prefab == b.prefab and a.components.stackable:StackSize() == b.components.stackable:StackSize(), "save roundtrip mismatch")
end
print("BIGBAG_ENGINE_PASS: 64 slots, sort identity, oversized stack, save roundtrip")
local huge = container:GetItemInSlot(64)
huge.components.stackable:SetStackSize(999)
config.STACK = true
util.RefreshContents(bag)
assert(huge.components.stackable:StackSize() == 999, "overstack shrank")
config.STACK = false
local foodbag = SpawnPrefab("bigbag")
local berries = SpawnPrefab("berries")
berries.components.perishable:SetPercent(.1)
foodbag.components.container:GiveItem(berries,1)
config.FRESH = true
util.RefreshContents(foodbag)
assert(berries.components.perishable:GetPercent() > .99)
local preserved = SpawnPrefab("bigbag")
assert(preserved.components.preserver:GetPerishRateMultiplier(berries) == 0)
config.FRESH = false
local player = SpawnPrefab("wilson")
player.Transform:SetPosition(0,0,0)
player.components.health:SetInvincible(true)
player.components.inventory:Open()
player.components.inventory:Equip(foodbag)
assert(foodbag.components.container:IsOpenedBy(player))
player.components.inventory:Equip(bag)
assert(not foodbag.components.container:IsOpenedBy(player), "old bag remained open")
assert(bag.components.container:IsOpenedBy(player), "new bag not open")
player.components.inventory:Unequip(bag.components.equippable.equipslot)
assert(not bag.components.container:IsOpenedBy(player), "unequip did not close")
print("BIGBAG_ENGINE_PASS: refresh, preservation, equip/swap/unequip")
-- Verify actual server material supply and the native building buffer path.
player.components.inventory:Equip(foodbag)
require("bigbag_supply").Supply(player.components.builder, AllRecipes.torch)
assert(player.components.inventory:Has("cutgrass", 2, true))
assert(player.components.inventory:Has("twigs", 2, true))
player.components.builder._bigbag_supplytime = nil
player.components.builder:BufferBuild("campfire")
assert(player.components.builder:IsBuildBuffered("campfire"))
print("BIGBAG_ENGINE_PASS: crafting supplies and structure buffering")
player:Remove()
bag:Remove()
restored:Remove()
foodbag:Remove()
preserved:Remove()
print("BIGBAG_ENGINE_DONE")
