local M = {}
-- Multipliers preserve the existing drawing and black outlines.
M.PALETTE = {
    {1,1,1,1}, {.78,.52,1,1}, {.48,.68,1,1}, {.40,1,.94,1},
    {.60,1,.46,1}, {1,.84,.40,1}, {1,.57,.35,1}, {1,.50,.78,1},
}
function M.Get(inst)
    return inst._oracle_colour ~= nil and inst._oracle_colour:value() or 0
end
function M.RGBA(inst) return unpack(M.PALETTE[M.Get(inst)+1] or M.PALETTE[1]) end
function M.Apply(inst) inst.AnimState:SetMultColour(M.RGBA(inst)) end
function M.Prepare(inst)
    inst._oracle_colour=net_smallbyte(inst.GUID,"oracle.colour","oraclecolourdirty")
    inst:ListenForEvent("oraclecolourdirty",M.Apply)
end
function M.Set(inst,index)
    if type(index)~="number" or index~=math.floor(index) or M.PALETTE[index+1]==nil then index=0 end
    inst._oracle_colour:set(index)
    M.Apply(inst)
    if inst.prefab=="spider_god_bone" and inst._godpet~=nil and inst._godpet:IsValid() then
        M.Set(inst._godpet,index)
    end
end
function M.Attach(inst)
    local save,load=inst.OnSave,inst.OnLoad
    inst.OnSave=function(ent,data,...)
        data.oracle_colour=M.Get(ent)
        if save~=nil then return save(ent,data,...)end
    end
    inst.OnLoad=function(ent,data,...)
        if load~=nil then load(ent,data,...)end
        M.Set(ent,data~=nil and data.oracle_colour or 0)
    end
end
function M.HandleClick(player,guard)
    if player==nil or guard==nil or not player:IsValid() or not guard:IsValid()
        or guard.prefab~="spider_god" or player:HasTag("playerghost") or player:HasTag("busy")
        or player.components.health==nil or player.components.health:IsDead()
        or guard.components.health==nil or guard.components.health:IsDead()
        or guard.components.container==nil or not guard.components.container:IsOpenedBy(player)
        or not player:IsNear(guard,4)then return false end
    local f=guard.components.follower
    local staff=f~=nil and f.leader
    if staff==nil or not staff:IsValid() or staff.prefab~="spider_god_bone"
        or staff.components.petleash==nil or not staff.components.petleash:IsPet(guard)then return false end
    if guard._oracle_colour_next~=nil and GetTime()<guard._oracle_colour_next then return false end
    guard._oracle_colour_next=GetTime()+.15
    M.Set(staff,(M.Get(staff)+1)%#M.PALETTE)
    return true
end
function M.AttachTile(tile)
    local item=tile.item
    if item==nil or item.prefab~="spider_god_bone"then return end
    local function Refresh()
        if tile.image~=nil then tile.image:SetTint(M.RGBA(item))end
    end
    tile.inst:ListenForEvent("oraclecolourdirty",Refresh,item)
    Refresh()
end
return M
