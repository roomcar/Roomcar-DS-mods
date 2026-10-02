local G = GLOBAL
local util = G.require("bigbag_util")
local supply = G.require("bigbag_supply")

-- Equipment-slot mods often add BACK. Preserve their existing overflow policy,
-- falling back to our equipped bag only when that policy has no container.
AddComponentPostInit("inventory", function(self)
    local getoverflow = self.GetOverflowContainer
    self.GetOverflowContainer = function(self, ...)
        local container = getoverflow(self, ...)
        if container ~= nil or self.ignoreoverflow then return container end
        local bag = util.GetEquippedBag(self)
        return bag ~= nil and bag.components.container ~= nil and bag.components.container.canbeopened
            and bag.components.container or nil
    end
end)
AddClassPostConstruct("components/inventory_replica", function(self)
    local getoverflow = self.GetOverflowContainer
    self.GetOverflowContainer = function(self, ...)
        local container = getoverflow(self, ...)
        if container ~= nil or (self.classified ~= nil and self.classified.ignoreoverflow) then return container end
        local bag = util.GetEquippedBag(self)
        return bag ~= nil and bag.replica.container ~= nil and bag.replica.container:CanBeOpened()
            and bag.replica.container or nil
    end
end)

if G.TUNING.ROOMCAR_BIGBAG.GIVE then
    -- The crafting UI must permit a click on missing ordinary ingredients.
    -- Health/sanity, tech items, skills and unlock requirements remain vanilla.
    AddClassPostConstruct("components/builder_replica", function(self)
        local hasingredients = self.HasIngredients
        self.HasIngredients = function(self, recipe, ...)
            if hasingredients(self, recipe, ...) then return true end
            recipe = type(recipe) == "string" and G.GetValidRecipe(recipe) or recipe
            return supply.CanSupply(self, recipe, self.inst.replica.inventory)
        end
    end)
    AddComponentPostInit("builder", function(self)
        local make = self.MakeRecipeFromMenu
        self.MakeRecipeFromMenu = function(self, recipe, ...)
            if recipe ~= nil and recipe.placer == nil then supply.Supply(self, recipe) end
            return make(self, recipe, ...)
        end
        local buffer = self.BufferBuild
        self.BufferBuild = function(self, name, ...)
            local recipe = G.GetValidRecipe(name)
            if recipe ~= nil and recipe.placer ~= nil then supply.Supply(self, recipe) end
            return buffer(self, name, ...)
        end
    end)
end
