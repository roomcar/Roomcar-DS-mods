-- Shared appearance marker. Keep colour in prefab data; native components
-- continue to serialize the container, name and inventory item separately.
local data = require("expedition_data")
local M = {}

function M.Set(inst,index)
    if type(index)~="number" or data.colors[index]==nil then index=inst._bigbag_defaultcolor end
    inst.roomcar_bagcolor:set(index)
    local rgb=data.colors[index].rgb
    inst.AnimState:SetMultColour(rgb[1],rgb[2],rgb[3],1)
    local owner=inst.components.inventoryitem.owner
    if owner~=nil and inst.components.equippable:IsEquipped() then
        for _,symbol in ipairs({"swap_body","backpack"})do
            owner.AnimState:SetSymbolMultColour(symbol,rgb[1],rgb[2],rgb[3],1)
        end
    end
end

function M.Network(inst)
    inst.roomcar_bagcolor=net_tinybyte(inst.GUID,"roomcar.bagcolor","roomcar_bagcolordirty")
end

function M.Server(inst,default)
    inst._bigbag_defaultcolor=default
    inst.SetBagColor=M.Set
    M.Set(inst,default)
    inst.OnSave=function(bag,saved) saved.color=bag.roomcar_bagcolor:value() end
    inst.OnLoad=function(bag,saved) M.Set(bag,saved and saved.color) end
end

function M.ClearOwner(owner)
    for _,symbol in ipairs({"swap_body","backpack"})do
        owner.AnimState:SetSymbolMultColour(symbol,1,1,1,1)
    end
end
return M
