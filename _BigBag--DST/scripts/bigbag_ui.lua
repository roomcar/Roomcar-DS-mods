local G = GLOBAL
local config = G.TUNING.ROOMCAR_BIGBAG
local ImageButton = G.require("widgets/imagebutton")
local Panel = G.require("widgets/bigbagpanel")
local drag = G.require("bigbag_ui_drag")
local classic_drag = G.require("bigbag_classic_drag")
local function IsClassic(inst) return inst ~= nil and inst.prefab == "bigbag" end
local function DragFor(inst) return IsClassic(inst) and classic_drag or drag end
local naming = G.require("bigbag_naming_ui")
local bags = G.require("expedition_data")
local expedition_ui = G.require("expedition_ui")
local integrated = G.require("bigbag_integrated")

-- Local console recovery, including when no backpack is currently open.
G.d_resetbigbagui = function() drag.Reset() classic_drag.Reset() end

local function OtherContainerOpen(owner, modern)
    if not config.AUTOHIDE or owner.HUD == nil then return false end
    -- Cooking needs repeated transfers from the bag. The stewer tag is present
    -- on pristine cookpots (including portable and modded stewers), so this
    -- works on remote clients without reading server-only components.
    -- Give cooking priority even if a recipe menu/another container is open.
    for inst, widget in pairs(owner.HUD.controls.containers) do
        if widget.isopen and inst.HasTag ~= nil and inst:HasTag("stewer") then
            return false
        end
    end
    if owner.HUD.cookbookscreen ~= nil then return true end
    -- The recipe menu is different from the cookbook popup. Keep Expedition's
    -- existing detection unchanged; only the new Big Bag opts into this fix.
    if modern and owner.HUD.IsCraftingOpen ~= nil and owner.HUD:IsCraftingOpen() then return true end
    for inst, widget in pairs(owner.HUD.controls.containers) do
        if not bags.IsBag(inst) and widget.isopen
            and inst.replica.container ~= nil and not inst.replica.container:IsSideWidget() then
            return true
        end
    end
    return false
end

