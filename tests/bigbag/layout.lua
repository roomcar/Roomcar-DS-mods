-- Temporary integrated-layout check, without changing saved player settings.
local inv = ThePlayer.HUD.controls.inv
local original = Profile.GetIntegratedBackpack
Profile.GetIntegratedBackpack = function() return true end
local ok, err = pcall(function()
    inv:Rebuild()
    assert(#inv.backpackinv == 64 and inv.bigbag_gridbg ~= nil)
    local rows, columns = {}, {}
    for _, slot in ipairs(inv.backpackinv) do
        local p = slot:GetPosition()
        rows[p.y], columns[p.x] = true, true
    end
    local nr, nc = 0, 0
    for _ in pairs(rows) do nr = nr + 1 end
    for _ in pairs(columns) do nc = nc + 1 end
    assert(nr == 4 and nc == 16)
    local slot = inv.backpackinv[1]
    local x, y = slot.inst.UITransform:GetWorldPosition()
    local nextslot, list = inv:GetClosestWidget({inv.backpackinv}, Vector3(x,y,0), Vector3(0,-1,0))
    assert(nextslot == inv.backpackinv[17] and list == inv.backpackinv)
    print("BIGBAG_CLIENT_PASS: integrated 16x4 layout and directional selection")
end)
Profile.GetIntegratedBackpack = original
inv:Rebuild()
if not ok then print("BIGBAG_CLIENT_FAIL", err) end
