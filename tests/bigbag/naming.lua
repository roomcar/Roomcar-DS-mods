-- Run from repository root with Lua 5.1 and the matching DST scripts directory.
package.path = "_BigBag--DST/scripts/?.lua;" .. assert(arg[1]) .. "/?.lua;" .. package.path
require("class")
local naming = require("bigbag_naming")
local Named = require("components/named")
STRINGS = {NAMES = {BIGBAG = "大背包"}}
TheNet = {GetNetIdForUser = function(_, user) return "author:" .. user end}
local now = 10
GetTime = function() return now end
local passed = 0
local function test(name, fn) fn(); passed = passed + 1; print("PASS " .. name) end
local player = {userid = "test", tags = {}}
function player:IsValid() return true end
function player:HasTag(tag) return self.tags[tag] end
local function bag()
    local b = {prefab = "bigbag", components = {}, replica = {}, opened = true}
    function b:IsValid() return not self.removed end
    b.replica.named = {SetName = function(_, name, author) b.netname, b.author = name, author end}
    b.components.named = Named(b)
    b.components.inventoryitem = {owner = player}
    b.components.container = {IsOpenedBy = function(_, p) return b.opened and p == player end}
    return b
end

test("Chinese, emoji, whitespace and 20-character limit", function()
    assert(naming.Normalize("  矿石包 ⛏  ") == "矿石包 ⛏")
    assert(naming.Normalize("　食物\n备用　") == "食物 备用")
    assert(naming.Normalize(string.rep("包",20)) == string.rep("包",20))
    assert(naming.Normalize(string.rep("包",21)) == nil)
    assert(naming.Normalize("🎒旅行包") == "🎒旅行包")
    assert(naming.Normalize(" \t\n　") == "")
end)
test("malformed input cannot reach the name renderer", function()
    for _, value in ipairs({42, {}, false, "\255", "\192\128", "\237\160\128", "\244\144\128\128", "\226\128", string.rep("x",1000)}) do
        assert(naming.Normalize(value) == nil)
    end
end)
test("independent names and author survive official Named save/load", function()
    local a,b = bag(),bag()
    assert(naming.Rename(player,a,"矿石包"))
    assert(naming.Rename(player,b,"食物包"))
    assert(a.netname == "矿石包" and b.netname == "食物包")
    local saved = a.components.named:OnSave()
    local restored = bag()
    restored.components.named:OnLoad(saved)
    assert(restored.name == "矿石包" and restored.author == "author:test")
    now = now + 1
    assert(naming.Rename(player,a,""))
    assert(a.name == "大背包" and a.netname == "" and a.components.named:OnSave() == nil)
    assert(b.netname == "食物包")
end)
test("server rejects other owners, closed bags, ghosts, stale targets and rapid requests", function()
    local b = bag()
    b.components.inventoryitem.owner = {}
    assert(not naming.Rename(player,b,"bad"))
    b.components.inventoryitem.owner = player
    b.opened = false; assert(not naming.Rename(player,b,"bad")); b.opened = true
    player.tags.playerghost = true; assert(not naming.Rename(player,b,"bad")); player.tags.playerghost = nil
    b.removed = true; assert(not naming.Rename(player,b,"bad")); b.removed = nil
    for _, target in ipairs({false,42,"bag",{}}) do assert(not naming.Rename(player,target,"bad")) end
    assert(naming.Rename(player,b,"ok"))
    assert(not naming.Rename(player,b,"too soon"))
    assert(b.name == "ok")
end)
print(passed .. " naming tests passed")