-- Collapse visuals only: contents stay replicated and usable for crafting.
AddClassPostConstruct("widgets/containerwidget", function(self)
    self.UpdateBigBagDragLabel = function(self)
        if self.bigbag_dragkey == nil then return end
        local key = drag.GetKey(config)
        self.bigbag_dragkey:SetText(config.LANG == 1
            and (key == 0 and "拖动：关" or "拖动 F" .. key)
            or (key == 0 and "Drag: Off" or "Drag F" .. key))
    end
    local open = self.Open
    self.Open = function(self, container, ...)
        -- Avoid leaving a previous panel registered when reopening the same bag.
        open(self, container, ...)
        if not bags.IsBag(container) then return end
        self._bigbag_nativebg = self.bgimage
        self._bigbag_nativebg:Hide()
        self.bgimage = self:AddChild(Panel())
        self.bgimage:MoveToBack()
        if IsClassic(container) then
            -- Original texture and full-size grid, with tighter visible margins.
            self:SetScale(.6)
            self.bgimage:SetSize(544, 544)
            self.bgimage:SetPosition(0, 0, 0)
            classic_drag.Attach(self, config)
            self:StartUpdating()
            return
        end
        self._bigbag_visibilitystate = container.prefab == "roomcar_bigbag_new" and {} or self.owner
        -- Opening a bag always reveals its contents, even if a previous bag was
        -- folded or the crafting menu used to make this bag is still open.
        self._bigbag_visibilitystate._bigbag_collapsed = false
        self._bigbag_visibilitystate._bigbag_autoexpanded = OtherContainerOpen(self.owner, container.prefab == "roomcar_bigbag_new") or nil
        self:SetScale(.6 * config.UI_SCALE)
        self.bigbag_toggle = self:AddChild(ImageButton("images/ui.xml", "button_small.tex", "button_small_over.tex", "button_small_disabled.tex"))
        self.bigbag_toggle:SetPosition(110, -310, 0)
        self.bigbag_toggle:SetTextSize(30)
        self.bigbag_toggle:SetOnClick(function()
            -- A deliberate Expand overrides auto-hide for this interaction.
            self._bigbag_visibilitystate._bigbag_collapsed = not self._bigbag_hidden
            self._bigbag_visibilitystate._bigbag_autoexpanded = self._bigbag_hidden and OtherContainerOpen(self.owner, self.container ~= nil and self.container.prefab == "roomcar_bigbag_new") or nil
            self:UpdateBigBagVisibility()
        end)
        self.bigbag_dragkey = self:AddChild(ImageButton("images/ui.xml", "button_small.tex", "button_small_over.tex", "button_small_disabled.tex"))
        self.bigbag_dragkey:SetPosition(-100, -365, 0)
        self.bigbag_dragkey:SetTextSize(27)
        self.bigbag_dragkey:SetHoverText(config.LANG == 1
            and "鼠标指向背包\n按住功能键移动，无需点击\n点击此按钮换键，仅影响自己"
            or "Point at the bag; hold the key to move.\nNo item click needed.\nClick here to change your drag key.", { font_size = 20, offset_y = 75 })
        self.bigbag_dragkey:SetOnClick(function() drag.CycleKey(config) end)
        self.bigbag_reset = self:AddChild(ImageButton("images/ui.xml", "button_small.tex", "button_small_over.tex", "button_small_disabled.tex"))
        self.bigbag_reset:SetPosition(110, -365, 0)
        self.bigbag_reset:SetTextSize(30)
        self.bigbag_reset:SetText(config.LANG == 1 and "复位" or "Reset")
        self.bigbag_reset:SetHoverText(config.LANG == 1 and "恢复默认位置并展开背包。" or "Restore the default position and expand the bag.")
        self.bigbag_reset:SetOnClick(drag.Reset)
        naming.Attach(self, config)
        if container.prefab == bags.PREFAB then
            expedition_ui.Attach(self, config)
        else
            -- Full-size grid; nine-slice panel also contains title and controls.
            self._bigbag_requested_scale = .6
            self._bigbag_geometry = G.require("bigbag_new_position")
            self.bgimage:SetSize(544, 632)
            self.bgimage:SetPosition(0, -6, 0)
            self._bigbag_title_width = 480
            self.bigbag_name:SetPosition(0, 286, 0)
            self.bigbag_name:SetTextSize(33)
            self._bigbag_title = nil
            naming.Update(self, config)
            expedition_ui.AttachColor(self, config, 98)
            local buttons = { self.button, self.bigbag_toggle, self.expedition_color, self.bigbag_dragkey, self.bigbag_reset }
            for i = 1, 5 do
                local button = buttons[i]
                if button ~= nil then
                    button:SetPosition((i - 3) * 104, -292, 0)
                    button:ForceImageSize(98, 42)
                    button.scale_on_focus = false
                    button:SetTextSize(26)
                    button.text:SetPosition(0, -2, 0)
                end
            end
        end
        drag.Attach(self, config)
        self:UpdateBigBagDragLabel()
        self:StartUpdating()
        self.bigbag_task = self.inst:DoPeriodicTask(.15, function() self:UpdateBigBagVisibility() end)
        self:UpdateBigBagVisibility()
    end
    self.UpdateBigBagVisibility = function(self)
        if self.container == nil or not bags.IsBag(self.container) or IsClassic(self.container) then return end
        naming.Update(self, config)
        local otheropen = OtherContainerOpen(self.owner, self.container ~= nil and self.container.prefab == "roomcar_bigbag_new")
        if not otheropen then self._bigbag_visibilitystate._bigbag_autoexpanded = nil end
        local collapsed = self._bigbag_visibilitystate._bigbag_collapsed or (otheropen and not self._bigbag_visibilitystate._bigbag_autoexpanded)
        expedition_ui.Update(self, config, collapsed)
        if self._bigbag_hidden ~= collapsed then
            self._bigbag_hidden = collapsed
            for _, slot in ipairs(self.inv) do
                if collapsed then slot:Hide() else slot:Show() end
            end
            if collapsed then self.bgimage:Hide() else self.bgimage:Show() end
            local inv = self.owner.HUD and self.owner.HUD.controls.inv
            if collapsed and inv ~= nil and inv.current_list == self.inv then inv:SelectDefaultSlot() end
        end
        -- Folding leaves exactly one affordance: Expand. Apply every refresh
        -- so rename/colour updates cannot leave an orphan control visible.
        for _, key in ipairs({"button", "bigbag_name", "bigbag_dragkey", "bigbag_reset",
            "expedition_color", "expedition_marker"}) do
            local control = self[key]
            if control ~= nil then
                if collapsed then control:Hide() else control:Show() end
            end
        end
        self.bigbag_toggle:Show()
        self.bigbag_toggle:SetText(config.LANG == 1 and (collapsed and "展开" or "收起") or (collapsed and "Expand" or "Hide"))
    end
    local update = self.OnUpdate
    self.OnUpdate = function(self, dt, ...)
        if update ~= nil then update(self, dt, ...) end
        if self.isopen and self.container ~= nil and bags.IsBag(self.container) then
            DragFor(self.container).Update(self, config)
        end
    end
    local control = self.OnControl
    self.OnControl = function(self, action, down, ...)
        if self.isopen and self.container ~= nil and bags.IsBag(self.container)
            and (action == G.CONTROL_PRIMARY or action == G.CONTROL_ACCEPT)
            and (self._bigbag_dragclick or (self.focus and DragFor(self.container).KeyHeld(config))) then
            -- Also accept F-key + left-drag without clicking inventory slots.
            self._bigbag_dragclick = down or nil
            return true
        end
        return control(self, action, down, ...)
    end
    local close = self.Close
    self.Close = function(self, ...)
        classic_drag.Detach(self)
        if IsClassic(self.container) and update == nil then self:StopUpdating() end
        self._bigbag_visibilitystate = nil
        naming.Close(self)
        expedition_ui.Close(self)
        if self.bigbag_name ~= nil then self.bigbag_name:Kill() self.bigbag_name = nil end
        if self.bigbag_dragkey ~= nil then
            drag.Detach(self)
            if update == nil then self:StopUpdating() end
            self.bigbag_dragkey:Kill()
            self.bigbag_dragkey = nil
            self.bigbag_reset:Kill()
            self.bigbag_reset = nil
        end
        self._bigbag_dragclick = nil
        if self.bigbag_task ~= nil then self.bigbag_task:Cancel() self.bigbag_task = nil end
        if self.bigbag_toggle ~= nil then self.bigbag_toggle:Kill() self.bigbag_toggle = nil end
        self._bigbag_hidden = nil
        self._bigbag_geometry = nil
        self._bigbag_requested_scale = nil
        self._bigbag_title_width = nil
        if self._bigbag_nativebg ~= nil then
            self.bgimage:Kill()
            self.bgimage = self._bigbag_nativebg
            self._bigbag_nativebg = nil
        end
        return close(self, ...)
    end
    local kill = self.Kill
    self.Kill = function(self, ...)
        naming.Close(self)
        -- Controls can destroy a widget directly, without first closing it.
        drag.Detach(self)
        classic_drag.Detach(self)
        return kill(self, ...)
    end
end)

