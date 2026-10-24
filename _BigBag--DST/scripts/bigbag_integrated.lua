-- Client layout only. Never reorder the container slots or replace InvSlots.
local M = { SPACING = 70, ROW_GAP = 70, SCALE = .8, MARGIN = 12 }
local bigrows = { {1,20}, {21,40}, {41,64} }
local expeditionrows = { {1,12}, {13,32} }

local function Rows(self)
    return self.backpack.prefab == "roomcar_expeditionbag" and expeditionrows or bigrows
end

local function Spacing(self)
    return self.backpack.prefab=="roomcar_expeditionbag" and 72 or M.SPACING
end
local function RowWidth(row,spacing)
    return (row[2]-row[1])*spacing+76
end

local function Measure(self)
    local node = self.bottomrow
    local p, before = node:GetPosition(), node:GetWorldPosition()
    node:SetPosition(p.x + 100, p.y + 100, p.z)
    local after = node:GetWorldPosition()
    node:SetPosition(p)
    local width, height = TheSim:GetScreenSize()
    return {width, height, (after.x-before.x)/100, (after.y-before.y)/100,
        before.x, before.y, self.toprow:GetPosition().y-p.y}
end

function M.Refresh(self, force)
    local rows = Rows(self)
    local spacing=Spacing(self)
    local view = Measure(self)
    if view[1] <= 0 or view[2] <= 0 or view[3] <= 0 or view[4] <= 0 then return end
    local old = self._bigbag_integrated_view
    local changed = force or old == nil
    if not changed then
        for i,v in ipairs(view) do
            if math.abs(v-old[i]) > .001 then changed = true break end
        end
    end
    if not changed then return end
    self._bigbag_integrated_view = view
    -- Deliberately smaller bag slots, with additional fitting for small screens
    -- or controller/HUD zoom. Never rescale the player/equipment slots.
    local room = math.max(1, 2*math.min(view[5]-M.MARGIN, view[1]-M.MARGIN-view[5]))
    local upperroom = (view[2]-M.MARGIN-view[6])/view[4]-view[7]-34
    local lastrow = #rows
    local maxwidth = math.max(RowWidth(rows[1],spacing), RowWidth(rows[lastrow],spacing))
    local fit = math.max(.01, math.min(M.SCALE, room/(maxwidth*view[3]),
        upperroom/(86+(lastrow-2)*M.ROW_GAP)))
    self._bigbag_integrated_fit = fit
    local near = view[7]+34+42*fit
    for i,slot in ipairs(self.backpackinv) do
        local row = lastrow
        for r,bounds in ipairs(rows) do
            if i >= bounds[1] and i <= bounds[2] then row = r break end
        end
        local first,last = rows[row][1],rows[row][2]
        slot._bigbag_integrated_index, slot._bigbag_integrated_row = i,row
        slot._bigbag_original_base = slot._bigbag_original_base or slot.base_scale
        slot._bigbag_original_highlight = slot._bigbag_original_highlight or slot.highlight_scale
        slot.base_scale = slot._bigbag_original_base*fit
        slot.highlight_scale = slot._bigbag_original_highlight*fit
        slot:SetScale(slot.base_scale)
        slot:SetPosition((i-first-(last-first)/2)*spacing*fit,
            row == lastrow and 0 or near+(lastrow-1-row)*M.ROW_GAP*fit, 0)
    end
    local upperheight = 76+(lastrow-2)*M.ROW_GAP
    self.bigbag_gridbg:SetBorderScale(fit)
    self.bigbag_bottom_bg:SetBorderScale(fit)
    self.bigbag_gridbg:SetSize(RowWidth(rows[1],spacing)*fit,upperheight*fit)
    self.bigbag_gridbg:SetPosition(0,near+(lastrow-2)*M.ROW_GAP*fit/2,0)
    self.bigbag_bottom_bg:SetSize(RowWidth(rows[lastrow],spacing)*fit,76*fit)
    self.bigbag_bottom_bg:SetPosition(0,0,0)
    return true
end

function M.Horizontal(self, lists, dir)
    local active = self.active_slot
    if dir.y ~= 0 or dir.x == 0 or self.current_list ~= self.backpackinv
        or active == nil or active._bigbag_integrated_row == nil then return false end
    local included = false
    for _,list in pairs(lists) do if list == self.backpackinv then included = true break end end
    if not included then return false end
    -- Vanilla's half-plane search can jump diagonally to another row at an
    -- edge. Left/right stay in the visible row; up/down use native geometry.
    local limits = Rows(self)[active._bigbag_integrated_row]
    local index = active._bigbag_integrated_index + (dir.x > 0 and 1 or -1)
    local slot = index >= limits[1] and index <= limits[2] and self.backpackinv[index] or nil
    if slot ~= nil and slot:IsVisible() then return true,slot,self.backpackinv end
    return true
end

return M
