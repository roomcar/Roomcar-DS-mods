-- All effects and sounds below are existing Klei resources. No custom media.
local M = {}
local function Live(inst)
    return TheWorld ~= nil and TheWorld.ismastersim and TheSim ~= nil
        and inst ~= nil and inst:IsValid() and not inst._oracle_fx_removing
end
local function Alive(inst)
    return Live(inst) and not inst:HasTag("playerghost")
        and (inst.components.health == nil or not inst.components.health:IsDead())
end
local function Spawn(name, inst, parent, scale)
    if not Live(inst) then return end
    local fx = SpawnPrefab(name)
    if fx == nil then return end
    fx.persists = false
    if parent then
        inst:AddChild(fx)
        fx.Transform:SetPosition(0, 0, 0)
    else
        fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    end
    if scale ~= nil then fx.Transform:SetScale(scale, scale, scale) end
    return fx
end
local function Sound(inst, event, key)
    if not Live(inst) or inst.SoundEmitter == nil then return end
    local now = GetTime()
    if key ~= nil and inst[key] ~= nil and now - inst[key] < .4 then return end
    if key ~= nil then inst[key] = now end
    inst.SoundEmitter:PlaySound(event)
end
function M.Equip(owner, equipped)
    if not Alive(owner) or owner._despawning then return end
    local inventory = owner.components.inventory
    if inventory ~= nil and inventory.isloading then return end
    if owner._oracle_fx_ready == false then return end
    local now = GetTime()
    if owner._oracle_wear_fx_time ~= nil and now - owner._oracle_wear_fx_time < .25 then return end
    owner._oracle_wear_fx_time = now
    Spawn(equipped and "wendy_sanityaura_buff_on_fx" or "wendy_sanityaura_buff_off_fx", owner, true, .8)
    Sound(owner, equipped and "meta5/wendy/sisturn_sanity_buff" or "meta5/wendy/sisturn_sanity_buff_pst")

end
function M.Recruited(target)
    if not Alive(target) then return end
    Spawn("battlesong_attach", target, true, .55)
    local sg = target.sg
    if sg == nil or sg.sg.states.hit == nil or sg.currentstate.name == "hit" then return end
    for _, tag in ipairs({"dead", "sleeping", "frozen", "thawing", "nointerrupt", "flight", "jumping", "sinking", "leaving"}) do
        if sg:HasStateTag(tag) then return end
    end
    if sg:HasStateTag("busy") and not sg:HasStateTag("attack") then return end
    -- An attacked event would damage loyalty or aggro the new owner. Only enter
    -- the creature's native hit animation; do not invent hit states for others.
    if target.components.locomotor ~= nil then target.components.locomotor:Stop() end
    target:ClearBufferedAction()
    sg:GoToState("hit")
end
function M.Released(target)
    if Alive(target) then Spawn("battlesong_detach", target, true, .55) end
end
function M.GuardArrive(guard)
    if Alive(guard) then Spawn("spawn_fx_small", guard, false) end
end
function M.GuardDepart(guard)
    if not Alive(guard) then return end
    Spawn("shadow_teleport_out", guard, false)
    -- This stock puff owns its own sound, so removing the guardian immediately
    -- cannot cut off the audio emitter or leave it attached to a deleted entity.
    Spawn("shadow_puff", guard, false, .55)
end
function M.AttachPlayer(inst)
    if not TheWorld.ismastersim then return end
    inst._oracle_fx_ready = false
    inst:DoTaskInTime(0, function() inst._oracle_fx_ready = true end)
    inst:ListenForEvent("onremove", function() inst._oracle_fx_removing = true end)
end
return M
