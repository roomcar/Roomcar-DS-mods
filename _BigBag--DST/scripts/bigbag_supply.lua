local util = require("bigbag_util")
local M = {}

function M.SpecialCostsAvailable(builder, recipe)
    if recipe == nil or recipe.is_deconstruction_recipe then return false end
    if recipe.getlimitedrecipecount ~= nil and recipe:getlimitedrecipecount(builder.inst) <= 0 then return false end
    for _, cost in ipairs(recipe.character_ingredients or {}) do
        if not builder:HasCharacterIngredient(cost) then return false end
    end
    for _, cost in ipairs(recipe.tech_ingredients or {}) do
        if not builder:HasTechIngredient(cost) then return false end
    end
    return true
end

function M.CanSupply(builder, recipe, inventory)
    return TUNING.ROOMCAR_BIGBAG.GIVE
        and util.GetEquippedBag(inventory) ~= nil
        and not builder.inst:HasTag("playerghost")
        and M.SpecialCostsAvailable(builder, recipe)
end

function M.Supply(builder, recipe)
    local inventory = builder.inst.components.inventory
    if not M.CanSupply(builder, recipe, inventory) or not inventory:IsOpenedBy(builder.inst)
        or builder.inst:HasTag("busy")
        or builder:IsBuildBuffered(recipe.name)
        or not (builder:KnowsRecipe(recipe) or
            (builder:CanLearn(recipe.name) and CanPrototypeRecipe(recipe.level, builder.accessible_tech_trees))) then
        return
    end
    local now = GetTime()
    if builder._bigbag_supplytime ~= nil and now - builder._bigbag_supplytime < .25 then return end
    builder._bigbag_supplytime = now
    for _, ingredient in ipairs(recipe.ingredients) do
        local amount = math.max(1, RoundBiasedUp(ingredient.amount * builder.ingredientmod))
        local has, count = inventory:Has(ingredient.type, amount, true)
        -- Only the deficit is generated; existing stacks are never overwritten.
        local missing = not has and amount - (count or 0) or 0
        if missing > 0 and missing < math.huge then
            while missing > 0 do
                local item = SpawnPrefab(ingredient.type)
                if item == nil then break end
                if item.components.inventoryitem == nil then item:Remove() break end
                local stack = item.components.stackable
                local limit = stack ~= nil and (stack.originalmaxsize or stack.maxsize) or 1
                if type(limit) ~= "number" or limit ~= limit or limit == math.huge or limit < 1 then limit = 1 end
                local give = math.min(missing, math.floor(limit))
                if stack ~= nil then stack:SetStackSize(give) end
                inventory:GiveItem(item, nil, builder.inst:GetPosition())
                missing = missing - give
            end
        end
    end
end

return M
