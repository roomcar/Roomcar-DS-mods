local M = {}
local NAME = "roomcar_oracle_resonate"
local SOUND = "dontstarve/wilson/flute_LP"
local function Circlet(action)
    return action ~= nil and action.invobject ~= nil and action.invobject.prefab == "godhat"
end
local function Riding(inst)
    local rider = inst.components.rider or (inst.replica ~= nil and inst.replica.rider) or nil
    return rider ~= nil and rider:IsRiding()
end
local function StartPose(inst)
    inst.components.locomotor:Stop()
    inst.AnimState:Hide("ARM_carry")
    inst.AnimState:Show("ARM_normal")
    inst.AnimState:Hide("swap_object")
    inst.AnimState:PlayAnimation("channelcast_oh_idle_pre")
    inst.AnimState:PushAnimation("channelcast_oh_idle", true)
end
local function RestorePose(inst)
    inst.AnimState:Show("swap_object")
    local inv = inst.components.inventory or (inst.replica ~= nil and inst.replica.inventory)
    local item = inv ~= nil and inv:GetEquippedItem(EQUIPSLOTS.HANDS) or nil
    inst.AnimState:Show(item ~= nil and "ARM_carry" or "ARM_normal")
    inst.AnimState:Hide(item ~= nil and "ARM_normal" or "ARM_carry")
end
local function Finish(inst)
    inst.SoundEmitter:KillSound("roomcar_oracle_resonate")
    inst.AnimState:PlayAnimation("channelcast_oh_idle_pst")
    inst.sg.statemem.finishing = true
end
function M.ServerState()
    return State{
        name = NAME,
        tags = {"doing", "busy", "playing"},
        onenter = function(inst)
            local action = inst:GetBufferedAction()
            if not Circlet(action) then inst.sg:GoToState("idle"); return end
            inst.sg.statemem.instrument = action.invobject
            StartPose(inst)
            inst.components.inventory:ReturnActiveActionItem(action.invobject)
            inst.sg:SetTimeout(4)
        end,
        timeline = {
            -- Preserve the native pan flute's effect/busy/audio timings.
            TimeEvent(30*FRAMES, function(inst)
                if inst:PerformBufferedAction() then
                    inst.SoundEmitter:PlaySound(SOUND, "roomcar_oracle_resonate")
                else
                    inst.sg:RemoveStateTag("busy")
                    Finish(inst)
                end
            end),
            TimeEvent(52*FRAMES, function(inst) inst.sg:RemoveStateTag("busy") end),
            TimeEvent(85*FRAMES, function(inst) inst.SoundEmitter:KillSound("roomcar_oracle_resonate") end),
            TimeEvent(100*FRAMES, Finish),
        },
        onupdate = function(inst)
            local item = inst.sg.statemem.instrument
            if item == nil or not item:IsValid() or item.components.inventoryitem == nil
                or item.components.inventoryitem:GetGrandOwner() ~= inst then inst.sg:GoToState("idle") end
        end,
        ontimeout = function(inst) inst.sg:GoToState("idle") end,
        events = {EventHandler("animover", function(inst)
            if inst.sg.statemem.finishing and inst.AnimState:AnimDone() then inst.sg:GoToState("idle") end
        end)},
        onexit = function(inst)
            inst.SoundEmitter:KillSound("roomcar_oracle_resonate")
            RestorePose(inst)
        end,
    }
end
function M.ClientState()
    return State{
        name = NAME, server_states = {NAME}, forward_server_states = true,
        tags = {"doing", "busy", "playing"},
        onenter = function(inst)
            StartPose(inst)
            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(2)
        end,
        onupdate = function(inst)
            if inst.sg:ServerStateMatches() then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg.statemem.matched = true
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then inst.sg:GoToState("idle") end
        end,
        ontimeout = function(inst) inst:ClearBufferedAction(); inst.sg:GoToState("idle") end,
        onexit = function(inst)
            if not inst.sg.statemem.matched then RestorePose(inst) end
        end,
    }
end
function M.Patch(sg, client)
    local handler = sg.actionhandlers[ACTIONS.PLAY]
    if handler == nil then return end
    local previous = handler.deststate
    handler.deststate = function(inst, action)
        if Circlet(action) and not Riding(inst) then return NAME end
        return previous(inst, action)
    end
    sg.states[NAME] = client and M.ClientState() or M.ServerState()
end
function M.Install(postinit)
    postinit("wilson", function(sg) M.Patch(sg, false) end)
    postinit("wilson_client", function(sg) M.Patch(sg, true) end)
end
M.NAME = NAME
return M
