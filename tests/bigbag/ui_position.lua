-- Run from the repository root with Lua 5.1 and the DST scripts directory.
package.path = "_BigBag--DST/scripts/?.lua;" .. assert(arg[1], "Pass the DST scripts directory") .. "/?.lua;" .. package.path
local geometry = require("bigbag_ui_position")
local json = require("json")
local passed = 0
local function test(name, fn)
    fn()
    passed = passed + 1
    print("PASS " .. name)
end
local function near(a,b) assert(math.abs(a-b)<.01, tostring(a).." ~= "..tostring(b)) end

test("whole panel, including footer, fits at every edge and supported screen size", function()
    for _, size in ipairs({{320,200},{640,480},{1280,720},{1920,1080},{3440,1440}}) do
        for _, scale in ipairs({.24,.48,1,2,4}) do
            local w,h=size[1],size[2]
            local s=scale*geometry.Fit(w,h,scale,scale)
            for _, p in ipairs({{-1e6,-1e6},{1e6,1e6},{0,1e6},{1e6,0}}) do
                local x,y=geometry.Clamp(p[1],p[2],w,h,s,s)
                assert(x+geometry.LEFT*s >= 11.99 and x+geometry.RIGHT*s <= w-11.99)
                assert(y+geometry.BOTTOM*s >= 11.99 and y+geometry.TOP*s <= h-11.99)
            end
        end
    end
end)
test("invalid saved coordinates are rejected and legacy offscreen values are bounded", function()
    for _, data in ipairs({{}, {x="bad",y=0}, {x=0/0,y=0}, {x=math.huge,y=0}}) do
        assert(geometry.DecodePosition(data)==nil)
    end
    local p=geometry.DecodePosition({x=-10,y=100})
    assert(p.x==0 and p.y==1)
end)

local width,height,parentscale = 1920,1080,2
local held,mousex,mousey,callback,saved,writes = false,0,0,nil,nil,0
local hud = {}
TheSim = {
    GetScreenSize=function() return width,height end,
    GetPersistentString=function(_, _, cb) callback=cb end,
    SetPersistentString=function(_, _, data) saved=data; writes=writes+1 end,
}
KEY_F1,KEY_F2=1,2
TheInput = {
    IsKeyDown=function(_,key) return held and key==1 end,
    ControllerAttached=function() return false end,
    GetScreenPosition=function() return {x=mousex,y=mousey} end,
}
TheFrontEnd = {GetActiveScreen=function() return hud end}
local config={UI_SCALE=.8,UI_DRAG_KEY=1}
local function widget()
    local w={owner={HUD=hud}, focus=true, x=-170,y=-40,scale=.48}
    w.inst={IsValid=function() return true end}
    w.parent={} -- Current engine has no UITransform:GetWorldScale method.
    function w:GetPosition() return {x=self.x,y=self.y,z=0} end
    function w:SetPosition(x,y) if type(x)=="table" then self.x,self.y=x.x,x.y else self.x,self.y=x,y end end
    function w:SetScale(s) self.scale=s end
    function w:GetWorldPosition() return {x=width+self.x*parentscale,y=height/2+self.y*parentscale} end
    function w:GetLooseScale() return self.scale,self.scale,1 end
    function w:IsVisible() return true end
    function w:UpdateBigBagDragLabel() end
    function w:UpdateBigBagVisibility() end
    return w
end
local drag=require("bigbag_ui_drag")
local w=widget()
test("reset wins over a late preferences read", function()
    drag.Attach(w,config)
    drag.Reset()
    local before=w:GetWorldPosition()
    callback(true,'{"position":{"x":0.1,"y":0.9},"key":8}')
    near(before.x,w:GetWorldPosition().x)
    near(before.y,w:GetWorldPosition().y)
    assert(drag.GetKey(config)==1)
end)
test("drag uses physical pixels under scaled, right-anchored parents and writes only on release", function()
    local before=w:GetWorldPosition()
    mousex,mousey=before.x,before.y
    held=true;drag.Update(w,config)
    local previouswrites=writes
    mousex,mousey=mousex-100,mousey+50
    drag.Update(w,config)
    near(w:GetWorldPosition().x,before.x-100)
    near(w:GetWorldPosition().y,before.y+50)
    assert(writes==previouswrites)
    held=false;drag.Update(w,config)
    assert(writes==previouswrites+1)
    local data=json.decode(saved)
    near(data.position.x,w:GetWorldPosition().x/width)
end)
test("position survives reopening and resizing never loses footer buttons", function()
    local before=w:GetWorldPosition()
    drag.Detach(w)
    w=widget();drag.Attach(w,config)
    near(w:GetWorldPosition().x,before.x)
    width,height,parentscale=640,480,3
    drag.Update(w,config)
    local p,s=w:GetWorldPosition(),drag.ScreenScale(w)
    assert(p.x+geometry.LEFT*s.x>=11.99 and p.x+geometry.RIGHT*s.x<=width-11.99)
    assert(p.y+geometry.BOTTOM*s.y>=11.99 and p.y+geometry.TOP*s.y<=height-11.99)
end)
test("local key choice cycles through F1-F9 and Off; reset clears saved position", function()
    drag.CycleKey(config);assert(drag.GetKey(config)==2)
    for _=1,8 do drag.CycleKey(config) end
    assert(drag.GetKey(config)==0 and not drag.KeyHeld(config))
    drag.CycleKey(config);assert(drag.GetKey(config)==1)
    drag.Reset();assert(json.decode(saved).position==nil)
    drag.Detach(w)
    w.inst.IsValid=function() error("detached widget accessed") end
    drag.Reset()
end)
print(passed .. " UI position tests passed")
