local M = {}

function M.IsChinese()
    local setting = TUNING.ROOMCAR_GODHAT_LANG
    if setting == 1 then return true end
    if setting == 0 then return false end
    local code = LOC ~= nil and LOC.GetLocaleCode ~= nil and LOC.GetLocaleCode()
        or LanguageTranslator ~= nil and LanguageTranslator.defaultlang or "en"
    return code == "zh" or code == "zhr" or code == "zht" or code == "chs" or code == "cht"
end

function M.Text(zh, en)
    return M.IsChinese() and zh or en
end

function M.Apply()
    local names = {
        GODHAT = M.Text("神谕头环", "Oracle Circlet"),
        SPIDER_GOD_BONE = M.Text("神谕秘法杖", "Oracle Arcane Staff"),
        SPIDER_GOD = M.Text("神谕守卫", "Oracle Sentinel"),
    }
    local descriptions = {
        GODHAT = M.Text("以神谕之眼守护佩戴者。", "The oracle's eye watches over its wearer."),
        SPIDER_GOD_BONE = {
            GENERIC = M.Text("持有它，神谕守卫便会随行。", "Carry it to call an Oracle Sentinel to your side."),
            WAITING = M.Text("神谕之光正在重新凝聚守卫。", "The oracle's light is restoring its sentinel."),
        },
        SPIDER_GOD = M.Text("神谕唤醒的构装守卫，可以为它更换装备。", "An oracle construct ready to wear the equipment you provide."),
    }
    for id, name in pairs(names) do STRINGS.NAMES[id] = name end
    STRINGS.RECIPE_DESC.GODHAT = M.Text("戴上头环，承接神谕的庇护。", "Wear the circlet and receive the oracle's protection.")
    STRINGS.RECIPE_DESC.SPIDER_GOD_BONE = M.Text("召唤并引领神谕守卫。", "Summon and lead an Oracle Sentinel.")
    STRINGS.RECIPE_DESC.SPIDER_GOD = M.Text("可换装、可储物的神谕构装守卫。", "An oracle construct with equipment and storage slots.")
    for _, character in pairs(STRINGS.CHARACTERS) do
        if type(character) == "table" and type(character.DESCRIBE) == "table" then
            for id, description in pairs(descriptions) do character.DESCRIBE[id] = description end
        end
    end
end

return M
