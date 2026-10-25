-- Follow the actual save graph (including other staff/guardian pairs), so open
-- chains are supported while adding an item can never create a save cycle.
local M = {}
function M.FindGuardian(inst)
    local seen={}
    while inst ~= nil and not seen[inst] do
        seen[inst]=true
        if inst.prefab=="spider_god" then return inst end
        local item=inst.components~=nil and inst.components.inventoryitem
        inst=item~=nil and item.owner or nil
    end
end
function M.RootHolder(inst)
    local seen={}
    while inst ~= nil and not seen[inst] do
        seen[inst]=true
        local c=inst.components
        local nextowner=c~=nil and c.inventoryitem~=nil and c.inventoryitem.owner or nil
        if nextowner==nil and inst.prefab=="spider_god" then
            nextowner=c.follower~=nil and c.follower.leader
        end
        if not nextowner then return inst end
        inst=nextowner
    end
end
local function Walk(node, seen, visit)
    if node==nil or seen[node] then return false end
    seen[node]=true
    if visit(node) then return true end
    local c=node.components or {}
    for _,name in ipairs({"container","inventory"})do
        local holder=c[name]
        if holder~=nil then
            for _,field in ipairs({"slots","itemslots","equipslots"})do
                for _,child in pairs(holder[field]or{})do
                    if Walk(child,seen,visit)then return true end
                end
            end
            if Walk(holder.activeitem,seen,visit)then return true end
        end
    end
    if node.prefab=="spider_god_bone" then
        if c.petleash~=nil then
            for pet in pairs(c.petleash:GetPets())do if Walk(pet,seen,visit)then return true end end
        end
        -- Pre-petleash legacy followers also participate before adoption.
        if c.leader~=nil then
            for pet in pairs(c.leader.followers)do if pet.prefab=="spider_god" and Walk(pet,seen,visit)then return true end end
        end
    end
    return false
end
function M.ContainsStaff(item)
    return Walk(item,{},function(node)return node.prefab=="spider_god_bone"end)
end
function M.WouldCycle(guard,item)
    if guard==nil then return false end
    local f=guard.components.follower
    local paired=f~=nil and f.leader
    return Walk(item,{},function(node)return node==guard or node==paired end)
end
local GroundNear
local function PlaceOnGround(item,guard)
    local pt=GroundNear(guard)
    if item.Physics~=nil then item.Physics:Teleport(pt:Get());item.Physics:Stop()
    else item.Transform:SetPosition(pt:Get())end
end
function M.WrapContainer(container)
    local old=container.CanTakeItemInSlot
    container.CanTakeItemInSlot=function(self,item,slot,...)
        if M.WouldCycle(M.FindGuardian(self.inst),item)then return false end
        return old(self,item,slot,...)
    end
    local load,give=container.OnLoad,container.GiveItem
    container.OnLoad=function(self,...)
        self._oracle_loading=true
        load(self,...)
        self._oracle_loading=nil
    end
    container.GiveItem=function(self,item,...)
        local result=give(self,item,...)
        local guard=M.FindGuardian(self.inst)
        -- Native loading may reject an old paired staff before it ever enters
        -- a slot. Reposition that dropped item as well as items adopted later.
        if self._oracle_loading and not result and item~=nil and item:IsValid()
            and item.prefab=="spider_god_bone" and M.WouldCycle(guard,item)then
            PlaceOnGround(item,guard)
        end
        return result
    end
end
GroundNear=function(guard)
    local pt=guard:GetPosition()
    for _,radius in ipairs({1,2,4,8,16,32,64,128})do
        local offset=FindWalkableOffset(pt,math.random()*2*PI,radius,24,true,true,function(p)
            return not TheWorld.Map:IsOceanAtPoint(p:Get()) and not TheWorld.Map:IsPointNearHole(p)
        end)
        if offset~=nil then return pt+offset end
    end
    return pt
end
function M.EjectLegacyStaff(guard)
    local seen={}
    local function Eject(holder)
        if holder==nil or seen[holder]then return end
        seen[holder]=true
        local snapshot={}
        for _,field in ipairs({"slots","itemslots","equipslots"})do
            for _,item in pairs(holder[field]or{})do snapshot[#snapshot+1]=item end
        end
        for _,item in ipairs(snapshot)do
            if item.prefab=="spider_god_bone" then
                if M.WouldCycle(guard,item)then
                    holder:DropItem(item,true,true)
                    PlaceOnGround(item,guard)
                end
            elseif item.components~=nil then
                Eject(item.components.container);Eject(item.components.inventory)
            end
        end
    end
    Eject(guard.components.container);Eject(guard.components.inventory)
end
function M.RegisterMigrationPets(player)
    if player.migrationpets==nil then return end
    local seen={}
    for _,pet in ipairs(player.migrationpets)do seen[pet]=true end
    Walk(player,{},function(node)
        if node.prefab=="spider_god" and not seen[node]then
            seen[node]=true;table.insert(player.migrationpets,node)
        end
        return false
    end)
end
return M