-- The vanilla integrated backpack assumes a single row. Reflow its existing
-- slots so controller selection, transfers and item tooltips keep vanilla code.
AddClassPostConstruct("widgets/inventorybar", function(self)
    local rebuild = self.Rebuild
    self.Rebuild = function(self, ...)
        rebuild(self, ...)
        self.bigbag_gridbg = nil
        self.bigbag_bottom_bg = nil
        self._bigbag_integrated_view = nil
        self.expedition_gridheaders = nil
        self._bigbag_gridhidden = nil
        if self.backpack == nil or not bags.IsBag(self.backpack) or #self.backpackinv == 0 then return end
        self._bigbag_gridautoexpanded = OtherContainerOpen(self.owner, self.backpack.prefab == "roomcar_bigbag_new") or nil
        self.bigbag_gridbg = self.bottomrow:AddChild(Panel())
        self.bigbag_bottom_bg = self.bottomrow:AddChild(Panel())
        self.bigbag_bottom_bg:MoveToBack()
        integrated.Refresh(self, true)
        if self.backpack.prefab == bags.PREFAB then
            self.expedition_gridheaders = expedition_ui.Decorate(self.bottomrow,self.backpackinv,config.LANG,true,
                {self.bigbag_gridbg,self.bigbag_bottom_bg})
            expedition_ui.ReflowIntegrated(self.expedition_gridheaders, self.backpackinv)
        end
        self.bigbag_gridbg:MoveToBack()
        if self.integrated_arrow ~= nil then self.integrated_arrow:Hide() end
    end
    local closest = self.GetClosestWidget
    self.GetClosestWidget = function(self, lists, pos, dir, ...)
        if self.backpack ~= nil and bags.IsBag(self.backpack) then
            local handled, slot, list = integrated.Horizontal(self, lists, dir)
            if handled then return slot, list end
        end
        local visible, originals = {}, {}
        for _, list in pairs(lists) do
            local filtered = {}
            for key, slot in pairs(list) do
                if slot:IsVisible() then filtered[key] = slot end
            end
            visible[#visible + 1] = filtered
            originals[filtered] = list
        end
        local slot, list = closest(self, visible, pos, dir, ...)
        return slot, originals[list]
    end
    local update = self.OnUpdate
    self.OnUpdate = function(self, dt, ...)
        update(self, dt, ...)
        if self.bigbag_gridbg ~= nil then
            if integrated.Refresh(self) and self.expedition_gridheaders ~= nil then
                expedition_ui.ReflowIntegrated(self.expedition_gridheaders, self.backpackinv)
            end
            -- Keep controller slots visible while navigating inventory.
            local otheropen = not IsClassic(self.backpack) and OtherContainerOpen(self.owner, self.backpack ~= nil and self.backpack.prefab == "roomcar_bigbag_new")
            if not otheropen then self._bigbag_gridautoexpanded = nil end
            local hidden = not self.open and otheropen and not self._bigbag_gridautoexpanded
            if hidden ~= self._bigbag_gridhidden then
                self._bigbag_gridhidden = hidden
                for _, slot in ipairs(self.backpackinv) do
                    if hidden then slot:Hide() else slot:Show() end
                end
                if hidden then self.bigbag_gridbg:Hide() else self.bigbag_gridbg:Show() end
                if self.bigbag_bottom_bg ~= nil then
                    if hidden then self.bigbag_bottom_bg:Hide() else self.bigbag_bottom_bg:Show() end
                    if hidden and self.current_list == self.backpackinv then self:SelectDefaultSlot() end
                end
                for _,label in ipairs(self.expedition_gridheaders or {}) do
                    if hidden then label:Hide() else label:Show() end
                end
            end
        end
    end
end)

-- Close any stale widget for the same entity before creating its replacement.
AddClassPostConstruct("screens/playerhud", function(self)
    local open = self.OpenContainer
    self.OpenContainer = function(self, container, ...)
        if container ~= nil and bags.IsBag(container) then
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
