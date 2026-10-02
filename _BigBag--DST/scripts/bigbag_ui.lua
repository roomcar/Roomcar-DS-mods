local G = GLOBAL
local config = G.TUNING.ROOMCAR_BIGBAG
local Image = G.require("widgets/image")
local ImageButton = G.require("widgets/imagebutton")

local function OtherContainerOpen(owner)
    if not config.AUTOHIDE or owner.HUD == nil then return false end
    if owner.HUD.cookbookscreen ~= nil then return true end
    for inst, widget in pairs(owner.HUD.controls.containers) do
        if inst.prefab ~= "bigbag" and widget.isopen
            and inst.replica.container ~= nil and not inst.replica.container:IsSideWidget() then
            return true
        end
    end
    return false
end

-- Collapse visuals only: contents stay replicated and usable for crafting.
AddClassPostConstruct("widgets/containerwidget", function(self)
    local open = self.Open
    self.Open = function(self, container, ...)
        -- Avoid leaving a previous panel registered when reopening the same bag.
        open(self, container, ...)
        if container.prefab ~= "bigbag" then return end
        self:SetScale(.6 * config.UI_SCALE)
        self.bgimage:SetSize(560, 560)
        self.bigbag_toggle = self:AddChild(ImageButton("images/ui.xml", "button_small.tex", "button_small_over.tex", "button_small_disabled.tex"))
        self.bigbag_toggle:SetPosition(110, -310, 0)
        self.bigbag_toggle:SetTextSize(30)
        self.bigbag_toggle:SetOnClick(function()
            self.owner._bigbag_collapsed = not self.owner._bigbag_collapsed
            self:UpdateBigBagVisibility()
        end)
        self.bigbag_task = self.inst:DoPeriodicTask(.15, function() self:UpdateBigBagVisibility() end)
        self:UpdateBigBagVisibility()
    end
    self.UpdateBigBagVisibility = function(self)
        if self.container == nil or self.container.prefab ~= "bigbag" then return end
        local collapsed = self.owner._bigbag_collapsed or OtherContainerOpen(self.owner)
        if self._bigbag_hidden ~= collapsed then
            self._bigbag_hidden = collapsed
            for _, slot in ipairs(self.inv) do
                if collapsed then slot:Hide() else slot:Show() end
            end
            if collapsed then self.bgimage:Hide() else self.bgimage:Show() end
            local inv = self.owner.HUD and self.owner.HUD.controls.inv
            if collapsed and inv ~= nil and inv.current_list == self.inv then inv:SelectDefaultSlot() end
        end
        if self.button ~= nil then
            if collapsed then self.button:Hide() else self.button:Show() end
        end
        self.bigbag_toggle:SetText(config.LANG == 1 and (collapsed and "展开" or "收起") or (collapsed and "Expand" or "Hide"))
    end
    local close = self.Close
    self.Close = function(self, ...)
        if self.bigbag_task ~= nil then self.bigbag_task:Cancel() self.bigbag_task = nil end
        if self.bigbag_toggle ~= nil then self.bigbag_toggle:Kill() self.bigbag_toggle = nil end
        self._bigbag_hidden = nil
        return close(self, ...)
    end
end)

-- The vanilla integrated backpack assumes a single row. Reflow its existing
-- slots so controller selection, transfers and item tooltips keep vanilla code.
AddClassPostConstruct("widgets/inventorybar", function(self)
    local rebuild = self.Rebuild
    self.Rebuild = function(self, ...)
        rebuild(self, ...)
        self.bigbag_gridbg = nil
        self._bigbag_gridhidden = nil
        if self.backpack == nil or self.backpack.prefab ~= "bigbag" or #self.backpackinv == 0 then return end
        local columns, spacing = 16, 70
        for i, slot in ipairs(self.backpackinv) do
            local column, row = (i - 1) % columns, math.floor((i - 1) / columns)
            slot:SetPosition((column - 7.5) * spacing, 120 + (3 - row) * spacing, 0)
        end
        self.bigbag_gridbg = self.bottomrow:AddChild(Image("images/bigbagbg.xml", "bigbagbg.tex"))
        self.bigbag_gridbg:SetSize(columns * spacing + 25, 4 * spacing + 25)
        self.bigbag_gridbg:SetPosition(0, 225, 0)
        self.bigbag_gridbg:MoveToBack()
        if self.integrated_arrow ~= nil then self.integrated_arrow:Hide() end
    end
    local closest = self.GetClosestWidget
    self.GetClosestWidget = function(self, lists, ...)
        local visible, originals = {}, {}
        for _, list in pairs(lists) do
            local filtered = {}
            for key, slot in pairs(list) do
                if slot:IsVisible() then filtered[key] = slot end
            end
            visible[#visible + 1] = filtered
            originals[filtered] = list
        end
        local slot, list = closest(self, visible, ...)
        return slot, originals[list]
    end
    local update = self.OnUpdate
    self.OnUpdate = function(self, dt, ...)
        update(self, dt, ...)
        if self.bigbag_gridbg ~= nil then
            -- Keep controller slots visible while navigating inventory.
            local hidden = not self.open and OtherContainerOpen(self.owner)
            if hidden ~= self._bigbag_gridhidden then
                self._bigbag_gridhidden = hidden
                for _, slot in ipairs(self.backpackinv) do
                    if hidden then slot:Hide() else slot:Show() end
                end
                if hidden then self.bigbag_gridbg:Hide() else self.bigbag_gridbg:Show() end
            end
        end
    end
end)

-- Close any stale widget for the same entity before creating its replacement.
AddClassPostConstruct("screens/playerhud", function(self)
    local open = self.OpenContainer
    self.OpenContainer = function(self, container, ...)
        if container ~= nil and container.prefab == "bigbag" then
            local previous = self.controls.containers[container]
            if previous ~= nil then
                previous:Close()
                previous:Kill()
                self.controls.containers[container] = nil
            end
        end
        return open(self, container, ...)
    end
end)
