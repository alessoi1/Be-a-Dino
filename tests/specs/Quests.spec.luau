--!strict
local Framework = require("../Framework")
local QuestConfig = require("../../src/shared/Config/Quests")
local Quests = require("../../src/shared/Quests")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertTrue = Framework.assertTrue

local pool: { Quests.Quest } = {
	{ id = "a", kind = "food", target = 10, coins = 5 },
	{ id = "b", kind = "kill", target = 2, coins = 7 },
	{ id = "c", kind = "combo", target = 8, coins = 9 },
	{ id = "d", kind = "play", target = 60, coins = 11 },
}

test("Quests: the same day gives the same quests", function()
	local first = Quests.pick(5, pool, 3)
	local second = Quests.pick(5, pool, 3)
	assertEquals(#first, 3)
	for index, quest in first do
		assertEquals(quest.id, second[index].id)
	end
end)

test("Quests: a day has no repeated quest and the days rotate", function()
	local seen: { [string]: boolean } = {}
	for day = 0, 3 do
		local ids: { [string]: boolean } = {}
		for _, quest in Quests.pick(day, pool, 3) do
			assertTrue(not ids[quest.id], "no repeat on day " .. day)
			ids[quest.id] = true
			seen[quest.id] = true
		end
	end
	assertTrue(seen.a and seen.b and seen.c and seen.d, "every quest comes up")
end)

test("Quests: pick handles an empty pool, a big count and invalid input", function()
	assertEquals(#Quests.pick(1, {}, 3), 0)
	assertEquals(#Quests.pick(1, pool, 10), 4)
	assertEquals(#Quests.pick(0 / 0, pool, 3), 0)
	assertEquals(#Quests.pick(1, pool, 0), 0)
end)

test("Quests: progress adds up, combo keeps the best, and it stops at the target", function()
	local state = Quests.new(1)
	assertTrue(Quests.record(state, pool, "food", 4))
	assertTrue(Quests.record(state, pool, "food", 4))
	assertEquals(state.progress.a, 8)
	assertTrue(Quests.record(state, pool, "food", 100))
	assertEquals(state.progress.a, 10)
	assertTrue(not Quests.record(state, pool, "food", 1), "nothing changes at the target")
	Quests.record(state, pool, "combo", 5)
	Quests.record(state, pool, "combo", 3)
	assertEquals(state.progress.c, 5)
end)

test("Quests: invalid amounts and unknown kinds change nothing", function()
	local state = Quests.new(1)
	assertTrue(not Quests.record(state, pool, "food", -1))
	assertTrue(not Quests.record(state, pool, "food", 0 / 0))
	assertTrue(not Quests.record(state, pool, "swim", 5))
	assertEquals(next(state.progress), nil)
end)

test("Quests: a quest is claimed once and gives its coins", function()
	local state = Quests.new(1)
	assertEquals(Quests.claim(state, pool[2]), 0, "not done yet")
	Quests.record(state, pool, "kill", 2)
	assertTrue(Quests.canClaim(state, pool[2]))
	assertEquals(Quests.claim(state, pool[2]), 7)
	assertEquals(Quests.claim(state, pool[2]), 0, "only once")
	assertTrue(not Quests.record(state, pool, "kill", 1), "a claimed quest no longer counts")
end)

test("Quests: a new day starts with a fresh state", function()
	local state = Quests.new(1)
	Quests.record(state, pool, "food", 3)
	assertEquals(Quests.sync(state, 1), state)
	local fresh = Quests.sync(state, 2)
	assertEquals(fresh.day, 2)
	assertEquals(next(fresh.progress), nil)
	assertEquals(Quests.sync(nil, 4).day, 4)
end)

test("Quests: encode and decode round-trip and skip junk", function()
	local state = Quests.new(1)
	Quests.record(state, pool, "kill", 2)
	Quests.claim(state, pool[2])
	Quests.record(state, pool, "food", 3)
	local views = Quests.decode(Quests.encode(state, { pool[1], pool[2] }))
	assertEquals(#views, 2)
	assertEquals(views[1].id, "a")
	assertEquals(views[1].progress, 3)
	assertEquals(views[1].claimed, false)
	assertEquals(views[2].claimed, true)
	assertEquals(views[2].coins, 7)
	assertEquals(#Quests.decode("junk;a,1,2;;x,1,2,3,9"), 0)
end)

test("Quests: the real pool is valid", function()
	local errors = Quests.validate(QuestConfig.pool, QuestConfig.perDay)
	assertEquals(#errors, 0, table.concat(errors, "; "))
end)

test("Quests: a broken pool is reported", function()
	assertTrue(#Quests.validate({ { id = "a b", kind = "food", target = 1, coins = 1 } }, 1) > 0)
	assertTrue(#Quests.validate({ pool[1], pool[1] }, 1) > 0)
	assertTrue(#Quests.validate({ { id = "a", kind = "swim", target = 1, coins = 1 } }, 1) > 0)
	assertTrue(#Quests.validate({ { id = "a", kind = "food", target = 0, coins = 1 } }, 1) > 0)
	assertTrue(#Quests.validate(pool, 9) > 0)
end)

test("Quests: every quest of the real pool has a name for the player", function()
	local Strings = require("../../src/shared/Strings")
	for _, quest in QuestConfig.pool do
		assertTrue((Strings.quests.names :: any)[quest.id] ~= nil, "missing name for " .. quest.id)
	end
end)
