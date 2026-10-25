local TAGS = {"scarytoprey", "monster", "hostile", "hound"}
local Recruitment = Class(function(self, inst)
    self.inst = inst
    local old = inst.OnPreLoad
    inst.OnPreLoad = function(ent, data, ...)
        if old ~= nil then old(ent, data, ...) end
        local saved = data ~= nil and data.oracle_recruitment
        if saved ~= nil and ent.components.follower ~= nil then
            -- Follower.OnLoad clamps loyalty using maxfollowtime; set it first.
            ent.components.follower.maxfollowtime = saved.limit
        end
    end
    inst:ListenForEvent("stopfollowing", function()
        local f = inst.components.follower
        if self.state ~= nil and not self.loading
            and (self.owner == nil or f == nil or f.cached_player_leader_userid ~= self.owner) then
            self:Restore()
        end
    end)
    inst:ListenForEvent("death", function() self:Restore() end)
    inst:ListenForEvent("onremove", function() inst._oracle_fx_removing = true end)
end)

function Recruitment:Apply()
    local inst = self.inst
    inst._roomcar_godhat_recruit = self.state
    inst._roomcar_godhat_followtime = self.limit
    inst.components.follower.maxfollowtime = self.limit
    for _, tag in ipairs(TAGS) do inst:RemoveTag(tag) end
    if inst.AnimState ~= nil then inst.AnimState:SetMultColour(1, .8, .2, 1) end
    if inst._roomcar_godhat_peacetask ~= nil then inst._roomcar_godhat_peacetask:Cancel() end
    inst._roomcar_godhat_peacetask = inst:DoPeriodicTask(1, function() self:Tick() end)
end

function Recruitment:Restore()
    local inst, state = self.inst, self.state
    if inst._roomcar_godhat_peacetask ~= nil then
        inst._roomcar_godhat_peacetask:Cancel(); inst._roomcar_godhat_peacetask = nil
    end
    if state == nil then return end
    if not self.loading and not self.silent_restore then require("oracleeffects").Released(inst) end
    self.state = nil
    inst._roomcar_godhat_recruit = nil
    for _, tag in ipairs(TAGS) do if state.tags[tag] then inst:AddTag(tag) end end
    local f = inst.components.follower
    if f ~= nil and f.maxfollowtime == self.limit then f.maxfollowtime = state.maxfollowtime end
    inst._roomcar_godhat_followtime = nil
    if inst.AnimState ~= nil then
        local r,g,b,a = inst.AnimState:GetMultColour()
        if r == nil or (math.abs(r-1)<.001 and math.abs(g-.8)<.001
            and math.abs(b-.2)<.001 and math.abs(a-1)<.001) then
            inst.AnimState:SetMultColour(unpack(state.colour))
        end
    end
end

function Recruitment:Tick()
    if self.state == nil or self.loading then return end
    local inst, f = self.inst, self.inst.components.follower
    if f == nil then self:Restore(); return end
    local leader = f.leader
    if leader ~= nil and leader:IsValid() and
        (self.owner ~= nil and leader.userid == self.owner or self.owner == nil and leader == self.musician) then
        if inst.components.combat ~= nil and inst.components.combat:TargetIs(leader) then
            inst.components.combat:DropTarget()
        end
        return
    end
    -- Player despawn caches the userid before removing the leader. Keep the
    -- effect while that native lease is valid; another player's pet is untouched.
    if leader == nil and self.owner ~= nil and f.cached_player_leader_userid == self.owner
        and f.cached_player_leader_timeleft ~= nil and f.cached_player_leader_timeleft > GetTime() then
        return
    end
    self:Restore()
end

function Recruitment:Recruit(musician, wasenemy)
    local inst, f = self.inst, self.inst.components.follower
    if self.state == nil then
        local r,g,b,a
        if inst.AnimState ~= nil then r,g,b,a = inst.AnimState:GetMultColour() end
        self.state = {tags={}, maxfollowtime=f.maxfollowtime, colour=r ~= nil and {r,g,b,a} or {1,1,1,1}}
        for _, tag in ipairs(TAGS) do self.state.tags[tag] = inst:HasTag(tag) end
        self.limit = f.maxfollowtime ~= nil and not wasenemy and f.maxfollowtime*10 or TUNING.PIG_LOYALTY_MAXTIME*10
    end
    self.owner, self.musician = musician.userid, musician
    self:Apply()
    f:AddLoyaltyTime(self.limit)
    self:Tick()
end

function Recruitment:OnSave()
    if self.state == nil or self.owner == nil then return end
    local f = self.inst.components.follower
    local expiry = f ~= nil and (f.leader ~= nil and f.targettime or f.cached_player_leader_timeleft)
    if expiry == nil or expiry <= GetTime() then return end
    return {add_component_if_missing=true, owner=self.owner, remaining=expiry-GetTime(),
        state=self.state, limit=self.limit}
end

function Recruitment:OnLoad(data)
    if data == nil or data.remaining == nil or data.remaining <= 0 then return end
    self.owner, self.state, self.limit = data.owner, data.state, data.limit
    self.loading = true
    self:Apply()
    self.inst:DoTaskInTime(0, function()
        self.loading = nil
        local f = self.inst.components.follower
        -- The native follower owns the countdown and rejoin listeners. Resolve
        -- players already loaded before this creature (world load order varies).
        if f ~= nil and f.leader == nil and f.cached_player_leader_userid == self.owner then
            for _, player in ipairs(AllPlayers or {}) do
                if player.userid == self.owner then f.cached_player_join_fn(TheWorld, player); break end
            end
        end
        self.silent_restore = true
        self:Tick()
        self.silent_restore = nil
    end)
end

function Recruitment:OnRemoveFromEntity() self:Restore() end
return Recruitment
