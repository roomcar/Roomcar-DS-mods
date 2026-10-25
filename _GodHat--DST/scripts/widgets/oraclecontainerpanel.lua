-- Original Big Bag texture and feathered corners. The Oracle atlas crops its
-- centre/edges to this panel's natural dimensions instead of squeezing the
-- large square Big Bag centre non-uniformly. At 256x398 every patch is 1:1.
local Widget = require("widgets/widget")
local NineSlice = require("widgets/nineslice")
local BORDER, PADDING = 56,20
local Panel = Class(Widget, function(self)
    Widget._ctor(self, "OracleContainerPanel")
    self.atlas = "images/oracle_container_bg_nine.xml"
    self.texture = "oracle_container_bg.tex"
    self.patch = self:AddChild(NineSlice(self.atlas,
        "tl.tex", "top.tex", "tr.tex", "left.tex", "center.tex", "right.tex",
        "bl.tex", "bottom.tex", "br.tex"))
    self.border_scale = 1
    self:SetSize(256,398)
end)

function Panel:SetBorderScale(scale)
    if self.border_scale == scale then return end
    self.border_scale = scale
    self:SetSize(self.width,self.height)
end

function Panel:SetSize(width,height)
    self.width,self.height = width,height
    -- Thin integrated strips must shrink ALL parts of each corner uniformly,
    -- not squash one axis or overlap the top/bottom corners.
    local scale=math.min(self.border_scale,width/(2*(BORDER-PADDING)),height/(2*(BORDER-PADDING)))
    local border,padding=BORDER*scale,PADDING*scale
    self.corner_size=border
    self.transparent_padding=padding
    for _,image in ipairs(self.patch.elements) do image:SetSize(border,border) end
    self.patch:SetSize(math.max(0,width+2*padding-2*border),math.max(0,height+2*padding-2*border))
end

function Panel:GetSize() return self.width,self.height end
return Panel
