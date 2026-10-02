-- Server-side item operations. Never shrink stacks or change item identities.
local M = {}

function M.FillStack(item)
    local stack = item.components.stackable
    if stack == nil then return end
    local limit = stack.originalmaxsize or stack.maxsize
    local count = stack:StackSize()
    if type(limit) == "number" and limit == limit and limit < math.huge
        and limit >= 1 and limit > count then
        stack:SetStackSize(math.floor(limit))
    end
end

function M.RefreshItem(item, repair)
    if item.components.perishable ~= nil then
        item.components.perishable:SetPercent(1)
    end
    if repair then
        for _, name in ipairs({ "finiteuses", "fueled", "armor" }) do
            local component = item.components[name]
            if component ~= nil then component:SetPercent(1) end
        end
    end
end

function M.RefreshContents(inst)
    local config = TUNING.ROOMCAR_BIGBAG
    for _, item in pairs(inst.components.container.slots) do
        if item:IsValid() then
            if config.STACK then M.FillStack(item) end
            if config.FRESH then M.RefreshItem(item, config.REPAIR) end
        end
    end
end

function M.Sort(inst)
    local container = inst.components.container
    if container == nil or container.readonlycontainer or container.infinitestacksize or inst._bigbag_sorting then return end
    local items = {}
    for slot = 1, container:GetNumSlots() do
        local item = container:GetItemInSlot(slot)
        if item ~= nil then
            if item.components.inventoryitem.islockedinslot then return end
            -- Do not remove stacks into the world or merge items with different
            -- freshness, skins, charges, or custom data. Reorder whole entities.
            items[#items + 1] = { item = item, slot = slot }
        end
    end
    table.sort(items, function(a, b)
        if a.item.prefab ~= b.item.prefab then return a.item.prefab < b.item.prefab end
        return a.slot < b.slot
    end)
    inst._bigbag_sorting = true
    for _, entry in ipairs(items) do
        container:RemoveItemBySlot(entry.slot)
    end
    for slot, entry in ipairs(items) do
        -- Empty explicit slots prevent GiveItem from merging the stacks.
        container:GiveItem(entry.item, slot)
    end
    inst._bigbag_sorting = nil
end

function M.GetEquippedBag(inventory)
    if inventory == nil then return end
    local equips = inventory.GetEquips ~= nil and inventory:GetEquips() or inventory.equipslots
    for _, item in pairs(equips or {}) do
        if item ~= nil and item.prefab == "bigbag" then return item end
    end
end

return M
