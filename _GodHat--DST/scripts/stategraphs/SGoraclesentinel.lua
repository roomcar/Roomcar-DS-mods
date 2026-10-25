require("stategraphs/commonstates")

local events = {
    CommonHandlers.OnLocomote(true, false),
    CommonHandlers.OnDeath(),
    EventHandler("doattack", function(inst, data)
        if not inst.components.health:IsDead() and not inst.sg:HasStateTag("busy") then
            inst.sg:GoToState("attack", data ~= nil and data.target or nil)
        end
    end),
    EventHandler("attacked", function(inst)
        if not inst.components.health:IsDead() and not inst.components.health:IsInvincible() then
            inst.sg:GoToState("hit")
        end
    end),
}

local function BackToIdle(inst)
    if inst.AnimState:AnimDone() then inst.sg:GoToState("idle") end
end

local states = {
    State{
        name="idle", tags={"idle","canrotate"},
        onenter=function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("idle_loop",true)
        end,
    },
    State{
        name="attack", tags={"attack","busy"},
        onenter=function(inst,target)
            inst.components.locomotor:Stop()
            local action=inst:GetBufferedAction()
            target=target or (action~=nil and action.target) or inst.components.combat.target
            inst.sg.statemem.target=target
            inst.components.combat:StartAttack()
            if target~=nil and target:IsValid() then inst:FacePoint(target.Transform:GetWorldPosition()) end
            inst.AnimState:PlayAnimation("atk")
        end,
        timeline={TimeEvent(8*FRAMES,function(inst)
            local target=inst.sg.statemem.target
            if target~=nil and target:IsValid() then
                if inst:GetBufferedAction()~=nil then inst:PerformBufferedAction()
                else inst.components.combat:DoAttack(target) end
            end
        end)},
        events={EventHandler("animover",BackToIdle)},
        onexit=function(inst) inst.components.combat:CancelAttack() end,
    },
    State{
        name="hit",tags={"busy"},
        onenter=function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("hit")
        end,
        events={EventHandler("animover",BackToIdle)},
    },
    State{
        name="death",tags={"busy","dead"},
        onenter=function(inst)
            inst.components.locomotor:Stop()
            inst.Physics:Stop()
            RemovePhysicsColliders(inst)
            inst.AnimState:PlayAnimation("death")
        end,
        events={EventHandler("animover",function(inst)
            if inst.AnimState:AnimDone() then inst:DoTaskInTime(2,inst.Remove) end
        end)},
    },
}
CommonStates.AddRunStates(states)

return StateGraph("oraclesentinel",states,events,"idle",{
    ActionHandler(ACTIONS.ATTACK,"attack"),
})
