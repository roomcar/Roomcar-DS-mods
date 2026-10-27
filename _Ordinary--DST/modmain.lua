PrefabFiles = {"ordinary_hats"}

local defs = require("ordinary_definitions")
local Ingredient = GLOBAL.Ingredient
local STRINGS = GLOBAL.STRINGS
local code = GLOBAL.LOC ~= nil and GLOBAL.LOC.GetLocaleCode ~= nil and GLOBAL.LOC.GetLocaleCode()
    or GLOBAL.LanguageTranslator ~= nil and GLOBAL.LanguageTranslator.defaultlang or "en"
local chinese = code == "zh" or code == "zhr" or code == "zht" or code == "chs" or code == "cht"
local atlas = "images/inventoryimages/ordinary_hats.xml"

Assets = {Asset("ATLAS", atlas), Asset("IMAGE", "images/inventoryimages/ordinary_hats.tex")}

for _, def in ipairs(defs) do
    local key = string.upper(def.name)
    STRINGS.NAMES[key] = chinese and def.zh or def.en
    STRINGS.RECIPE_DESC[key] = chinese and def.recipe_zh or def.recipe_en
    for _, character in pairs(STRINGS.CHARACTERS) do
        if type(character) == "table" and type(character.DESCRIBE) == "table" then
            character.DESCRIBE[key] = chinese and def.describe_zh or def.describe_en
        end
    end

    local ingredients = {}
    for _, ingredient in ipairs(def.ingredients) do
        ingredients[#ingredients + 1] = Ingredient(ingredient[1], ingredient[2])
    end
    AddRecipe2(def.name, ingredients, GLOBAL.TECH.NONE, {
        atlas = atlas, image = def.name .. ".tex",
    }, {"CLOTHING"})
end
