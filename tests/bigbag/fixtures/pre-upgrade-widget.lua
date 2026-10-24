-- Extracted verbatim from 2457c55:_BigBag--DST/modmain.lua (1.5.0).
params.bigbag =
{
    widget =
    {
        slotpos = {},
        animbank = nil,
        animbuild = nil,
        bgatlas = "images/bigbagbg.xml",
        bgimage = "bigbagbg.tex",
        pos = Vector3(-200,-60,0),
    },
    issidewidget = true,
    type = "pack",
}

-- 格子设定

for m = 0, 7 do
    local gridsize = 66
    local mis = 3.5*gridsize
    for n = 0, 7 do
        table.insert(params.bigbag.widget.slotpos, Vector3(m*gridsize - mis, n*gridsize - mis, 0))
    end
end

-- 放入时检测设定

function params.bigbag.itemtestfn(container, item, slot)
    if item:HasTag("bigbag") then
        return false
    end
    return true
end

--------------------------------------------------------------------------
--[[ 假装这儿有另一个容器 ]]
--------------------------------------------------------------------------

-- -- here should be code for another container

--------------------------------------------------------------------------

-- 计算所有容器的最大容量（针对mod中的单个容器bigbag用，其实不太鲁棒，建议换成下面的）
-- containers.MAXITEMSLOTS = math.max(containers.MAXITEMSLOTS, params.bigbag.widget.slotpos ~= nil and #params.bigbag.widget.slotpos or 0)

-- 计算所有容器的最大容量（mod中有多个容器时用，抄自 containers.lua）
for k, v in pairs(params) do
    containers.MAXITEMSLOTS = math.max(containers.MAXITEMSLOTS, v.widget.slotpos ~= nil and #v.widget.slotpos or 0)
end

--------------------------------------------------------------------------

-- 此处，containers.lua中还有一句“return containers”，
-- 但MOD不需要这样做吧。

--------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------------------------

print("    BIGBAG    MOD DONE")
