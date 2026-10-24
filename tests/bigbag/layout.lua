-- Optional LOCAL console check using real live client widgets.
-- require("bigbag_test_layout"); d_bigbag_test_layout()
function d_bigbag_test_layout()
    local player = assert(ThePlayer, "Enter a world first")
    local bag = assert(player.replica.inventory:GetOverflowContainer()).inst
    assert(bag.prefab == "roomcar_bigbag_new", "Equip Big Bag - New UI")
    local inv = player.HUD.controls.inv
    local original = Profile.GetIntegratedBackpack
    local items = {}
    for i=1,64 do items[i]=bag.replica.container:GetItemInSlot(i) end
    Profile.GetIntegratedBackpack = function() return true end
    local ok, err = pcall(function()
        inv:Rebuild()
        assert(#inv.backpackinv == 64 and inv.bigbag_bottom_bg ~= nil)
        for i=41,64 do assert(inv.backpackinv[i]:GetPosition().y==0) end
        local top,near=inv.backpackinv[1]:GetPosition().y,inv.backpackinv[21]:GetPosition().y
        assert(top>near and near>inv.toprow:GetPosition().y-inv.bottomrow:GetPosition().y)
        local reached,queue={},{{inv.inv[1],inv.inv}}
        reached[inv.inv[1]]=true
        local at=1
        while queue[at]~=nil do
            local state=queue[at];at=at+1
            for _,dir in ipairs({Vector3(1,0,0),Vector3(-1,0,0),Vector3(0,1,0),Vector3(0,-1,0)})do
                inv.active_slot,inv.current_list=state[1],state[2]
                if inv:CursorNav(dir,dir.x~=0) and not reached[inv.active_slot]then
                    reached[inv.active_slot]=true
                    queue[#queue+1]={inv.active_slot,inv.current_list}
                end
            end
        end
        for i=1,64 do
            assert(reached[inv.backpackinv[i]], "Unreachable slot "..i)
            assert(bag.replica.container:GetItemInSlot(i)==items[i], "Item identity changed")
        end
    end)
    Profile.GetIntegratedBackpack=original
    inv:Rebuild()
    if ok then
        print("BIGBAG_LAYOUT_PASS: 40 above + 24 below; native navigation reaches all 64; contents unchanged")
    else
        print("BIGBAG_LAYOUT_FAIL: "..tostring(err))
    end
end
return d_bigbag_test_layout
