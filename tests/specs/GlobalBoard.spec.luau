--!strict
local Framework = require("../Framework")
local GlobalBoard = require("../../src/shared/GlobalBoard")
local Leaderboards = require("../../src/shared/Config/Leaderboards")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertTrue = Framework.assertTrue

local MAX = 1000000000000000

local data = { kills = 12.9, bestPoints = 5000000000.4, playSeconds = 3600 }

test("GlobalBoard: each list takes its number from the profile, whole", function()
	assertEquals(GlobalBoard.valueFor("kills", data, MAX), 12)
	assertEquals(GlobalBoard.valueFor("size", data, MAX), 5000000000)
	assertEquals(GlobalBoard.valueFor("time", data, MAX), 3600)
end)

test("GlobalBoard: unknown lists and bad numbers give 0", function()
	assertEquals(GlobalBoard.valueFor("other", data, MAX), 0)
	assertEquals(GlobalBoard.valueFor("kills", { kills = -3, bestPoints = 0, playSeconds = 0 }, MAX), 0)
	assertEquals(GlobalBoard.valueFor("kills", { kills = 0 / 0, bestPoints = 0, playSeconds = 0 }, MAX), 0)
	assertEquals(GlobalBoard.valueFor("size", { kills = 0, bestPoints = math.huge, playSeconds = 0 }, MAX), 0)
end)

test("GlobalBoard: a number is cut at the maximum", function()
	assertEquals(GlobalBoard.valueFor("size", { kills = 0, bestPoints = 5e20, playSeconds = 0 }, MAX), MAX)
end)

test("GlobalBoard: the config lists the three boards", function()
	local ids: { [string]: boolean } = {}
	for _, category in Leaderboards.categories do
		ids[category.id] = true
		assertTrue(
			GlobalBoard.valueFor(category.id, { kills = 1, bestPoints = 1, playSeconds = 1 }, MAX) > 0,
			category.id
		)
	end
	assertTrue(ids.kills and ids.size and ids.time)
	assertEquals(#Leaderboards.categories, 3)
end)

test("GlobalBoard: only a new number above 0 is written", function()
	assertTrue(GlobalBoard.shouldWrite(nil, 5))
	assertTrue(GlobalBoard.shouldWrite(5, 6))
	assertTrue(not GlobalBoard.shouldWrite(5, 5), "unchanged")
	assertTrue(not GlobalBoard.shouldWrite(nil, 0), "nothing to write")
	assertTrue(not GlobalBoard.shouldWrite(nil, -1))
	assertTrue(not GlobalBoard.shouldWrite(nil, 0 / 0))
end)

test("GlobalBoard: rows are sorted by value, highest first, with ranks", function()
	local rows = GlobalBoard.rows({
		{ key = "10", value = 5 },
		{ key = "20", value = 50 },
		{ key = "30", value = 20 },
	}, 10)
	assertEquals(#rows, 3)
	assertEquals(rows[1].userId, 20)
	assertEquals(rows[1].rank, 1)
	assertEquals(rows[2].userId, 30)
	assertEquals(rows[3].userId, 10)
	assertEquals(rows[3].rank, 3)
end)

test("GlobalBoard: ties are decided by the smaller user id", function()
	local rows = GlobalBoard.rows({
		{ key = "300", value = 7 },
		{ key = "100", value = 7 },
		{ key = "200", value = 7 },
	}, 10)
	assertEquals(rows[1].userId, 100)
	assertEquals(rows[2].userId, 200)
	assertEquals(rows[3].userId, 300)
end)

test("GlobalBoard: the list is limited", function()
	local raw = {}
	for id = 1, 25 do
		table.insert(raw, { key = tostring(id), value = id })
	end
	local rows = GlobalBoard.rows(raw, 10)
	assertEquals(#rows, 10)
	assertEquals(rows[1].userId, 25)
	assertEquals(rows[10].userId, 16)
end)

test("GlobalBoard: junk entries are dropped", function()
	local rows = GlobalBoard.rows({
		{ key = "abc", value = 5 },
		{ key = "0", value = 5 },
		{ key = "-3", value = 5 },
		{ key = "1.5", value = 5 },
		{ key = "7", value = 0 },
		{ key = "8", value = -2 },
		{ key = "9", value = 0 / 0 },
		{ key = "11", value = 3.9 },
	}, 10)
	assertEquals(#rows, 1)
	assertEquals(rows[1].userId, 11)
	assertEquals(rows[1].value, 3, "whole numbers")
end)

test("GlobalBoard: a user appears once, with the higher value", function()
	local rows = GlobalBoard.rows({
		{ key = "5", value = 10 },
		{ key = "5", value = 30 },
		{ key = "5", value = 20 },
	}, 10)
	assertEquals(#rows, 1)
	assertEquals(rows[1].value, 30)
end)

test("GlobalBoard: an empty list gives no rows", function()
	assertEquals(#GlobalBoard.rows({}, 10), 0)
end)
