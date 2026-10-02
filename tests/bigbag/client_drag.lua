-- LOCAL client console, isolated test world, equipped bigbag in side-panel mode.
-- Exercises real Widget transforms with synthetic key/pointer input. Resets UI
-- position before and after; does not change any server or inventory contents.
local player = assert(ThePlayer)
local bag = assert(player.replica.inventory:GetOverflowContainer()).inst
local widget = assert(player.HUD.controls.containers[bag], "side panel must be open")
local drag, geometry = require("bigbag_ui_drag"), require("bigbag_ui_position")
local config = TUNING.ROOMCAR_BIGBAG
local oldkey, oldmouse = TheInput.IsKeyDown, TheInput.GetScreenPosition
local oldscreen = TheFrontEnd.GetActiveScreen
local oldfocus, oldcookbook = widget.focus, player.HUD.cookbookscreen
local oldauto = config.AUTOHIDE
local sx, sy, sz = widget.parent:GetLooseScale()
local held, pointer = false, Vector3(0,0,0)
local dragkey = _G["KEY_F" .. drag.GetKey(config)]
assert(dragkey ~= nil, "enable a drag key before testing")
local function bounded()
    local width,height = TheSim:GetScreenSize()
    local p,s = widget:GetWorldPosition(),drag.ScreenScale(widget)
    assert(p.x + geometry.LEFT*s.x >= 11.9 and p.x + geometry.RIGHT*s.x <= width-11.9, "horizontal bounds")
    assert(p.y + geometry.BOTTOM*s.y >= 11.9 and p.y + geometry.TOP*s.y <= height-11.9, "vertical bounds")
end
local ok,err = pcall(function()
    TheInput.IsKeyDown = function(_, key) return held and key == dragkey end
    TheInput.GetScreenPosition = function() return pointer end
    TheFrontEnd.GetActiveScreen = function() return player.HUD end
    d_resetbigbagui()
    bounded()
    widget.focus = true
    pointer = widget:GetWorldPosition()
    held = true
    drag.Update(widget, config)
    assert(widget._bigbag_drag ~= nil, "drag did not start")
    assert(widget:OnControl(CONTROL_ACCEPT,true), "drag click was not consumed")
    assert(widget:OnControl(CONTROL_ACCEPT,false), "drag release was not consumed")
    for _, p in ipairs({{-100000,-100000},{100000,100000},{-100000,100000},{100000,-100000}}) do
        pointer = Vector3(p[1],p[2],0)
        drag.Update(widget,config)
        bounded()
    end
    held = false
    drag.Update(widget,config)
    assert(widget._bigbag_drag == nil)
    local before = widget:GetWorldPosition()
    drag.Apply(widget)
    assert((widget:GetWorldPosition()-before):LengthSq() < .1, "saved position changed")
    widget.parent:SetScale(sx*8,sy*8,sz)
    drag.Update(widget,config)
    bounded()
    widget.parent:SetScale(sx,sy,sz)
    drag.Update(widget,config)
    bounded()
    config.AUTOHIDE = true
    player.HUD.cookbookscreen = {}
    player._bigbag_collapsed = false
    player._bigbag_autoexpanded = nil
    widget:UpdateBigBagVisibility()
    assert(widget._bigbag_hidden)
    widget.bigbag_toggle.onclick()
    assert(not widget._bigbag_hidden, "manual Expand must override automatic hiding")
    widget:UpdateBigBagVisibility()
    assert(not widget._bigbag_hidden, "automatic update undid manual Expand")
    print("BIGBAG_DRAG_PASS: real transforms, four edges, scaled HUD, click interception, manual expand")
end)
TheInput.IsKeyDown,TheInput.GetScreenPosition = oldkey,oldmouse
TheFrontEnd.GetActiveScreen = oldscreen
widget.parent:SetScale(sx,sy,sz)
widget.focus,player.HUD.cookbookscreen = oldfocus,oldcookbook
config.AUTOHIDE = oldauto
d_resetbigbagui()
if not ok then print("BIGBAG_DRAG_FAIL",err) end
