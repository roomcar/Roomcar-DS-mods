local data = require("expedition_data")
local M = {}
function M.Attach(inst)
    local container = inst.components.container
    local load = container.OnLoad
    container.OnLoad = function(self, ...)
        -- Changes in tags or compatibility rules must not eject saved contents.
        self._expedition_loading = true
        local ok, result = pcall(load, self, ...)
        self._expedition_loading = nil
        if not ok then error(result) end
        return result
    end
    local function onperished(item)
        local slot = container:GetItemSlot(item)
        local replacement = item.components.perishable and item.components.perishable.onperishreplacement
        if slot ~= nil and replacement ~= nil then
            container._expedition_replacements = container._expedition_replacements or {}
            container._expedition_replacements[slot] = replacement
            inst:DoTaskInTime(0, function() container._expedition_replacements[slot] = nil end)
        end
    end
    inst:ListenForEvent("itemget", function(_, event)
        if event.item.components.perishable ~= nil then inst:ListenForEvent("perished", onperished, event.item) end
    end)
    inst:ListenForEvent("itemlose", function(_, event)
        if event.prev_item ~= nil then inst:RemoveEventCallback("perished", onperished, event.prev_item) end
    end)
    local give = container.GiveItem
    container.GiveItem = function(self, item, slot, ...)
        -- Controller equipment swaps suggest the incoming item's old slot. A
        -- cane returning from a weapon swap must use a travel/general slot.
        if self._expedition_equipping and slot ~= nil and not self:CanTakeItemInSlot(item,slot) then slot=nil end
        return give(self,item,slot,...)
    end
end
function M.GuardEquipment(inventory)
    local equip = inventory.Equip
    inventory.Equip = function(self, item, old_to_active, ...)
        local bag = self:GetOverflowContainer()
        local component = item and item.components.equippable
        local old = component and self:GetEquippedItem(component.equipslot)
        if bag == nil or bag.inst.prefab ~= data.PREFAB or old == nil or old == item
            or old_to_active or component.equipslot == bag.inst.components.equippable.equipslot then
            return equip(self,item,old_to_active,...)
        end
        local room = false
        for slot=1,self.maxslots do
            if (self.itemslots[slot] == nil or self.itemslots[slot] == item) and self:CanTakeItemInSlot(old,slot) then room=true break end
        end
        if not room then
            for slot=1,data.NUMSLOTS do
                local current=bag:GetItemInSlot(slot)
                if (current == nil or current == item) and bag:CanTakeItemInSlot(old,slot) then room=true break end
            end
        end
        if not room then
            if self.inst.components.talker then
                self.inst.components.talker:Say(TUNING.ROOMCAR_BIGBAG.LANG == 1
                    and "没有合适的空格放回当前装备。" or "No suitable slot for my current equipment.")
            end
            return false
        end
        bag._expedition_equipping=true
        local ok,result=pcall(equip,self,item,old_to_active,...)
        bag._expedition_equipping=nil
        if not ok then error(result) end
        return result
    end
end
return M
