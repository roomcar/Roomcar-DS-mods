-- LOCAL console in an isolated world, with a worn Expedition Bag and side UI.
-- Changes its name to 洞穴远行包 and cycles its colour; no contents are changed.
local player=assert(ThePlayer)
local bag=assert(player.replica.inventory:GetOverflowContainer()).inst
assert(bag.prefab=="roomcar_expeditionbag")
local widget=assert(player.HUD.controls.containers[bag])
local data=require("expedition_data")
local function step(delay,fn)
    player:DoTaskInTime(delay,function()
        local ok,err=pcall(fn)
        if not ok then print("EXPEDITION_CLIENT_FAIL",err) end
    end)
end
assert(#widget.inv==32 and #widget.expedition_headers==6)
for slot,role in ipairs(data.slots) do
    assert(widget.inv[slot].label:GetString()==data.Label(role,TUNING.ROOMCAR_BIGBAG.LANG))
    if data.roles[role].icon and not widget.inv[slot].tile then assert(widget.inv[slot].bgimage2:IsVisible()) end
end
local before=bag.roomcar_bagcolor:value()
step(.2,function()
widget.expedition_color.onclick()
widget.bigbag_name.onclick()
widget._bigbag_namescreen:OverrideText("洞穴远行包")
widget._bigbag_namescreen.buttons[1].cb()
end)
step(1,function()
    assert(bag.roomcar_bagcolor:value()==before%#data.colors+1,"colour RPC")
    assert(bag:GetDisplayName()=="洞穴远行包" and widget._bigbag_title=="洞穴远行包","name RPC")
    widget.bigbag_toggle.onclick()
    assert(not widget.inv[1]:IsVisible() and not widget.expedition_headers[1]:IsVisible())
    widget.bigbag_toggle.onclick()
    assert(widget.inv[32]:IsVisible() and widget.expedition_headers[6]:IsVisible())
    print("EXPEDITION_CLIENT_PASS: 32 slots, six groups, icons, name/colour RPC, collapse")
    local inv=player.HUD.controls.inv
    local original=Profile.GetIntegratedBackpack
    Profile.GetIntegratedBackpack=function() return true end
    local ok,err=pcall(function()
        inv:Rebuild()
        assert(#inv.backpackinv==32 and #inv.expedition_gridheaders==6)
        local position=inv.backpackinv[1]:GetWorldPosition()
        local nextslot,list=inv:GetClosestWidget({inv.backpackinv},position,Vector3(0,-1,0))
        assert(nextslot==inv.backpackinv[4] and list==inv.backpackinv,"directional selection")
        print("EXPEDITION_CLIENT_PASS: integrated six-group layout and directional selection")
    end)
    Profile.GetIntegratedBackpack=original
    inv:Rebuild()
    if not ok then error(err) end
    print("EXPEDITION_CLIENT_DONE")
end)
