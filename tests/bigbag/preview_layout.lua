-- Developer-only local console helper. Not loaded by modmain or saved to disk.
-- Deploy this file as scripts/bigbag_test_preview.lua in the development copy.
local original
function d_bigbag_preview(mode)
    assert(ThePlayer ~= nil and ThePlayer.HUD ~= nil, "Enter a world first; use the LOCAL console")
    assert(mode == "integrated" or mode == "mouse" or mode == "restore", "Use integrated, mouse or restore")
    if original == nil then original = Profile.GetIntegratedBackpack end
    if mode == "restore" then
        Profile.GetIntegratedBackpack = original
        original = nil
    else
        Profile.GetIntegratedBackpack = function() return mode == "integrated" end
    end
    local hud = ThePlayer.HUD
    hud:RefreshControllers()
    hud.controls.inv:Rebuild()
    hud.controls.inv:Refresh()
    print("BIGBAG_PREVIEW: " .. mode .. "; layout only, no virtual controller; no saved profile changes")
end
return d_bigbag_preview
