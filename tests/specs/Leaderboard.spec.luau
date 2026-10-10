--!strict
local Framework = require("../Framework")
local Leaderboard = require("../../src/shared/Leaderboard")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertTrue = Framework.assertTrue

local function entry(id: number, points: number): Leaderboard.Entry
	return { id = id, name = "P" .. id, points = points, stageId = "compy" }
end

test("Leaderboard: sorts by points, highest first", function()
	local rows = Leaderboard.rank({ entry(1, 10), entry(2, 50), entry(3, 30) }, 5, nil)
	assertEquals(#rows, 3)
	assertEquals(rows[1].id, 2)
	assertEquals(rows[2].id, 3)
	assertEquals(rows[3].id, 1)
	assertEquals(rows[1].rank, 1)
	assertEquals(rows[3].rank, 3)
end)

test("Leaderboard: ties are stable by id", function()
	local rows = Leaderboard.rank({ entry(9, 10), entry(2, 10), entry(5, 10) }, 5, nil)
	assertEquals(rows[1].id, 2)
	assertEquals(rows[2].id, 5)
	assertEquals(rows[3].id, 9)
end)

test("Leaderboard: the list is limited", function()
	local entries = {}
	for id = 1, 10 do
		table.insert(entries, entry(id, id))
	end
	local rows = Leaderboard.rank(entries, 5, nil)
	assertEquals(#rows, 5)
	assertEquals(rows[1].id, 10)
	assertEquals(rows[5].id, 6)
end)

test("Leaderboard: the own row follows with the real rank when outside the top", function()
	local entries = {}
	for id = 1, 10 do
		table.insert(entries, entry(id, id))
	end
	local rows = Leaderboard.rank(entries, 5, 2)
	assertEquals(#rows, 6)
	assertEquals(rows[6].id, 2)
	assertEquals(rows[6].rank, 9)
	assertTrue(rows[6].isOwn)
	assertTrue(not rows[1].isOwn)
end)

test("Leaderboard: the own row is marked inside the top and not repeated", function()
	local entries = { entry(1, 10), entry(2, 50), entry(3, 30) }
	local rows = Leaderboard.rank(entries, 5, 3)
	assertEquals(#rows, 3)
	assertTrue(rows[2].isOwn)
	assertEquals(rows[2].id, 3)
end)

test("Leaderboard: invalid points count as zero", function()
	local rows = Leaderboard.rank({ entry(1, 0 / 0), entry(2, -5), entry(3, 4) }, 5, nil)
	assertEquals(rows[1].id, 3)
	assertEquals(rows[2].points, 0)
	assertEquals(rows[3].points, 0)
end)

test("Leaderboard: empty list and unknown own id", function()
	assertEquals(#Leaderboard.rank({}, 5, 1), 0)
	assertEquals(#Leaderboard.rank({ entry(1, 5) }, 5, 99), 1)
end)

test("Leaderboard: the input is not changed", function()
	local entries = { entry(1, 10), entry(2, 50) }
	Leaderboard.rank(entries, 5, nil)
	assertEquals(entries[1].id, 1)
end)
