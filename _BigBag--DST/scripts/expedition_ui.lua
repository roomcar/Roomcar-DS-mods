local data = require("expedition_data")
local Widget = require("widgets/widget")
local Image = require("widgets/image")
local ImageButton = require("widgets/imagebutton")
local naming = require("bigbag_naming_ui")
local M = {}

local function Border(parent, x, y, width, height, color)
    local frame=parent:AddChild(Widget("expedition_section"))
    frame:SetClickable(false)
    frame:SetPosition(x,y,0)
    frame._expedition_color=color
    frame._expedition_edges={}
    for _, edge in ipairs({{0,height/2,width,3},{0,-height/2,width,3},
        {-width/2,0,3,height},{width/2,0,3,height}}) do
        local line=frame:AddChild(Image("images/ui.xml","white.tex"))
        line:SetPosition(edge[1],edge[2],0)
        line:SetSize(edge[3],edge[4])
        line:SetTint(color[1],color[2],color[3],1)
        line:SetClickable(false)
        frame._expedition_edges[#frame._expedition_edges+1]=line
    end
    return frame
end

local function GroupBounds(slots, group)
    local minx,miny,maxx,maxy=math.huge,math.huge,-math.huge,-math.huge
    for i=group.first,group.last do
        local slot=slots[i]
        local p=slot:GetPosition()
        local half=36*slot.base_scale
        minx=math.min(minx,p.x-half);maxx=math.max(maxx,p.x+half)
        miny=math.min(miny,p.y-half);maxy=math.max(maxy,p.y+half)
    end
    return (minx+maxx)/2,(miny+maxy)/2,maxx-minx,maxy-miny
end

function M.ReflowIntegrated(frames, slots)
    for i,frame in ipairs(frames) do
        local x,y,width,height=GroupBounds(slots,data.groups[i])
        frame:SetPosition(x,y,0)
        for edge,line in ipairs(frame._expedition_edges) do
            if edge<=2 then
                line:SetPosition(0,(edge==1 and 1 or -1)*height/2,0)
                line:SetSize(width,math.max(1.5,2*slots[1].base_scale))
            else
                line:SetPosition((edge==3 and -1 or 1)*width/2,0,0)
                line:SetSize(math.max(1.5,2*slots[1].base_scale),height)
            end
        end
    end
end

function M.Decorate(parent, slots, lang, integrated, backgrounds)
    local frames={}
    for index, group in ipairs(data.groups) do
        local x,y,width,height=GroupBounds(slots,group)
        local frame=Border(parent,x,y,width,height,group.border)
        frames[#frames+1]=frame
        for number=group.first,group.last do
            local slot=slots[number]
            local role=data.slots[number]
            local info=data.roles[role]
            -- No per-slot category text; stack counts remain native ItemTiles.
            if slot.label~=nil then slot.label:Hide() end
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
                else self:SetHoverText(group[lang==1 and "zh" or "en"].."\n"..data.Hint(role,lang),{font_size=20,offset_y=65}) end
            end)
            slot:ontilechangedfn(slot.tile)
        end
    end
    -- Enlarged native slots/items must draw over the section outlines. Keep
    -- the outlines above BOTH backplates, including the integrated bottom row.
    for _,frame in ipairs(frames) do frame:MoveToBack() end
    for _,background in ipairs(backgrounds or {}) do background:MoveToBack() end
    return frames
end

function M.AttachColor(widget,config,button_width)
    widget.expedition_color=widget:AddChild(ImageButton("images/ui.xml","button_small.tex","button_small_over.tex","button_small_disabled.tex"))
    -- Keep the colour indicator inside its action, above the label. A child
    -- follows the button when it moves and never intercepts clicks or focus.
    widget.expedition_marker=widget.expedition_color:AddChild(Image("images/ui.xml","white.tex"))
    widget.expedition_marker:SetPosition(0,15,0)
    widget.expedition_marker:SetSize(button_width-24,4)
    widget.expedition_marker:SetClickable(false)
    widget.expedition_color:SetHoverText(config.LANG==1
        and "点击切换颜色标记；背负和落地外观也会改变颜色。"
        or "Click to change this bag's colour, including its worn and ground appearance.",
        {font_size=20,offset_y=65})
    widget.expedition_color:SetOnClick(function()
        SendModRPCToServer(GetModRPC("roomcar_bigbag","color"),widget.container)
    end)
end

function M.Attach(widget, config)
    widget._bigbag_requested_scale=.6
    widget._bigbag_geometry=require("expedition_position")
    widget.bgimage:SetSize(288,696)
    widget.bgimage:SetPosition(0,-34,0)
    widget._bigbag_title_width=260
    widget._bigbag_title=nil
    widget.bigbag_name:SetPosition(0,292,0)
    widget.bigbag_name:SetTextSize(30)
    naming.Update(widget,config)
    widget.expedition_headers=M.Decorate(widget,widget.inv,config.LANG,false,{widget.bgimage})
    M.AttachColor(widget,config,126)
    for i,button in ipairs({widget.expedition_color,widget.bigbag_toggle,widget.bigbag_dragkey,widget.bigbag_reset}) do
        button:SetPosition(i%2==1 and -66 or 66,i<=2 and -307 or -353,0)
        button:ForceImageSize(126,42)
        button.scale_on_focus=false
        button:SetTextSize(i==1 and 28 or 30)
        button.text:SetPosition(0,-2,0)
    end
    M.Update(widget,config,false)
end

function M.Update(widget, config, collapsed)
    for _, frame in ipairs(widget.expedition_headers or {}) do
        if collapsed then frame:Hide() else frame:Show() end
    end
    if widget.expedition_color~=nil then
        local index=widget.container.roomcar_bagcolor:value()
        local color=data.colors[index] or data.colors[2]
        widget.expedition_marker:SetTint(color.rgb[1],color.rgb[2],color.rgb[3],1)
        widget.expedition_color:SetText(config.LANG==1
            and (widget.container.prefab==data.PREFAB and "颜色 "..color.zh or color.zh) or color.en)
    end
end

function M.Close(widget)
    for _,frame in ipairs(widget.expedition_headers or {}) do frame:Kill() end
    widget.expedition_headers=nil
    if widget.expedition_marker then widget.expedition_marker:Kill();widget.expedition_marker=nil end
    if widget.expedition_color then widget.expedition_color:Kill();widget.expedition_color=nil end
end
return M
