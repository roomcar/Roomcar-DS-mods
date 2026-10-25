-- Camera and colour correction belong to the local player, never the server.
local CAMERA_FIELDS = { "zoomstep", "mindist", "maxdist", "mindistpitch", "maxdistpitch", "distancetarget" }
local SOURCE = "roomcar_godhat"

local function PopNightVision(vision)
    vision:PopForcedNightVision(SOURCE)
    -- Native Pop restores the next colour table, but does not always restore
    -- that source's no-CC flag. Keep the newly exposed source's own setting.
    if vision.forcednightvisionstack ~= nil and vision.ForceNoNightVisionCC ~= nil then
        local current = vision.forcednightvisionstack[1]
        vision:ForceNoNightVisionCC(current ~= nil and current.nonightvisioncc == true)
    end
end

local function ReadCameraField(camera, key)
    -- Native FollowCamera adds extramaxdist through its maxdist property setter.
    -- Save/compare the raw limit so restoring it does not add that bonus twice.
    return key == "maxdist" and camera.GetRawMaxDistance ~= nil
        and camera:GetRawMaxDistance() or camera[key]
end

local function UpdateCamera(inst, state)
    local camera = state.camera
    if camera == nil or camera.paused or camera.cutscene or camera.lockdistance
        or (camera.CanControl ~= nil and not camera:CanControl()) then return end

    local cave = TheWorld:HasTag("cave")
    local desired = { zoomstep=6, mindist=10, maxdist=180,
        mindistpitch=cave and 25 or 40, maxdistpitch=cave and 90 or 60 }
    local reset = state.applied == nil
    for key, value in pairs(desired) do
        if ReadCameraField(camera, key) ~= value then reset = true end
    end
    if not reset then return end

    for _, key in ipairs(CAMERA_FIELDS) do
        local current = ReadCameraField(camera, key)
        -- Rejoin/classified/focal-point initialization can call SetDefault on
        -- the SAME camera after activation. Capture those new defaults, never
        -- our own boosted values, then reapply without requiring a hat swap.
        if state.applied == nil or current ~= state.applied[key] then
            state.saved[key] = current
        end
    end
    for key, value in pairs(desired) do camera[key] = value end
    camera.distancetarget = 80
    desired.distancetarget = 80
    state.applied = desired
    -- A changed distance alone is normal scroll-wheel input, not a reset.
end

local function Restore(inst)
    local state = inst._roomcar_godhat_visuals
    if state == nil then return end
    if state.camera ~= nil and state.applied ~= nil then
        for _, key in ipairs(CAMERA_FIELDS) do
            state.camera[key] = state.saved[key]
        end
    end
    if state.nightvision and inst.components.playervision ~= nil then
        PopNightVision(inst.components.playervision)
    end
    inst._roomcar_godhat_visuals = nil
end

local function Update(inst)
    if inst ~= ThePlayer then
        Restore(inst)
        return
    end
    local inventory = inst.replica.inventory
    local hat = inventory ~= nil and inventory:GetEquippedItem(EQUIPSLOTS.HEAD) or nil
    if hat == nil or hat.prefab ~= "godhat" or inst:HasTag("playerghost") then
        Restore(inst)
        return
    end
    -- The physical light is neutral white, independent of the circlet artwork.
    if hat.Light ~= nil then hat.Light:SetColour(1, 1, 1) end
    local state = inst._roomcar_godhat_visuals
    if state ~= nil and state.camera ~= TheCamera then
        Restore(inst)
        state = nil
    end
    if state == nil then
        state = { camera = TheCamera, saved = {} }
        inst._roomcar_godhat_visuals = state
    end
    UpdateCamera(inst, state)
    local night = TheWorld:HasTag("cave") or TheWorld.state.isnight
    local vision = inst.components.playervision
    if vision ~= nil and night ~= (state.nightvision == true) then
        if night then
            -- Native night vision without purple/mole colour correction;
            -- retain the world's normal environment colour table.
            vision:PushForcedNightVision(SOURCE, 0, nil, nil, nil, true)
        else
            PopNightVision(vision)
        end
        state.nightvision = night
    end
    -- Another higher-priority effect can end between our ticks. Native Pop
    -- may reveal our source without restoring its no-CC flag until now.
    if night and vision ~= nil and vision.forcednightvisionstack ~= nil
        and vision.ForceNoNightVisionCC ~= nil then
        local current = vision.forcednightvisionstack[1]
        if current ~= nil and current.source == SOURCE then
            -- A stale custom cube can survive another effect ending even when
            -- the no-nightvision-CC flag is true. Own only our stack entry; do
            -- not touch the world's seasonal/nightmare/environment colour.
            if vision.overridecctable ~= nil and vision.SetCustomCCTable ~= nil then
                vision:SetCustomCCTable(nil)
            end
            if vision.forcednightvisionambienttable ~= nil and vision.SetForcedNightVisionAmbientOverrides ~= nil then
                vision:SetForcedNightVisionAmbientOverrides(nil)
            end
            vision:ForceNoNightVisionCC(true)
        end
    end
end

local function Attach(inst)
    if TheNet:IsDedicated() then return end
    local function Activate()
        if inst ~= ThePlayer then return end
        if inst._roomcar_godhat_visualtask == nil then
            inst._roomcar_godhat_visualtask = inst:DoPeriodicTask(.25, Update)
        end
        Update(inst)
    end
    inst:ListenForEvent("playeractivated", Activate)
    inst:ListenForEvent("playerdeactivated", function()
        if inst._roomcar_godhat_visualtask ~= nil then
            inst._roomcar_godhat_visualtask:Cancel()
            inst._roomcar_godhat_visualtask = nil
        end
        Restore(inst)
    end)
    inst:ListenForEvent("onremove", Restore)
    inst:DoTaskInTime(0, Activate)
end

return { Attach = Attach, Update = Update, Restore = Restore }
