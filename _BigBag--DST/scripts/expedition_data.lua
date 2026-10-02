-- Shared by the server and client. Classification uses replicated tags/replicas,
-- never server-only components, so slot previews agree with admission checks.
local M = { PREFAB = "roomcar_expeditionbag", NUMSLOTS = 32 }
local function set(list)
    local result = {}
    for word in list:gmatch("%S+") do result[word] = true end
    return result
end
local travel = set("cane orangestaff umbrella grass_umbrella voidcloth_umbrella balloon_speed")
local lights = set("lantern minerhat torch lighter redlantern molehat lantern_flower")
local repair = set("sewing_kit sewing_tape lunarplant_kit voidcloth_kit wagpunkbits_kit")
local medicine = set("healingsalve bandage healingsalve_acid healingsalve_fumarole tillweedsalve spider_healer_item mosquitosack")
local materials = set([[cutgrass twigs log rocks flint goldnugget rope boards cutstone papyrus silk pigskin
    beefalowool houndstooth charcoal ash nitre marble moonrocknugget thulecite thulecite_pieces
    livinglog tentaclespots stinger beeswax waxpaper transistor gears boneshard
    feather_crow feather_robin feather_robin_winter feather_canary cutreeds dug_grass dug_sapling
    dug_berrybush dug_berrybush2 dug_berrybush_juicy pinecone acorn twiggy_nut manrabbit_tail
    slurtleslime slurtle_shellpieces saltrock fossil_piece cookiecuttershell driftwood_log
    messagebottleempty spoiled_food rottenegg poop guano compostwrap compost soil_amender
    purebrilliance dreadstone lunarplant_husk voidcloth wagpunk_bits]])
