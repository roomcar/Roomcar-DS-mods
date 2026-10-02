local InputDialog = require("screens/redux/inputdialog")
local TextButton = require("widgets/textbutton")
local naming = require("bigbag_naming")
local M = {}

function M.Close(widget)
    local screen = widget._bigbag_namescreen
    widget._bigbag_namescreen = nil
    if screen ~= nil then TheFrontEnd:PopScreen(screen) end
end

function M.Open(widget, config)
    if widget._bigbag_namescreen ~= nil then return end
    local bag = widget.container
    local screen
    local function cancel() M.Close(widget) end
    local function save()
        local name = naming.Normalize(screen:GetActualString())
        if name == nil then return end
        if bag:IsValid() then
            SendModRPCToServer(GetModRPC("roomcar_bigbag", "rename"), bag, name)
        end
        cancel()
    end
    screen = InputDialog(config.LANG == 1 and "背包命名（最多20字，留空复原）"
        or "Name bag (20 characters; blank resets)", {
        {text = config.LANG == 1 and "保存" or "Save", cb = save},
        {text = config.LANG == 1 and "取消" or "Cancel", cb = cancel},
    }, true)
    screen.bg.title:SetSize(26)
    widget._bigbag_namescreen = screen
    screen.edit_text:SetTextLengthLimit(naming.MAX_LENGTH)
    screen.edit_text:EnableWordWrap(false)
    screen.edit_text:EnableScrollEditWindow(true)
    screen.edit_text.OnTextEntered = save
    screen:OverrideText(bag:GetDisplayName())
    TheFrontEnd:PushScreen(screen)
    screen.edit_text:SetFocus()
    if not TheInput:ControllerAttached() then screen.edit_text:SetEditing(true) end
end

function M.Update(widget, config)
    local name = widget.container:GetDisplayName()
    if name ~= widget._bigbag_title then
        widget._bigbag_title = name
        local button = widget.bigbag_name
        -- Keep the rename affordance visible even for a long custom name.
        button.text:SetTruncatedString(name, 360, nil, true)
        button:SetText(button.text:GetString() .. (config.LANG == 1 and " [命名]" or " [Rename]"))
    end
end

function M.Attach(widget, config)
    widget._bigbag_title = nil
    widget.bigbag_name = widget:AddChild(TextButton())
    widget.bigbag_name:SetPosition(0, 315)
    widget.bigbag_name:SetTextSize(30)
    widget.bigbag_name:SetOnClick(function() M.Open(widget, config) end)
    M.Update(widget, config)
end

return M
