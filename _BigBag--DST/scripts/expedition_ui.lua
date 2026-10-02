local data = require("expedition_data")
local Text = require("widgets/text")
local Image = require("widgets/image")
local ImageButton = require("widgets/imagebutton")
local M = {}

function M.Decorate(parent, slots, lang, integrated)
    local headers = {}
    for index, group in ipairs(data.groups) do
        local x,y=group.x,group.y
        if integrated then x=((index-1)%3-1)*350; y=index<=3 and 480 or 265 end
        local label=parent:AddChild(Text(CHATFONT_OUTLINE,30,group[lang==1 and "zh" or "en"]))
        label:SetPosition(x,y)
        label:SetColour(1,.94,.78,1)
        label:SetClickable(false)
        headers[#headers+1]=label
        for number=group.first,group.last do
            local slot=slots[number]
            local role=data.slots[number]
            local info=data.roles[role]
            if integrated then
                local n=number-group.first
                slot:SetPosition(x+(n%group.cols-(group.cols-1)/2)*group.spacing,y-55-math.floor(n/group.cols)*82)
            end
            if group.cols==4 then
                slot.base_scale=.86
                slot.highlight_scale=1.05
                slot:SetScale(.86)
            end
            slot:SetLabel(data.Label(role,lang),{1,.98,.9,1})
            -- ItemSlot defaults to NUMBERFONT, intended for stack-like labels.
            -- Use the reading font and compensate for the smaller material slots.
            local labelscale=group.cols==4 and 1/.86 or 1
            slot.label:SetFont(CHATFONT_OUTLINE)
            slot.label:SetSize(26)
            slot.label:SetScale(labelscale)
            slot.label:SetPosition(0,-36*labelscale)
            slot.label:SetClickable(false)
            if info.icon then
                slot:SetBGImage2(GetInventoryItemAtlas(info.icon),info.icon,{.3,.24,.16,.3})
                slot.bgimage2:SetClickable(false)
                slot.bgimage2:SetSize(48,48)
            end
            local changed=slot.ontilechangedfn
            slot:SetOnTileChangedFn(function(self,tile)
                if changed then changed(self,tile) end
                if self.bgimage2 then
                    if tile then self.bgimage2:Hide() else self.bgimage2:Show() end
                end
                if tile then self:ClearHoverText()
                else self:SetHoverText(data.Hint(role,lang),{font_size=20,offset_y=65}) end
            end)
            slot:ontilechangedfn(slot.tile)
        end
    end
    return headers
end
function M.Attach(widget, config)
    widget.expedition_headers=M.Decorate(widget,widget.inv,config.LANG)
    -- Leave room below the final row's larger labels; stay inside drag bounds.
    widget.bigbag_toggle:SetPosition(110,-332)
    widget.bigbag_dragkey:SetPosition(-100,-386)
    widget.bigbag_reset:SetPosition(110,-386)
    widget.expedition_marker=widget:AddChild(Image("images/ui.xml","white.tex"))
    widget.expedition_marker:SetPosition(-248,315)
    widget.expedition_marker:SetSize(12,30)
    widget.expedition_marker:SetClickable(false)
    widget.expedition_color=widget:AddChild(ImageButton("images/ui.xml","button_small.tex","button_small_over.tex","button_small_disabled.tex"))
    widget.expedition_color:SetPosition(-100,-332)
    widget.expedition_color:SetTextSize(26)
    widget.expedition_color:SetHoverText(config.LANG==1 and "更换这只背包的颜色标记，随背包保存。" or "Change this bag's saved colour marker.",{font_size=20,offset_y=65})
    widget.expedition_color:SetOnClick(function()
        SendModRPCToServer(GetModRPC("roomcar_bigbag","color"),widget.container)
    end)
    M.Update(widget,config,false)
end
function M.Update(widget, config, collapsed)
    for _, label in ipairs(widget.expedition_headers or {}) do
        if collapsed then label:Hide() else label:Show() end
    end
    if widget.expedition_color ~= nil then
        local index=widget.container.roomcar_bagcolor:value()
        local color=data.colors[index] or data.colors[2]
        widget.expedition_marker:SetTint(color.rgb[1],color.rgb[2],color.rgb[3],1)
        widget.expedition_color:SetText((config.LANG==1 and "标记：" or "Mark: ")..color[config.LANG==1 and "zh" or "en"])
    end
end
function M.Close(widget)
    for _, label in ipairs(widget.expedition_headers or {}) do label:Kill() end
    widget.expedition_headers=nil
    if widget.expedition_color then widget.expedition_color:Kill();widget.expedition_color=nil end
    if widget.expedition_marker then widget.expedition_marker:Kill();widget.expedition_marker=nil end
end
return M