M.roles = {
    weapon = {zh="武器",en="Weapon",icon="spear.tex",zhhint="战斗武器；工具、灯具和行装有各自的槽位",enhint="Combat weapons; tools, lights and travel gear have separate slots"},
    head = {zh="头部",en="Headwear",icon="footballhat.tex",zhhint="头部装备：防具、季节帽、矿工帽等",enhint="Head armour, seasonal hats and other headwear"},
    body = {zh="身体",en="Bodywear",icon="armorwood.tex",zhhint="身体防具和服装；穿上时仍需遵守原版装备栏规则",enhint="Body armour and clothing; normal equipment-slot rules apply"},
    tool = {zh="工具",en="Tool",icon="axe.tex",zhhint="斧、镐、铲、锤、捕虫网、钓竿等",enhint="Axes, picks, shovels, hammers, nets, fishing rods and other tools"},
    travel = {zh="行装",en="Travel",icon="cane.tex",zhhint="手杖、雨伞、步行法杖等出行用品",enhint="Walking canes, umbrellas and travel gear"},
    light = {zh="照明",en="Light",icon="lantern.tex",zhhint="提灯、矿工帽、火炬、打火机等；燃料另放",enhint="Lanterns, mining hats, torches and lighters; fuel goes below"},
    thermal = {zh="温控",en="Thermal",icon="heatrock.tex",zhhint="暖石等温控用品",enhint="Thermal stones and temperature-control supplies"},
    repair = {zh="修补",en="Repair",icon="sewing_kit.tex",zhhint="针线包、胶带和装备修补套件；不会自动修理",enhint="Sewing kits, tape and equipment repair kits; no automatic repair"},
    food = {zh="食物",en="Food",icon="meatballs.tex",zhhint="各种食物；自行按角色食性选择，正常腐败",enhint="Food for your character's diet; normal spoilage applies"},
    medicine = {zh="药品",en="Medicine",icon="bandage.tex",zhhint="药膏等治疗用品；回血食物放食物槽",enhint="Healing salves and other remedies; healing meals go in food slots"},
    material = {zh="材料",en="Material",icon="twigs.tex",zhhint="基础制作材料；六格互通，可按需要换装",enhint="Crafting materials; all six slots accept the same category"},
    fuel = {zh="燃料",en="Fuel",icon="lightbulb.tex",zhhint="荧光果、噩梦燃料等燃料；不会自动加油",enhint="Light bulbs, nightmare fuel and other fuels; refuel manually"},
    general = {zh="通用",en="General",zhhint="角色道具、额外补给或战利品；不能放入背包",enhint="Character items, extra supplies or loot; no nested backpacks"},
}
M.slots = {}
for _, entry in ipairs({{"weapon",2},{"head",3},{"body",1},{"tool",4},{"travel",2},{"light",2},
    {"thermal",1},{"repair",1},{"food",3},{"medicine",1},{"material",6},{"fuel",2},{"general",4}}) do
    for _ = 1, entry[2] do M.slots[#M.slots+1] = entry[1] end
end
M.groups = {
    {first=1,last=6,x=-142,y=270,cols=3,spacing=66,zh="战斗与换装",en="Combat & clothing"},
    {first=7,last=12,x=142,y=270,cols=3,spacing=66,zh="工具与行装",en="Tools & travel"},
    {first=13,last=16,x=-142,y=75,cols=2,spacing=74,zh="照明与维护",en="Light & maintenance"},
    {first=17,last=20,x=142,y=75,cols=2,spacing=74,zh="食物与急救",en="Food & medicine"},
    {first=21,last=28,x=-142,y=-120,cols=4,spacing=58,zh="材料与燃料",en="Materials & fuel"},
    {first=29,last=32,x=142,y=-120,cols=2,spacing=74,zh="机动侧袋",en="General pockets"},
}
M.colors = {
    {zh="原色",en="Natural",rgb={1,1,1}},
    {zh="青绿",en="Teal",rgb={.55,.9,.8}},
    {zh="赭红",en="Red",rgb={1,.55,.45}},
    {zh="靛蓝",en="Blue",rgb={.55,.7,1}},
    {zh="金黄",en="Gold",rgb={1,.85,.4}},
}
function M.IsBag(inst) return inst ~= nil and (inst.prefab == "bigbag" or inst.prefab == M.PREFAB) end
function M.Label(role, lang) return M.roles[role][lang == 1 and "zh" or "en"] end
function M.Hint(role, lang) return M.roles[role][lang == 1 and "zhhint" or "enhint"] end
local function EquipSlot(item)
    local replica = item.replica and item.replica.equippable
    return replica and replica:EquipSlot()
end
function M.Matches(item, role)
    if item == nil or item:HasTag("backpack") or M.IsBag(item) then return false end
    if role == "general" then return true end
    if item:HasTag("roomcar_expedition_" .. role) then return true end
    local prefab = item.prefab
    local slot = EquipSlot(item)
    if role == "head" then return slot == EQUIPSLOTS.HEAD end
    if role == "body" then return slot == EQUIPSLOTS.BODY end
    if role == "tool" then
        return item:HasTag("tool") or item:HasTag("fishingrod") or item:HasTag("accepts_oceanfishingtackle")
    end
    if role == "travel" then return travel[prefab] == true end
    if role == "light" then return lights[prefab] == true or (slot ~= nil and (item:HasTag("light") or item:HasTag("lighter"))) end
    if role == "weapon" then
        return slot == EQUIPSLOTS.HANDS and (item:HasTag("weapon") or item:HasTag("rangedweapon"))
            and not M.Matches(item,"tool") and not M.Matches(item,"travel") and not M.Matches(item,"light")
    end
    if role == "thermal" then return item:HasTag("heatrock") or prefab == "dumbbell_heat" end
    if role == "repair" then return repair[prefab] == true end
    if role == "medicine" then return medicine[prefab] == true end
    if role == "material" then return materials[prefab] == true end
    if role == "food" then
        for _, kind in pairs(FOODTYPE) do if item:HasTag("edible_"..kind) then return true end end
    elseif role == "fuel" then
        for _, kind in pairs(FUELTYPE) do if item:HasTag(kind.."_fuel") then return true end end
    end
    return false
end
function M.ItemTest(container, item, slot)
    if item == nil or item:HasTag("backpack") or M.IsBag(item) then return false end
    if slot == nil then return true end -- The native container checks carrying restrictions.
    if type(slot) ~= "number" or slot % 1 ~= 0 or M.slots[slot] == nil then return false end
    if container._expedition_loading then return true end
    local replacement = container._expedition_replacements and container._expedition_replacements[slot]
    if replacement ~= nil and replacement == item.prefab then return true end
    return M.Matches(item, M.slots[slot])
end
-- Native GetSpecificSlotForItem chooses the first matching slot even if full.
-- Keep manual slot validation independent from this automatic destination search.
function M.FindSlot(container, item)
    -- Prefer a mining hat's light slot and a light bulb's fuel slot over
    -- generic headwear/food. Ordinary wood still belongs with materials.
    for _, role in ipairs({"light","thermal","repair","medicine","travel","tool",
        "head","body","weapon","material","fuel","food","general"}) do
        local empty
        for slot = 1, M.NUMSLOTS do
            if M.slots[slot] == role and container:CanTakeItemInSlot(item, slot) then
                local existing = container:GetItemInSlot(slot)
                if existing == nil then empty = empty or slot
                else
                    local stack = existing.replica and existing.replica.stackable
                    if stack ~= nil and not stack:IsFull() and stack:CanStackWith(item) then return slot end
                end
            end
        end
        if empty then return empty end
    end
end
function M.MakeWidget(x, y)
    local widget = {slotpos={},bgatlas="images/bigbagbg.xml",bgimage="bigbagbg.tex",pos=Vector3(x,y,0)}
    for _, group in ipairs(M.groups) do
        for slot=group.first,group.last do
            local i=slot-group.first
            widget.slotpos[slot]=Vector3(group.x+(i%group.cols-(group.cols-1)/2)*group.spacing,
                group.y-55-math.floor(i/group.cols)*82,0)
        end
    end
    return widget
end
return M
