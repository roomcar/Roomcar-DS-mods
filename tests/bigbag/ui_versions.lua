-- Headless integration: execute the installed game's real ContainerWidget;
-- only rendering/input/entity primitives are substitutes (no GPU screenshot).
package.path = "_BigBag--DST/scripts/?.lua;" .. assert(arg[1]) .. "/?.lua;" .. package.path
require("class")
GLOBAL=_G
Vector3=function(x,y,z) return {x=x or 0,y=y or 0,z=z or 0} end
TUNING={}; TECH={NONE={},SCIENCE_ONE={},SCIENCE_TWO={},MAGIC_ONE={},MAGIC_TWO={}}
Asset=function(...) return {...} end
Ingredient=function(name,amount) return {type=name,amount=amount} end
local containers={params={},MAXITEMSLOTS=0}; package.loaded.containers=containers
local recipes,hooks,rpcs={},{},{}
GetModConfigData=function(key) return ({UI_SCALE=.8,UI_DRAG_KEY=8,UI_X=123,UI_Y=42})[key] end
TheNet={IsDedicated=function() return true end}
AddRecipe2=function(id,ingredients,tech,options) recipes[id]={ingredients=ingredients,tech=tech,options=options} end
AddClassPostConstruct=function(name,fn) hooks[name]=fn end
AddModRPCHandler=function(_,name,fn) rpcs[name]=fn end
AddComponentPostInit=function() end
AddMinimapAtlas=function() end
RegisterInventoryItemAtlas=function() end
modimport=function() end
dofile("_BigBag--DST/modmain.lua")
local config=TUNING.ROOMCAR_BIGBAG
local passed=0
local function test(name,fn) fn(); passed=passed+1; print("PASS "..name) end
test("classic widget matches the actual pre-upgrade Git widget including all slot indices",function()
    local file=assert(io.open("tests/bigbag/fixtures/pre-upgrade-widget.lua","rb"));local source=file:read("*a");file:close()
    -- Execute the historical registration block, not a manually copied fixture.
    local start=assert(source:find("params.bigbag =",1,true))
    local env=setmetatable({params={},Vector3=Vector3,containers=containers},{__index=_G})
    local chunk=assert(loadstring(source:sub(start)));setfenv(chunk,env);chunk()
    local old,new=env.params.bigbag,containers.params.bigbag
    assert(new.widget.pos.x==old.widget.pos.x and new.widget.pos.y==old.widget.pos.y)
    assert(new.widget.bgatlas==old.widget.bgatlas and new.widget.bgimage==old.widget.bgimage)
    assert(new.widget.buttoninfo==nil and #new.widget.slotpos==64)
    for i,p in ipairs(old.widget.slotpos) do
        local q=new.widget.slotpos[i];assert(p.x==q.x and p.y==q.y and p.z==q.z)
    end
    assert(old.type==new.type and old.issidewidget==new.issidewidget)
    assert(recipes.bigbag and recipes.roomcar_bigbag_new and recipes.roomcar_expeditionbag)
    assert(#containers.params.roomcar_expeditionbag.widget.slotpos==32)
end)

local tasks={}
local function entity()
    return {IsValid=function()return true end, ListenForEvent=function()end,RemoveEventCallback=function()end,
        DoPeriodicTask=function(_,_,fn) local t={fn=fn,Cancel=function(self)self.cancelled=true end};tasks[#tasks+1]=t;return t end,
        DoSimTaskInTime=function(_,_,fn) return {fn=fn,Cancel=function()end} end}
end
local W=Class(function(self)
    self.inst=entity();self.children={};self.pos=Vector3();self.scale=1;self.visible=true
end)
function W:AddChild(child) self.children[#self.children+1]=child;child.parent=self;return child end
function W:SetPosition(x,y,z) self.pos=type(x)=="table" and Vector3(x.x,x.y,x.z) or Vector3(x,y,z) end
function W:GetPosition()return self.pos end
function W:GetWorldPosition()return Vector3(1920+self.pos.x*2,540+self.pos.y*2,0)end
function W:GetLooseScale()return self.scale,self.scale,1 end
function W:SetScale(x)self.scale=x end
function W:SetSize(w,h)self.width,self.height=w,h end
function W:GetSize()return self.width or 24,self.height or 24 end
function W:SetHRegPoint()end
function W:SetVRegPoint()end
function W:ForceImageSize(w,h)self.size_x,self.size_y=w,h;self.image:SetSize(w,h)end
function W:SetTextSize(n)self.fontsize=n end
function W:Show()self.visible=true end
function W:Hide()self.visible=false end
function W:SetClickable(value)self.clickable=value end
function W:SetTint(r,g,b,a)self.tint={r,g,b,a} end
function W:MoveToBack()
    if self.parent==nil then return end
    for i,child in ipairs(self.parent.children)do
        if child==self then table.remove(self.parent.children,i);table.insert(self.parent.children,1,self);return end
    end
end
function W:ScaleTo(_,target)self:SetScale(target)end
function W:IsVisible()return self.visible end
function W:Kill()self.killed=true end
function W:SetTexture(a,t)self.atlas=a;self.texture=t;self.width,self.height=596,596 end
function W:SetText(t)self.textvalue=t end
function W:GetString()return self.textvalue or "" end
function W:SetTruncatedString(t)self.textvalue=t end
function W:SetOnClick(fn)self.onclick=fn end
function W:SetHoverText(text,opts)self.hovertext=text;self.hoveroptions=opts end
function W:SetTile(tile)self.tile=tile end
function W:SetLabel(t)self.label=W();self.label.textvalue=t end
function W:SetBGImage2()self.bgimage2=W()end
function W:SetOnTileChangedFn(fn)self.ontilechangedfn=fn end
function W:StartUpdating()self.updating=true end
function W:StopUpdating()self.updating=false end
function W:OnControl()return false end
for _,key in ipairs({"SetFont","SetSize","SetColour","SetClickable","SetVAlign","SetTextSize","SetDisabledFont","SetHoverText","ClearHoverText","SetTint","MoveToBack","SetReadOnlyVisuals"})do
    if W[key]==nil then W[key]=function()end end
end
local function button()local b=W();b.text=W();b.image=W();return b end
local function anim()local a=W();a.GetAnimState=function()return setmetatable({},{__index=function()return function()end end})end;return a end
package.loaded["widgets/widget"]=W
package.loaded["widgets/image"]=W;Image=W
package.loaded["widgets/imagebutton"]=button
package.loaded["widgets/textbutton"]=button
package.loaded["widgets/text"]=function(_,_,t)local w=W();w.textvalue=t;return w end
package.loaded["widgets/uianim"]=anim
package.loaded["widgets/itemtile"]=W
package.loaded["widgets/invslot"]=function()local w=W();w.base_scale=1;w.highlight_scale=1.2;return w end
package.loaded["screens/redux/inputdialog"]=function()error("not used by this test")end
BUTTONFONT="button";CHATFONT_OUTLINE="chat";ANCHOR_MIDDLE=0;CONTROL_PRIMARY=1;CONTROL_ACCEPT=2
ANCHOR_LEFT=1;ANCHOR_RIGHT=2;ANCHOR_BOTTOM=3;ANCHOR_TOP=4
package.loaded.constants={}
TheWorld={ismastersim=false};KEY_F1=1;KEY_F8=8
local held,mousex,mousey=false,0,0
TheInput={ControllerAttached=function()return false end,IsKeyDown=function(_,key)return held and key==KEY_F1 end,GetScreenPosition=function()return Vector3(mousex,mousey)end}
local saved={}
TheSim={GetScreenSize=function()return 1920,1080 end,GetPersistentString=function(_,id,cb)
    if id=="roomcar_bigbag_ui_v1" then cb(true,'{"position":{"x":-90,"y":99},"key":8}') else cb(false,"")end
end,SetPersistentString=function(_,id,data)saved[id]=data end}
GetInventoryItemAtlas=function()return "images/inventoryimages.xml"end
local crafting=false
local owner={components={},HUD={controls={containers={},inv={SelectDefaultSlot=function()end}},IsCraftingOpen=function()return crafting end},_bigbag_collapsed=true}
TheFrontEnd={GetActiveScreen=function()return owner.HUD end}
dofile("_BigBag--DST/scripts/bigbag_ui.lua")
local ContainerWidget=require("widgets/containerwidget")
local function bag(id)
    local b={prefab=id,replica={},roomcar_bagcolor={value=function()return 1 end}}
    b.replica.container={GetWidget=function()return containers.params[id].widget end,IsInfiniteStackSize=function()return false end,
        IsReadOnlyContainer=function()return false end,IsSideWidget=function()return true end,GetItems=function()return {}end}
    function b:GetDisplayName()return id end
    return b
end
local function panel(id)
    local w=ContainerWidget(owner);w.parent=W();hooks["widgets/containerwidget"](w);w:Open(bag(id),owner);return w
end
local classic,new,expedition
test("classic uses a tight original-texture square, native scale and zero controls despite old hidden/offscreen preferences",function()
    classic=panel("bigbag")
    assert(classic.scale==.6 and classic.bgimage.width==544 and classic.bgimage.height==544)
    assert(classic.pos.x==-200 and classic.pos.y==-60 and #classic.inv==64)
    assert(classic.bigbag_toggle==nil and classic.bigbag_name==nil and classic.button==nil and classic.bigbag_reset==nil)
    classic:UpdateBigBagVisibility();assert(classic.bgimage:IsVisible() and classic.inv[64]:IsVisible())
end)
test("fixed F1 drag works even when modern preference selects F8; saved profile is independent",function()
    classic.focus=true;local p=classic:GetWorldPosition();mousex,mousey=p.x,p.y;held=true;classic:OnUpdate(0)
    mousex=mousex-100;classic:OnUpdate(0);held=false;classic:OnUpdate(0)
    assert(classic:GetWorldPosition().x==p.x-100 and saved.roomcar_bigbag_classic_ui_v1)
    assert(saved.roomcar_bigbag_ui_v1==nil)
end)
test("new bag uses full-size slots, a nine-slice panel around title and five compact controls",function()
    new=panel("roomcar_bigbag_new")
    assert(new.scale==.6 and new.bgimage.width==544 and new.bgimage.height==632 and #new.inv==64)
    assert(new.bgimage.atlas=="images/bigbagbg_nine.xml")
    assert(new.button and new.bigbag_name and new.bigbag_toggle and new.bigbag_reset)
    assert(new.bigbag_name.pos.y==286 and new.bigbag_name.fontsize==33)
    assert(new.bgimage.pos.y+316 > new.bigbag_name.pos.y+33/2)
    for i,b in ipairs({new.button,new.bigbag_toggle,new.expedition_color,new.bigbag_dragkey,new.bigbag_reset})do
        assert(b.pos.x==(i-3)*104 and b.pos.y==-292 and b.size_x==98 and b.size_y==42 and b.fontsize==26)
        assert(b.pos.y-21 > new.bgimage.pos.y-316 and not b.scale_on_focus)
    end
    assert(not new._bigbag_hidden and new.inv[64]:IsVisible())
    new.bigbag_toggle.onclick();assert(new._bigbag_hidden)
    require("bigbag_ui_drag").Reset();assert(not new._bigbag_hidden)
end)
test("opening always expands a bag even with a stale fold flag and the crafting menu already open",function()
    crafting=true;owner._bigbag_collapsed=true
    local w=panel("roomcar_bigbag_new")
    assert(not w._bigbag_hidden and w.inv[64]:IsVisible())
    w:UpdateBigBagVisibility();assert(not w._bigbag_hidden)
    crafting=false;w:UpdateBigBagVisibility();crafting=true;w:UpdateBigBagVisibility();assert(w._bigbag_hidden)
    crafting=false;w:Close();w:Kill()
end)
test("new auto-hide detects recipe menu and containers, honours temporary manual expansion, restores content",function()
    crafting=true;new:UpdateBigBagVisibility();assert(new._bigbag_hidden and not new.inv[1]:IsVisible())
    new.bigbag_toggle.onclick();assert(not new._bigbag_hidden)
    crafting=false;new:UpdateBigBagVisibility();crafting=true;new:UpdateBigBagVisibility();assert(new._bigbag_hidden)
    crafting=false;new:UpdateBigBagVisibility();assert(not new._bigbag_hidden)
    local chest={replica={container={IsSideWidget=function()return false end}}};owner.HUD.controls.containers[chest]={isopen=true}
    new:UpdateBigBagVisibility();assert(new._bigbag_hidden)
    owner.HUD.controls.containers={};new:UpdateBigBagVisibility();assert(not new._bigbag_hidden)
end)
test("Expedition has a full-size 4x8 grid, six coloured section frames and no category labels",function()
    owner._bigbag_collapsed=true;crafting=true;expedition=panel("roomcar_expeditionbag")
    assert(#expedition.inv==32 and expedition.scale==.6 and expedition.bgimage.width==288 and expedition.bgimage.height==696)
    assert(expedition.expedition_color and expedition.expedition_headers and not expedition._bigbag_hidden)
    assert(expedition.bigbag_toggle.pos.y==-307 and expedition.bigbag_reset.pos.y==-353)
    assert(expedition.expedition_color.pos.x==-66 and expedition.bigbag_dragkey.pos.x==-66)
    assert(expedition.bigbag_toggle.pos.x==66 and expedition.bigbag_reset.pos.x==66)
    local xs,ys={},{}
    for _,slot in ipairs(expedition.inv)do
        xs[slot.pos.x]=true;ys[slot.pos.y]=true
        assert(slot.base_scale==1 and (slot.label==nil or not slot.label:IsVisible()))
    end
    local nx,ny=0,0;for _ in pairs(xs)do nx=nx+1 end;for _ in pairs(ys)do ny=ny+1 end
    assert(nx==4 and ny==8)
    local colours={}
    for _,frame in ipairs(expedition.expedition_headers)do
        assert(#frame.children==4)
        local key=table.concat(frame._expedition_color,",");assert(not colours[key]);colours[key]=true
    end
    assert(expedition.inv[1].pos.x==-102 and expedition.inv[6].pos.y==107 and expedition.inv[7].pos.x==36)
    assert(expedition.inv[13].pos.y==35 and expedition.inv[16].pos.y==35)
    assert(expedition.inv[21].pos.y==-109 and expedition.inv[28].pos.y==-175)
    assert(expedition.inv[29].pos.y==-247 and expedition.inv[32].pos.y==-247)
    crafting=false
end)

test("both panels contain title, marker, all buttons and slots within their nine-slice backgrounds",function()
    for _,w in ipairs({new,expedition})do
        local bg=w.bgimage
        local left,right=bg.pos.x-bg.width/2,bg.pos.x+bg.width/2
        local bottom,top=bg.pos.y-bg.height/2,bg.pos.y+bg.height/2
        assert(w.bigbag_name.pos.y+w.bigbag_name.fontsize/2<top)
        assert(w.bigbag_name.pos.y-w.bigbag_name.fontsize/2>bottom)
        for _,key in ipairs({"button","bigbag_toggle","bigbag_dragkey","bigbag_reset","expedition_color"})do
            local b=w[key]
            if b then
                assert(b.pos.x-b.size_x/2>left and b.pos.x+b.size_x/2<right)
                assert(b.pos.y-b.size_y/2>bottom and b.pos.y+b.size_y/2<top)
            end
        end
        local geom=w._bigbag_geometry
        assert(geom.LEFT<=left and geom.RIGHT>=right and geom.BOTTOM<=bottom and geom.TOP>=top)
        for _,slot in ipairs(w.inv)do assert(slot.base_scale==1)end
    end
end)

test("name text has no permanent rename suffix; hover advertises the clickable rename action",function()
    local naming=require("bigbag_naming_ui")
    for _,lang in ipairs({0,1})do
        local w={container={GetDisplayName=function()return "矿石备用包"end},AddChild=W.AddChild,children={}}
        naming.Attach(w,{LANG=lang})
        assert(w.bigbag_name.textvalue=="矿石备用包")
        assert(w.bigbag_name.hovertext==(lang==1 and "点击重命名背包" or "Click to rename this bag"))
        assert(type(w.bigbag_name.onclick)=="function")
        w.container.GetDisplayName=function()return "新名字"end
        naming.Update(w,{LANG=lang});assert(w.bigbag_name.textvalue=="新名字")
    end
end)

test("new colour button sends the native colour RPC for the current bag",function()
    local oldsend,oldrpc=SendModRPCToServer,GetModRPC
    local target,count
    GetModRPC=function(_,name)assert(name=="color");return 123 end
    SendModRPCToServer=function(rpc,inst)assert(rpc==123);target=inst;count=(count or 0)+1 end
    new.expedition_color.onclick();assert(count==1 and target==new.container)
    assert(new.expedition_marker:IsVisible())
    SendModRPCToServer,GetModRPC=oldsend,oldrpc
end)

test("both colour indicators live inside their buttons and follow every networked colour",function()
    local ui=require("expedition_ui")
    local colors=require("expedition_data").colors
    for _,w in ipairs({new,expedition})do
        local b,m=w.expedition_color,w.expedition_marker
        assert(m.parent==b and m.clickable==false)
        assert(math.abs(m.pos.x)+m.width/2<b.size_x/2)
        assert(math.abs(m.pos.y)+m.height/2<b.size_y/2)
        assert(m.pos.y-m.height/2>b.text.pos.y+b.fontsize/2)
        local original=w.container.roomcar_bagcolor.value
        for index,color in ipairs(colors)do
            w.container.roomcar_bagcolor.value=function()return index end
            ui.Update(w,config,false)
            for component=1,3 do assert(m.tint[component]==color.rgb[component])end
            assert(m.tint[4]==1)
        end
        w.container.roomcar_bagcolor.value=original;ui.Update(w,config,false)
    end
end)

test("folding either modern bag hides every decoration/control except Expand and restores them",function()
    for _,w in ipairs({new,expedition})do
        for _,lang in ipairs({1,2})do
            config.LANG=lang
            assert(not w._bigbag_hidden)
            w.bigbag_toggle.onclick()
            assert(w._bigbag_hidden and w.bigbag_toggle:IsVisible())
            assert(w.bigbag_toggle.textvalue==(lang==1 and "展开" or "Expand"))
            for _,key in ipairs({"button","bigbag_name","bigbag_dragkey","bigbag_reset","expedition_color","expedition_marker"})do
                assert(w[key]==nil or not w[key]:IsVisible(),key.." remains visible")
            end
            for _,s in ipairs(w.inv)do assert(not s:IsVisible())end
            assert(not w.bgimage:IsVisible())
            for _,frame in ipairs(w.expedition_headers or {})do assert(not frame:IsVisible())end
            -- Periodic name/colour refresh must not re-show hidden controls.
            w._bigbag_title=nil;w.bigbag_task.fn()
            assert(not w.bigbag_name:IsVisible() and not w.bigbag_reset:IsVisible())
            w.bigbag_toggle.onclick()
            assert(not w._bigbag_hidden and w.bigbag_toggle:IsVisible())
            for _,key in ipairs({"button","bigbag_name","bigbag_dragkey","bigbag_reset","expedition_color","expedition_marker"})do
                assert(w[key]==nil or w[key]:IsVisible(),key.." was not restored")
            end
            assert(w.bgimage:IsVisible())
            for _,s in ipairs(w.inv)do assert(s:IsVisible())end
        end
    end
    config.LANG=1
end)

local function opencontainer(id,stewer)
    local inst={prefab=id,HasTag=function(_,tag)return stewer and tag=="stewer" end,
        replica={container={IsSideWidget=function()return false end}}}
    owner.HUD.controls.containers[inst]={isopen=true}
    return inst
end

test("cooking keeps side bags available across periodic transfer refreshes, including with recipe menu open",function()
    for _,w in ipairs({new,expedition})do
        for _,id in ipairs({"cookpot","portablecookpot","archive_cookpot","modded_stewer"})do
            owner.HUD.controls.containers={}
            local pot=opencontainer(id,true)
            crafting=true
            for _=1,4 do
                -- The periodic callback which previously folded the bag after
                -- the pot opened/ingredients moved; remote client has no components.
                w.bigbag_task.fn()
                assert(not w._bigbag_hidden and w.inv[1]:IsVisible() and w.inv[#w.inv]:IsVisible())
                assert(w.bigbag_name:IsVisible())
            end
            w.bigbag_toggle.onclick();assert(w._bigbag_hidden,"cooking must not override manual fold")
            w.bigbag_task.fn();assert(w._bigbag_hidden)
            w.bigbag_toggle.onclick();assert(not w._bigbag_hidden)
            owner.HUD.controls.containers[pot].isopen=false
            crafting=false;w.bigbag_task.fn()
            assert(not w._bigbag_hidden)
        end
    end
    owner.HUD.controls.containers={}
end)

test("cooking takes priority over a chest/cookbook but ordinary auto-hide and manual fold remain functional",function()
    local pot=opencontainer("cookpot",true)
    local chest=opencontainer("icebox",false)
    owner.HUD.cookbookscreen={}
    new:UpdateBigBagVisibility();assert(not new._bigbag_hidden)
    owner.HUD.controls.containers[pot].isopen=false
    new:UpdateBigBagVisibility();assert(new._bigbag_hidden)
    new.bigbag_toggle.onclick();assert(not new._bigbag_hidden)
    owner.HUD.controls.containers={};owner.HUD.cookbookscreen=nil
    new:UpdateBigBagVisibility()
    config.AUTOHIDE=false
    opencontainer("icebox",false);new:UpdateBigBagVisibility();assert(not new._bigbag_hidden)
    new.bigbag_toggle.onclick();assert(new._bigbag_hidden)
    new.bigbag_toggle.onclick();assert(not new._bigbag_hidden)
    owner.HUD.controls.containers={};config.AUTOHIDE=true
end)
-- Load actual native navigation; rendering and the initial slot creation remain
-- substitutes. This exercises CursorNav/GetInventoryLists/GetClosestWidget.
for _,name in ipairs({"tilebg","equipslot","hudcompass"})do package.loaded["widgets/"..name]=W end
package.loaded["widgets/templates"]={}
package.loaded["util/sourcemodifierlist"]={}
local NativeInv=require("widgets/inventorybar")
VecUtil_Dot=function(x,y,dx,dy)return x*dx+y*dy end
function W:DeHighlight()end
local function bar(id)
    local w=W();w.owner=owner;w.backpack=bag(id);w.bottomrow=W();w.toprow=W();w.backpackinv={};w.integrated_arrow=W()
    w.bottomrow:SetPosition(0,-38);w.toprow:SetPosition(0,38)
    w.testscale=1
    function w.bottomrow:GetWorldPosition()local width=TheSim:GetScreenSize();return Vector3(width/2+self.pos.x*w.testscale,200+self.pos.y*w.testscale)end
    local function slot(parent,index)
        local s=parent:AddChild(W());s.num=index;s.base_scale=1;s.highlight_scale=1.2
        function s:GetWorldPosition()local width=TheSim:GetScreenSize();return Vector3(width/2+self.pos.x*w.testscale,200+(self.pos.y+parent.pos.y)*w.testscale)end
        s.inst.UITransform={GetWorldPosition=function()local p=s:GetWorldPosition();return p.x,p.y,p.z end}
        return s
    end
    for i=1,#containers.params[id].widget.slotpos do local s=slot(w.bottomrow,i);s:SetPosition(i*70,120);w.backpackinv[i]=s end
    w.inv={};w.equip={}
    for i=1,15 do local s=slot(w.toprow,i);s:SetPosition((i-8)*80,0);w.inv[i]=s end
    for i=1,3 do local s=slot(w.toprow,i);s:SetPosition(560+i*80,0);w.equip[i]=s end
    w.Rebuild=function()end;w.OnUpdate=function()end
    for _,name in ipairs({"GetClosestWidget","GetInventoryLists","CursorNav","SelectSlot","SelectDefaultSlot","GetCursorItem","GetCursorSlot","CursorLeft","CursorRight","CursorUp","CursorDown"})do w[name]=NativeInv[name]end
    hooks["widgets/inventorybar"](w);w:Rebuild();return w
end
test("classic and new integrated grids share compact 40+24 while Expedition has 12+20",function()
    local c,n,e=bar("bigbag"),bar("roomcar_bigbag_new"),bar("roomcar_expeditionbag")
    for i=1,64 do
        assert(c.backpackinv[i].pos.x==n.backpackinv[i].pos.x and c.backpackinv[i].pos.y==n.backpackinv[i].pos.y)
        assert(c.backpackinv[i].base_scale==.8 and n.backpackinv[i].base_scale==.8)
        assert(c.backpackinv[i].num==i and n.backpackinv[i].num==i)
    end
    assert(not c.integrated_arrow:IsVisible())
    assert(n.backpackinv[1].pos.y==n.backpackinv[20].pos.y)
    assert(n.backpackinv[21].pos.y==n.backpackinv[40].pos.y)
    assert(n.backpackinv[1].pos.y>n.backpackinv[21].pos.y)
    for i=41,64 do assert(n.backpackinv[i].pos.y==0)end
    assert(n.bigbag_gridbg.pos.y-n.bigbag_gridbg.height/2 > 76+34)
    assert(n.bigbag_bottom_bg.height/2 < 76-34)
    for i=1,32 do
        assert(e.backpackinv[i].pos.y==(i<=12 and e.backpackinv[1].pos.y or 0))
        assert(e.backpackinv[i].base_scale==.8 and e.backpackinv[i].num==i)
    end
    assert(math.abs(e.bigbag_gridbg.height-60.8)<.001 and math.abs(e.bigbag_bottom_bg.height-60.8)<.001)
    assert(#e.expedition_gridheaders==6 and e.bigbag_gridbg.height<440/3)
    for _,w in ipairs({c,n,e})do
        for _,s in ipairs(w.inv)do assert(s.base_scale==1 and s.pos.y==0)end
        for _,s in ipairs(w.equip)do assert(s.base_scale==1 and s.pos.y==0)end
    end
    crafting=true;n:Rebuild();n:OnUpdate(0);assert(n.backpackinv[1]:IsVisible())
    crafting=false;n:OnUpdate(0);crafting=true;n:OnUpdate(0);assert(not n.backpackinv[1]:IsVisible())
    crafting=false;n:OnUpdate(0);assert(n.backpackinv[1]:IsVisible())
end)
test("integrated modern grids remain visible while cooking, including after rebuild and ingredient ticks",function()
    for _,id in ipairs({"roomcar_bigbag_new","roomcar_expeditionbag"})do
        owner.HUD.controls.containers={};crafting=false
        local w=bar(id)
        local pot=opencontainer("portablecookpot",true)
        crafting=true
        for _=1,4 do
            w:OnUpdate(0)
            for _,s in ipairs(w.backpackinv)do assert(s:IsVisible())end
            assert(w.bigbag_gridbg:IsVisible())
            if w.bigbag_bottom_bg then assert(w.bigbag_bottom_bg:IsVisible())end
        end
        w:Rebuild();w:OnUpdate(0)
        for _,s in ipairs(w.backpackinv)do assert(s:IsVisible())end
        crafting=false;owner.HUD.controls.containers[pot].isopen=false;w:OnUpdate(0)
        opencontainer("icebox",false);w:OnUpdate(0)
        assert(not w.backpackinv[1]:IsVisible(),"ordinary containers still auto-hide")
        owner.HUD.controls.containers={};w:OnUpdate(0)
        for _,s in ipairs(w.backpackinv)do assert(s:IsVisible())end
    end
end)

test("real native controller navigation reaches every bag slot in all three compact layouts",function()
    local oldplayer,oldcontroller=ThePlayer,TheInput.ControllerAttached
    ThePlayer={components={playercontroller={CancelDeployPlacement=function()end}}}
    TheInput.ControllerAttached=function()return true end
    owner.HUD.controls.craftingmenu={is_left_aligned=true}
    TheFrontEnd.GetSound=function()return {PlaySound=function()end}end
    local dirs={Vector3(1,0),Vector3(-1,0),Vector3(0,1),Vector3(0,-1)}
    for _,id in ipairs({"bigbag","roomcar_bigbag_new","roomcar_expeditionbag"})do
    local n=bar(id)
    for _,zoom in ipairs({1,2})do
        n.testscale=zoom;require("bigbag_integrated").Refresh(n)
        n.current_list=n.inv;n.active_slot=n.inv[1]
        local reached,queue={[n.active_slot]=true},{{n.active_slot,n.current_list}}
        local at=1
        while queue[at]do
            local state=queue[at];at=at+1
            for _,dir in ipairs(dirs)do
                n.active_slot,n.current_list=state[1],state[2]
                if n:CursorNav(dir,dir.x~=0) and not reached[n.active_slot]then
                    reached[n.active_slot]=true;queue[#queue+1]={n.active_slot,n.current_list}
                end
            end
        end
        for i=1,#n.backpackinv do assert(reached[n.backpackinv[i]],id.." unreachable slot "..i.." at zoom "..zoom)end
    end
    n.testscale=1;require("bigbag_integrated").Refresh(n)
    local rowbounds=id=="roomcar_expeditionbag" and {{1,12},{13,32}} or {{1,20},{21,40},{41,64}}
    for _,bounds in ipairs(rowbounds)do
        for i=bounds[1],bounds[2]-1 do
            n.active_slot=n.backpackinv[i];n.current_list=n.backpackinv;n:CursorRight()
            assert(n.active_slot==n.backpackinv[i+1] and n.current_list==n.backpackinv)
        end
        n.active_slot=n.backpackinv[bounds[2]];n:CursorRight();assert(n.active_slot==n.backpackinv[bounds[2]])
        n.active_slot=n.backpackinv[bounds[1]];n:CursorLeft();assert(n.active_slot==n.backpackinv[bounds[1]])
    end
    if id~="roomcar_expeditionbag" then
    n.active_slot=n.backpackinv[1];n.current_list=n.backpackinv;n:CursorDown();assert(n.active_slot==n.backpackinv[21])
    local index=n:GetCursorSlot();assert(index==21)
    n:CursorDown();assert(n.current_list==n.inv or n.current_list==n.equip)
    n:CursorDown();assert(n.current_list==n.backpackinv and n.active_slot.num>=41)
    end
    end
    ThePlayer,TheInput.ControllerAttached=oldplayer,oldcontroller
end)
test("integrated rows fit at controller/HUD zoom and hidden slots release focus",function()
    local n=bar("roomcar_bigbag_new");n.testscale=2;n:OnUpdate(0)
    assert(n._bigbag_integrated_fit<1)
    for _,i in ipairs({1,20,21,40,41,64})do
        local s=n.backpackinv[i];local p=s:GetWorldPosition();local half=34*s.base_scale*n.testscale
        assert(p.x-half>=12 and p.x+half<=1908)
    end
    n.testscale=1;n:OnUpdate(0);assert(n._bigbag_integrated_fit==.8 and n.backpackinv[64].base_scale==.8)
    n.current_list=n.backpackinv;n.active_slot=n.backpackinv[64]
    crafting=true;n:OnUpdate(0)
    assert(not n.backpackinv[64]:IsVisible() and not n.bigbag_bottom_bg:IsVisible() and n.current_list==n.inv)
    crafting=false;n:OnUpdate(0);assert(n.backpackinv[64]:IsVisible() and n.bigbag_bottom_bg:IsVisible())
end)
test("native nine-slice keeps square corners and edge thickness across tall, wide and thin panels",function()
    local Panel=require("widgets/bigbagpanel")
    local p=Panel()
    for _,scale in ipairs({1,.8,.3})do
        p:SetBorderScale(scale)
        for _,size in ipairs({{560,544},{280,544},{1400,80},{1440,150}})do
            local width,height=size[1]*scale,size[2]*scale
            p:SetSize(width,height)
            local effective=math.min(scale,width/72,height/72)
            local border,padding=56*effective,20*effective
            for _,i in ipairs({1,3,6,8})do
                local w,h=p.patch.elements[i]:GetSize()
                assert(w==border and h==border,"corner was stretched")
            end
            local cw,ch=p.patch:GetSize()
            assert(math.abs(cw+2*border-width-2*padding)<.0001)
            assert(math.abs(ch+2*border-height-2*padding)<.0001)
            assert(p.patch.elements[2].width==cw and p.patch.elements[2].height==border)
            assert(p.patch.elements[4].width==border and p.patch.elements[4].height==ch)
            assert(p.patch.elements[2].pos.y==ch/2 and p.patch.elements[4].pos.x==-cw/2)
        end
    end
end)

test("all compact layouts fit supported screens/zoom without overlapping player slots or scaling them",function()
    local original=TheSim.GetScreenSize
    for _,size in ipairs({{1920,1080},{1366,768},{1136,640},{800,600}})do
        TheSim.GetScreenSize=function()return size[1],size[2]end
        for _,id in ipairs({"bigbag","roomcar_bigbag_new","roomcar_expeditionbag"})do
            local w=bar(id)
            for _,zoom in ipairs({1,2,2.5})do
                w.testscale=zoom;w:OnUpdate(0)
                for _,slot in ipairs(w.backpackinv)do
                    local p=slot:GetWorldPosition()
                    local half=34*slot.base_scale*zoom
                    assert(p.x-half>=12 and p.x+half<=size[1]-12,id.." clipped")
                    assert(p.y+half<=size[2]-12 and p.y-half>=0)
                    local localtop=slot.pos.y+34*slot.base_scale
                    local localbottom=slot.pos.y-34*slot.base_scale
                    assert(localtop<76-34 or localbottom>76+34,"overlaps native inventory")
                end
                for _,slot in ipairs(w.inv)do assert(slot.base_scale==1)end
                for _,slot in ipairs(w.equip)do assert(slot.base_scale==1)end
            end
        end
    end
    TheSim.GetScreenSize=original
end)

test("Expedition section frames follow the 12+20 rows and resized native slots",function()
    local w=bar("roomcar_expeditionbag")
    local data=require("expedition_data")
    for _,zoom in ipairs({1,2,1})do
        w.testscale=zoom;w:OnUpdate(0)
        for index,group in ipairs(data.groups)do
            local frame=w.expedition_gridheaders[index]
            local first,last=w.backpackinv[group.first],w.backpackinv[group.last]
            local half=36*first.base_scale
            assert(first.pos.y==last.pos.y)
            local left=frame.pos.x+frame._expedition_edges[3].pos.x
            local right=frame.pos.x+frame._expedition_edges[4].pos.x
            assert(math.abs(left-(first.pos.x-half))<.001)
            assert(math.abs(right-(last.pos.x+half))<.001)
            assert(frame.pos.y==(index<=2 and w.backpackinv[1].pos.y or 0))
        end
    end
end)

test("classic integrated adaptation does not add automatic folding to classic side/native behaviour",function()
    local w=bar("bigbag")
    crafting=true;opencontainer("icebox",false);w:OnUpdate(0)
    assert(w.backpackinv[64]:IsVisible() and w.bigbag_gridbg:IsVisible())
    crafting=false;owner.HUD.controls.containers={}
    local p=panel("roomcar_bigbag_new")
    local old=p.bgimage
    p:Open(bag("bigbag"),owner)
    assert(old.killed and p.bgimage.patch~=nil and p.bgimage.width==544)
    assert(p.bigbag_toggle==nil)
    p:Close();p:Kill()
end)

test("section borders stay above backplates and below enlarged native slots in side/integrated views",function()
    local ItemSlot=require("widgets/itemslot")
    local function check(parent,frames,slots,backgrounds)
        local function index(child)
            for i,v in ipairs(parent.children)do if v==child then return i end end
            error("missing sibling")
        end
        for _,frame in ipairs(frames)do
            assert(frame.clickable==false)
            for _,line in ipairs(frame._expedition_edges)do assert(line.clickable==false)end
            for _,bg in ipairs(backgrounds)do assert(index(bg)<index(frame),"background hides border")end
            for _,slot in ipairs(slots)do assert(index(frame)<index(slot),"border covers slot")end
        end
        -- Run the native hover/controller highlight implementation. ScaleTo
        -- substitutes only the animation, retaining its real target scale.
        for _,slot in ipairs(slots)do
            local before=index(slot)
            ItemSlot.Highlight(slot)
            assert(slot.scale==slot.highlight_scale and slot.scale>slot.base_scale)
            for _,frame in ipairs(frames)do assert(index(frame)<index(slot))end
            ItemSlot.DeHighlight(slot)
            assert(slot.scale==slot.base_scale and index(slot)==before)
        end
    end
    check(expedition,expedition.expedition_headers,expedition.inv,{expedition.bgimage})
    local w=bar("roomcar_expeditionbag")
    for _,zoom in ipairs({1,2,1})do
        w.testscale=zoom;w:OnUpdate(0)
        check(w.bottomrow,w.expedition_gridheaders,w.backpackinv,{w.bigbag_gridbg,w.bigbag_bottom_bg})
    end
end)

test("section outlines occupy clear gaps outside unscaled native slots",function()
    local data=require("expedition_data")
    local function check(frames,slots)
        for i,g in ipairs(data.groups)do
            local frame=frames[i]
            for _,edge in ipairs(frame._expedition_edges)do
                local x,y=frame.pos.x+edge.pos.x,frame.pos.y+edge.pos.y
                local left,right=x-edge.width/2,x+edge.width/2
                local bottom,top=y-edge.height/2,y+edge.height/2
                for _,slot in ipairs(slots)do
                    local half=34*slot.base_scale
                    assert(right<=slot.pos.x-half+.001 or left>=slot.pos.x+half-.001
                        or top<=slot.pos.y-half+.001 or bottom>=slot.pos.y+half-.001,
                        "a normal slot obscures a section outline")
                end
            end
        end
    end
    check(expedition.expedition_headers,expedition.inv)
    local w=bar("roomcar_expeditionbag")
    for _,zoom in ipairs({1,2,1})do
        w.testscale=zoom;w:OnUpdate(0)
        check(w.expedition_gridheaders,w.backpackinv)
    end
end)

test("close, reset and reopening do not access dead classic/modern widgets",function()
    for _,w in ipairs({classic,new,expedition})do w:Close();assert(not w.isopen and #w.inv==0);w:Kill()end
    d_resetbigbagui();local c=panel("bigbag");assert(c.bgimage:IsVisible() and #c.inv==64);c:Close();c:Kill()
end)
test("invalid old options fall back instead of invalidating UI transforms",function()
    GetModConfigData=function(key) return ({UI_SCALE=0/0,UI_X="bad",UI_Y=math.huge,UI_DRAG_KEY=-1})[key] end
    dofile("_BigBag--DST/modmain.lua")
    local c=TUNING.ROOMCAR_BIGBAG;assert(c.UI_SCALE==.8 and c.UI_X==0 and c.UI_Y==0 and c.UI_DRAG_KEY==1)
end)
test("two free conversion recipes retain original recipes and target existing prefabs",function()
    for _,v in ipairs({{"roomcar_bigbag_to_new","bigbag","roomcar_bigbag_new"},{"roomcar_bigbag_to_classic","roomcar_bigbag_new","bigbag"}})do
        local r=assert(recipes[v[1]])
        assert(#r.ingredients==1 and r.ingredients[1].type==v[2] and r.ingredients[1].amount==1)
        assert(r.tech==TECH.NONE and r.options.product==v[3] and r.options.no_deconstruction)
        assert(recipes[v[3]] and #recipes[v[3]].ingredients>1,"ordinary recipe was replaced")
    end
    local far=recipes.roomcar_expeditionbag
    assert(far.tech==TECH.SCIENCE_TWO and #far.ingredients==3)
    assert(far.ingredients[1].type=="pigskin" and far.ingredients[1].amount==4)
    assert(far.ingredients[2].type=="silk" and far.ingredients[2].amount==8)
    assert(far.ingredients[3].type=="rope" and far.ingredients[3].amount==4)
end)

test("new sorting RPC accepts the holder and rejects closed or unrelated containers",function()
    local util=require("bigbag_util");local old=util.Sort;local calls=0
    util.Sort=function()calls=calls+1 end;GetTime=function()return 100 end
    local player={HasTag=function()return false end}
    local opened=true
    local b={prefab="roomcar_bigbag_new",IsValid=function()return true end,components={container={IsOpenedBy=function()return opened end}}}
    rpcs.sort(player,b);assert(calls==1)
    b._bigbag_lastsort=nil;opened=false;rpcs.sort(player,b);assert(calls==1)
    opened=true;b.prefab="chest";rpcs.sort(player,b);assert(calls==1)
    util.Sort=old
end)

test("colour RPC accepts an owned opened modern bag; rejects classic, other owners and closed bags",function()
    local now=100
    GetTime=function()return now end
    local p={userid="KU_owner",IsValid=function()return true end,HasTag=function()return false end}
    local opened=true
    local b={prefab="roomcar_bigbag_new",IsValid=function()return true end,components={named={},inventoryitem={owner=p},container={IsOpenedBy=function()return opened end}},roomcar_bagcolor={value=function()return 1 end}}
    local calls,index=0,nil
    b.SetBagColor=function(_,n)calls=calls+1;index=n end
    rpcs.color(p,b);assert(calls==1 and index==2)
    rpcs.color(p,b);assert(calls==1,"rate limit")
    now=101;b.prefab="bigbag";rpcs.color(p,b);assert(calls==1)
    b.prefab="roomcar_bigbag_new";opened=false;rpcs.color(p,b);assert(calls==1)
    opened=true;b.components.inventoryitem.owner={};rpcs.color(p,b);assert(calls==1)
    b.components.inventoryitem.owner=p;rpcs.color(p,b);assert(calls==2)
    b.SetBagColor=nil;now=102;rpcs.color(p,b);assert(calls==2)
end)
test("layout preview switches temporarily and restores the original profile function without saving",function()
    local original=function()return false end
    Profile={GetIntegratedBackpack=original,Save=function()error("must not save profile")end}
    local rebuilds=0
    ThePlayer={HUD={RefreshControllers=function()end,controls={inv={Rebuild=function()rebuilds=rebuilds+1 end,Refresh=function()end}}}}
    dofile("tests/bigbag/preview_layout.lua")
    d_bigbag_preview("integrated");assert(Profile:GetIntegratedBackpack())
    d_bigbag_preview("mouse");assert(not Profile:GetIntegratedBackpack())
    d_bigbag_preview("restore");assert(Profile.GetIntegratedBackpack==original and rebuilds==3)
end)
print(passed.." UI version tests passed (real DST ContainerWidget; mocked rendering/input)")
