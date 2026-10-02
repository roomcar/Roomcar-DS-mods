-- LOCAL console, isolated test world with an equipped bigbag side panel.
-- Exercises the actual dialog callbacks and server RPC, leaving the bag named
-- "矿石与工具" for a subsequent save/restart check. Does not change contents.
local player = assert(ThePlayer)
local bag = assert(player.replica.inventory:GetOverflowContainer()).inst
local widget = assert(player.HUD.controls.containers[bag])
local function step(delay, fn)
    player:DoTaskInTime(delay, function()
        local ok, err = pcall(fn)
        if not ok then print("BIGBAG_NAMING_FAIL", err) end
    end)
end
local function edit(text, save)
    widget.bigbag_name.onclick()
    local screen = assert(widget._bigbag_namescreen)
    screen:OverrideText(text)
    screen.buttons[save and 1 or 2].cb()
    assert(widget._bigbag_namescreen == nil)
end
step(.2, function()
    local before = bag:GetDisplayName()
    edit("取消不应改名", false)
    assert(bag:GetDisplayName() == before)
    edit("", true)
    step(1, function()
        assert(bag:GetDisplayName() == STRINGS.NAMES.BIGBAG, "blank name did not reset")
        edit("矿石与工具", true)
        step(1, function()
            assert(bag:GetDisplayName() == "矿石与工具", "Chinese name not replicated")
            assert(widget._bigbag_title == "矿石与工具", "panel title not refreshed")
            widget.bigbag_name.onclick()
            assert(widget._bigbag_namescreen:GetActualString() == "矿石与工具", "dialog did not restore current name")
            widget._bigbag_namescreen.buttons[2].cb()
            print("BIGBAG_NAMING_PASS: cancel, clear, Chinese RPC replication, title, dialog reopening")
        end)
    end)
end)
