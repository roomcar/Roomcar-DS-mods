local G = GLOBAL
local count = 0
local function check(label, value)
    G.assert(value, label)
    count = count + 1
    print("[ORDINARY_TEST] PASS " .. label)
end

AddSimPostInit(function()
    if not G.TheWorld.ismastersim then return end
    G.TheWorld:DoTaskInTime(1, function()
        local ok, err = G.xpcall(function()
            local player = G.SpawnPrefab("wilson")
            player.userid = "KU_ORDINARY_ISOLATED_TEST"
            player.components.health:SetInvincible(true)
            player.entity:SetCanSleep(false)
            local inv = player.components.inventory
            local ids = {"roomcar_tattered_hat_base", "roomcar_tattered_hat_mesh", "roomcar_tattered_hat", "roomcar_plain_circlet"}
            for _, id in G.ipairs(ids) do
                local item = G.SpawnPrefab(id)
                check(id .. " spawns", item ~= nil and item:IsValid())
                check(id .. " ground build", item.AnimState:GetBuild() == id)
                check(id .. " ground idle", item.AnimState:IsCurrentAnimation("idle"))
                check(id .. " head slot", item.components.equippable.equipslot == G.EQUIPSLOTS.HEAD)
                check(id .. " icon atlas", item.components.inventoryitem.atlasname == "images/inventoryimages/ordinary_hats.xml")
                check(id .. " has no bonuses", item.components.armor == nil and item.components.fueled == nil
                    and item.components.insulator == nil and item.components.waterproofer == nil
                    and item.components.stackable == nil and item.components.equippable.dapperness == 0)
                local visibility = {}
                local overridden
                local fake = {isplayer = true, AnimState = {
                    ClearOverrideSymbol = function() end,
                    OverrideSymbol = function(_, symbol, build) overridden = {symbol, build} end,
                    Show = function(_, layer) visibility[layer] = true end,
                    Hide = function(_, layer) visibility[layer] = false end,
                }}
                item.components.equippable.onequipfn(item, fake)
                local open = id == "roomcar_plain_circlet"
                check(id .. " correct OPEN tag", item:HasTag("open_top_hat") == open)
                check(id .. " correct head visibility", visibility.HEAD == open
                    and visibility.HEAD_HAT == not open and visibility.HEAD_HAT_NOHELM == not open
                    and visibility.HEAD_HAT_HELM == false)
                check(id .. " correct hair visibility", visibility.HAIR == open and visibility.HAIR_NOHAT == open
                    and visibility.HAIR_HAT == not open and visibility.HAT == true)
                check(id .. " correct symbol override", overridden[1] == "swap_hat" and overridden[2] == id)
                item.components.equippable.onunequipfn(item, fake)
                check(id .. " restores normal visibility", visibility.HEAD == true and visibility.HAIR == true
                    and visibility.HAIR_NOHAT == true and visibility.HAT == false and visibility.HAIR_HAT == false
                    and visibility.HEAD_HAT == false and visibility.HEAD_HAT_NOHELM == false)
                inv:GiveItem(item)
                inv:Equip(item)
                check(id .. " native equip", inv:GetEquippedItem(G.EQUIPSLOTS.HEAD) == item)
                local saved = item:GetSaveRecord()
                inv:Unequip(G.EQUIPSLOTS.HEAD)
                check(id .. " native unequip", inv:GetEquippedItem(G.EQUIPSLOTS.HEAD) == nil)
                item:Remove()
                local loaded = G.SpawnSaveRecord(saved)
                check(id .. " save roundtrip", loaded ~= nil and loaded.prefab == id)
                inv:GiveItem(loaded)
                inv:Equip(loaded)
                check(id .. " loaded item equips", inv:GetEquippedItem(G.EQUIPSLOTS.HEAD) == loaded)
                inv:DropItem(loaded, true, true)
                check(id .. " dropped item", inv:GetEquippedItem(G.EQUIPSLOTS.HEAD) == nil and loaded:IsValid())
                loaded:Remove()
                local recipe = G.AllRecipes[id]
                check(id .. " recipe registered", recipe ~= nil and #recipe.ingredients > 0)
            end
            local full = G.AllRecipes.roomcar_tattered_hat
            check("complete hat consumes base and mesh", #full.ingredients == 2
                and full.ingredients[1].type == ids[1] and full.ingredients[1].amount == 1
                and full.ingredients[2].type == ids[2] and full.ingredients[2].amount == 1)
            check("ordinary localisation", G.STRINGS.NAMES.ROOMCAR_TATTERED_HAT ~= nil)
            local circlet = G.AllRecipes.roomcar_plain_circlet
            check("circlet rope recipe", #circlet.ingredients == 1
                and circlet.ingredients[1].type == "rope" and circlet.ingredients[1].amount == 1)
            player:Remove()
            print("[ORDINARY_TEST] COMPLETE " .. count)
        end, G.debug.traceback)
        if not ok then print("[ORDINARY_TEST] FAIL " .. G.tostring(err)) end
        G.TheSim:Quit()
    end)
end)
