local data = require("expedition_data")
local assets = {
    Asset("ANIM","anim/backpack.zip"), Asset("ANIM","anim/swap_bigbag.zip"),
    Asset("ATLAS","images/inventoryimages/bigbag.xml"), Asset("IMAGE","images/inventoryimages/bigbag.tex"),
}
local function SetColor(inst, index)
    if type(index) ~= "number" or data.colors[index] == nil then index=2 end
    inst.roomcar_bagcolor:set(index)
    local c=data.colors[index].rgb
    inst.AnimState:SetMultColour(c[1],c[2],c[3],1)
    local owner=inst.components.inventoryitem.owner
    if owner ~= nil and inst.components.equippable:IsEquipped() then
        owner.AnimState:SetSymbolMultColour("swap_body",c[1],c[2],c[3],1)
    end
end
local function close(inst) inst.components.container:Close() end
local function equip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_body","swap_bigbag","swap_body")
    SetColor(inst,inst.roomcar_bagcolor:value())
    inst.components.container:Open(owner)
    owner:PushEvent("refreshcrafting")
end
local function unequip(inst, owner)
    owner.AnimState:SetSymbolMultColour("swap_body",1,1,1,1)
    owner.AnimState:ClearOverrideSymbol("swap_body")
    owner.AnimState:ClearOverrideSymbol("backpack")
    close(inst)
    owner:PushEvent("refreshcrafting")
end
local function fn()
    local inst=CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()
    MakeInventoryPhysics(inst)
    inst.AnimState:SetBank("backpack1")
    inst.AnimState:SetBuild("swap_bigbag")
    inst.AnimState:PlayAnimation("anim")
    inst.MiniMapEntity:SetIcon("bigbag.tex")
    inst:AddTag("backpack")
    inst:AddTag("roomcar_expeditionbag")
    inst.foleysound="dontstarve/movement/foley/krampuspack"
    inst.roomcar_bagcolor=net_tinybyte(inst.GUID,"roomcar.bagcolor","roomcar_bagcolordirty")
    MakeInventoryFloatable(inst,"small",.2,nil,nil,nil,{bank="backpack1",anim="anim"})
    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end
    inst:AddComponent("inspectable")
    inst:AddComponent("named")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname="images/inventoryimages/bigbag.xml"
    inst.components.inventoryitem:ChangeImageName("bigbag")
    inst.components.inventoryitem.cangoincontainer=false
    inst.components.inventoryitem:SetOnDroppedFn(close)
    inst.components.inventoryitem:SetOnPutInInventoryFn(function(bag)
        if not bag.components.equippable:IsEquipped() then close(bag) end
    end)
    inst:AddComponent("equippable")
    inst.components.equippable.equipslot=EQUIPSLOTS.BACK or EQUIPSLOTS.BODY
    inst.components.equippable.walkspeedmult=1
    inst.components.equippable:SetOnEquip(equip)
    inst.components.equippable:SetOnUnequip(unequip)
    inst.components.equippable:SetOnEquipToModel(close)
    inst:AddComponent("container")
    inst.components.container:WidgetSetup(data.PREFAB)
    require("expedition_container").Attach(inst)
    inst.SetBagColor=SetColor
    SetColor(inst,2)
    inst.OnSave=function(bag, saved) saved.color=bag.roomcar_bagcolor:value() end
    inst.OnLoad=function(bag, saved) SetColor(bag,saved and saved.color) end
    -- Normal spoilage, fuel and durability; no inherited Big Bag power options.
    return inst
end
return Prefab(data.PREFAB,fn,assets)
