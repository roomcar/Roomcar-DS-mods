-- Client-only preferences. Never store UI position in a world or item save.
local geometry = require("bigbag_ui_position")
local json = require("json")
local M = {}
local filename = "roomcar_bigbag_ui_v1"
local widgets = {}
local position, key, loading, loaded
local revision = 0

local function Save()
    revision = revision + 1
    TheSim:SetPersistentString(filename, json.encode({ position = position, key = key }), false)
end

-- UITransform:GetWorldScale is absent in current clients. Measure a local
-- translation through the real transform, including anchors and scale modes.
local function ParentScale(widget)
    local p, before = widget:GetPosition(), widget:GetWorldPosition()
    widget:SetPosition(p.x + 100, p.y + 100, p.z)
    local after = widget:GetWorldPosition()
    widget:SetPosition(p)
    return { x = (after.x - before.x) / 100, y = (after.y - before.y) / 100 }
end

function M.ScreenScale(widget)
    local parent = ParentScale(widget)
    local x, y = widget:GetLooseScale()
    return { x = parent.x * x, y = parent.y * y }
end

local function MoveScreen(widget, x, y)
    local current = widget:GetWorldPosition()
    local localpos = widget:GetPosition()
    local scale = ParentScale(widget)
    if scale.x <= 0 or scale.y <= 0 then return end
    widget:SetPosition(localpos.x + (x - current.x) / scale.x,
        localpos.y + (y - current.y) / scale.y, localpos.z)
end

function M.GetKey(config)
    return key ~= nil and key or config.UI_DRAG_KEY or 1
end

function M.Apply(widget)
    if not widget.inst:IsValid() or widget.parent == nil then return end
    local width, height = TheSim:GetScreenSize()
    if width <= 0 or height <= 0 then return end
    local parent = ParentScale(widget)
    if parent.x <= 0 or parent.y <= 0 then return end
    local base = widget._bigbag_base_scale
    local fit = geometry.Fit(width, height, parent.x * base, parent.y * base)
    widget:SetScale(base * fit)
    widget:SetPosition(widget._bigbag_default_pos)
    local p = widget:GetWorldPosition()
    local sx, sy = parent.x * base * fit, parent.y * base * fit
    local x, y = position ~= nil and position.x * width or p.x,
        position ~= nil and position.y * height or p.y
    x, y = geometry.Clamp(x, y, width, height, sx, sy)
    MoveScreen(widget, x, y)
    widget._bigbag_view = { width, height, parent.x, parent.y }
end

local function Load()
    if loading or loaded then return end
    loading = true
    local startrevision = revision
    TheSim:GetPersistentString(filename, function(success, data)
        loaded, loading = true, false
        -- An in-flight read must not undo a reset, key change or drag.
        if revision ~= startrevision then return end
        if success and data ~= nil and data ~= "" then
            local ok, value = pcall(json.decode, data)
            if ok and type(value) == "table" then
                position = geometry.DecodePosition(value.position)
                if geometry.IsFinite(value.key) and value.key >= 0 and value.key <= 9 and value.key % 1 == 0 then
                    key = value.key
                end
            end
        end
        for widget in pairs(widgets) do
            -- Avoid moving a panel out from underneath an active drag.
            if widget._bigbag_drag == nil then M.Apply(widget) end
            widget:UpdateBigBagDragLabel()
        end
    end)
end

function M.Attach(widget, config)
    widget._bigbag_base_scale = .6 * config.UI_SCALE
    widget._bigbag_default_pos = widget:GetPosition()
    widgets[widget] = true
    Load()
    M.Apply(widget)
end

function M.Finish(widget)
    if widget._bigbag_drag ~= nil then
        local changed = widget._bigbag_drag.changed
        widget._bigbag_drag = nil
        if changed then Save() end
    end
end

function M.Detach(widget)
    M.Finish(widget)
    widgets[widget] = nil
    widget._bigbag_keydown = nil
end

function M.CycleKey(config)
    key = (M.GetKey(config) + 1) % 10
    Save()
    for widget in pairs(widgets) do
        M.Finish(widget)
        widget:UpdateBigBagDragLabel()
    end
end

function M.Reset()
    -- Also works before a bag is equipped or before preferences finish loading.
    position = nil
    Save()
    for widget in pairs(widgets) do
        widget._bigbag_drag = nil
        widget.owner._bigbag_collapsed = false
        widget.owner._bigbag_autoexpanded = true
        widget:UpdateBigBagVisibility()
        M.Apply(widget)
    end
end

function M.KeyHeld(config)
    local number = M.GetKey(config)
    return number > 0 and TheInput:IsKeyDown(_G["KEY_F" .. number])
end

function M.Update(widget, config)
    local width, height = TheSim:GetScreenSize()
    if widget.parent == nil or width <= 0 or height <= 0 then return end
    local parent = ParentScale(widget)
    local view = widget._bigbag_view
    if view == nil or view[1] ~= width or view[2] ~= height or math.abs(view[3] - parent.x) > .0001 or math.abs(view[4] - parent.y) > .0001 then
        M.Finish(widget)
        M.Apply(widget)
    end
    local held = M.KeyHeld(config)
    local interactive = widget:IsVisible() and not TheInput:ControllerAttached()
        and TheFrontEnd:GetActiveScreen() == widget.owner.HUD
    if not held or not interactive then
        M.Finish(widget)
    elseif not widget._bigbag_keydown and widget.focus then
        -- Hold the function key with the pointer over the panel, then move.
        -- No item click is needed, so dragging cannot pick up a stack.
        local mouse, p = TheInput:GetScreenPosition(), widget:GetWorldPosition()
        widget._bigbag_drag = { x = mouse.x - p.x, y = mouse.y - p.y }
    end
    widget._bigbag_keydown = held
    local drag = widget._bigbag_drag
    if drag ~= nil then
        local mouse, scale = TheInput:GetScreenPosition(), M.ScreenScale(widget)
        local x, y = geometry.Clamp(mouse.x - drag.x, mouse.y - drag.y, width, height, scale.x, scale.y)
        local p = widget:GetWorldPosition()
        if math.abs(x - p.x) > .1 or math.abs(y - p.y) > .1 then
            MoveScreen(widget, x, y)
            position = { x = x / width, y = y / height }
            drag.changed = true
            revision = revision + 1
        end
    end
end

return M
