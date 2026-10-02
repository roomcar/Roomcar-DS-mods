local M = { MAX_LENGTH = 20 }

function M.Normalize(text)
    if type(text) ~= "string" or #text > M.MAX_LENGTH * 4 then return nil end
    -- Lua's locale-dependent %c/%s can classify UTF-8 continuation bytes as
    -- controls in the game runtime. Only replace explicit ASCII control bytes.
    text = text:gsub("[%z\1-\31\127]", " "):gsub("　", " "):match("^ *(.-) *$")
    -- Validate UTF-8 before passing player input to the engine's text renderer.
    local i, count = 1, 0
    while i <= #text do
        local a, b = text:byte(i, i + 1)
        local n = a < 128 and 1 or (a >= 194 and a <= 223 and 2)
            or (a >= 224 and a <= 239 and 3) or (a >= 240 and a <= 244 and 4)
        if not n or i + n - 1 > #text then return nil end
        for j = i + 1, i + n - 1 do
            local c = text:byte(j)
            if c < 128 or c > 191 then return nil end
        end
        if (a == 224 and b < 160) or (a == 237 and b >= 160)
            or (a == 240 and b < 144) or (a == 244 and b >= 144) then return nil end
        count = count + 1
        if count > M.MAX_LENGTH then return nil end
        i = i + n
    end
    return text
end

function M.Rename(player, inst, text)
    if player == nil or not player:IsValid() or player:HasTag("playerghost") or player:HasTag("busy")
        or type(inst) ~= "table" or type(inst.IsValid) ~= "function" or not inst:IsValid() or inst.prefab ~= "bigbag"
        or inst.components.named == nil or inst.components.inventoryitem == nil
        or inst.components.inventoryitem.owner ~= player
        or inst.components.container == nil or not inst.components.container:IsOpenedBy(player) then
        return false
    end
    local name = M.Normalize(text)
    if name == nil then return false end
    local now = GetTime()
    if inst._bigbag_lastrename ~= nil and now - inst._bigbag_lastrename < .5 then return false end
    inst._bigbag_lastrename = now
    inst.components.named:SetName(name ~= "" and name or nil, player.userid)
    return true
end

return M
