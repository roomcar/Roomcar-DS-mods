-- Run in the LOCAL client console after joining an isolated test server.
-- Requires GIVE=true, an equipped bigbag with cutgrass in slot 1, twigs in 64.
assert(ThePlayer ~= nil and not TheWorld.ismastersim, "requires a remote client")
local player = ThePlayer
local function later(delay, fn)
    player:DoTaskInTime(delay, function()
        local ok, err = pcall(fn)
        if not ok then print("BIGBAG_CLIENT_FAIL", err) end
    end)
end
local container = player.replica.inventory:GetOverflowContainer()
local bag = container.inst
assert(bag.prefab == "bigbag")
local widget = player.HUD.controls.containers[bag]
assert(widget ~= nil and #widget.inv == 64)
assert(player.replica.inventory:Has("twigs", 1, true))
widget.bigbag_toggle.onclick()
assert(not widget.inv[1]:IsVisible())
assert(player.replica.inventory:Has("twigs", 1, true))
widget.bigbag_toggle.onclick()
assert(widget.inv[1]:IsVisible())
print("BIGBAG_CLIENT_PASS: 64 slots, collapse, crafting contents")
later(.5, function()
    SendModRPCToServer(GetModRPC("roomcar_bigbag", "sort"), bag)
    later(1, function()
        assert(container:GetItemInSlot(2) ~= nil and container:GetItemInSlot(2).prefab == "twigs", "sort did not reach server")
        assert(container:GetItemInSlot(64) == nil)
        assert(player.replica.builder:HasIngredients(AllRecipes.torch))
        SendRPCToServer(RPC.MakeRecipeFromMenu, AllRecipes.torch.rpc_id)
        print("BIGBAG_CLIENT_PASS: sort RPC and crafting request sent")
        later(3, function()
            local held = player.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            assert((held ~= nil and held.prefab == "torch") or player.replica.inventory:Has("torch", 1, true))
            print("BIGBAG_CLIENT_PASS: remote crafting supplies produced torch")
        end)
    end)
end)
