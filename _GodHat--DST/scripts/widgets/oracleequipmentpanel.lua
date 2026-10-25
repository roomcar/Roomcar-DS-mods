local Widget = require("widgets/widget")
local ImageButton = require("widgets/imagebutton")
local Colours = require("oraclecolours")
local ItemTile = require("widgets/itemtile")
local Strings = require("oracle_strings")
local function MakeVisual(widget)
    widget:SetClickable(false)
    for child in pairs(widget.children) do MakeVisual(child) end
end

local OracleEquipmentPanel = Class(Widget, function(self, owner, container, send, sendcolour)
    Widget._ctor(self, "OracleEquipmentPanel")
    self.owner, self.container, self.send = owner, container, send
    self.buttons, self.items, self.tiles = {}, {}, {}
    local backgrounds = {"equip_slot.tex", "equip_slot_body.tex", "equip_slot_head.tex"}
    self.labels = {Strings.Text("手持", "Hands"), Strings.Text("身体", "Body"), Strings.Text("头部", "Head")}
    for i = 1, 3 do
        local index = i
        local button = self:AddChild(ImageButton("images/hud.xml", backgrounds[i]))
        -- Continue the native 75-unit storage grid as its fifth row.
        button:SetPosition((i - 2) * 75, -187.5)
        button:SetScale(1)
        button:SetOnClick(function() self.send(self.container.GUID, index, false) end)
        local oldcontrol = button.OnControl
        button.OnControl = function(b, control, down)
            if control == CONTROL_SECONDARY and b.focus and b:IsEnabled() then
                if not down then self.send(self.container.GUID, index, true) end
                return true
            end
            return oldcontrol(b, control, down)
        end
        self.buttons[i] = button
    end
    for i, button in ipairs(self.buttons) do
        if i > 1 then button:SetFocusChangeDir(MOVE_LEFT, self.buttons[i - 1]) end
        if i < 3 then button:SetFocusChangeDir(MOVE_RIGHT, self.buttons[i + 1]) end
    end
    local colour=self:AddChild(ImageButton("images/button_icons.xml", "circle.tex"))
    colour:ForceImageSize(24,24)
    colour:SetPosition(100,166)
    colour:SetFocusScale(1.15)
    colour:SetOnClick(function() if sendcolour~=nil then sendcolour(container.GUID)end end)
    self.colouricon=colour.image
    self.colourbutton=colour
    self.elapsed = 0
    self:Refresh()
    self:StartUpdating()
end)

function OracleEquipmentPanel:Refresh()
    local r,g,b,a=Colours.RGBA(self.container)
    self.colourbutton:SetImageNormalColour(r,g,b,a)
    self.colourbutton:SetImageFocusColour(math.min(1,r+.18),math.min(1,g+.18),math.min(1,b+.18),a)
    local nets = self.container._oracle_equipment
    for i, button in ipairs(self.buttons) do
        local item = nets ~= nil and nets[i]:value() or nil
        if item ~= nil and not item:IsValid() then item = nil end
        if self.items[i] ~= item then
            if self.tiles[i] ~= nil then self.tiles[i]:Kill(); self.tiles[i] = nil end
            self.items[i] = item
            if item ~= nil and item.replica.inventoryitem ~= nil then
                local tile = button:AddChild(ItemTile(item))
                MakeVisual(tile)
                self.tiles[i] = tile
            end
        elseif item ~= nil and self.tiles[i] == nil and item.replica.inventoryitem ~= nil then
            local tile = button:AddChild(ItemTile(item))
            MakeVisual(tile)
            self.tiles[i] = tile
        end
        local name = item ~= nil and item:GetDisplayName() or Strings.Text("空", "Empty")
        button:SetHoverText(self.labels[i]..": "..name.."\n"..
            Strings.Text("拿起对应装备后点击穿戴；空手点击或右键取下。", "Hold matching gear and click to equip. Click empty-handed or right-click to remove."))
    end
end

function OracleEquipmentPanel:OnUpdate(dt)
    if not self.container:IsValid() then self:StopUpdating(); self:Hide(); return end
    self.elapsed = self.elapsed + dt
    if self.elapsed >= .15 then self.elapsed = 0; self:Refresh() end
end

return OracleEquipmentPanel
