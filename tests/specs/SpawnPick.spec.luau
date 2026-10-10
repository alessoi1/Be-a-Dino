--!strict
local Framework = require("../Framework")
local SpawnPick = require("../../src/shared/SpawnPick")

local test = Framework.test
local assertEquals = Framework.assertEquals

test("SpawnPick: picks the candidate farthest from the nearest player", function()
	local candidates = { { x = 0, z = 0 }, { x = 50, z = 0 }, { x = 100, z = 0 } }
	local others = { { x = 5, z = 0 }, { x = 95, z = 0 } }
	local best = SpawnPick.best(candidates, others)
	assertEquals(best and best.x, 50)
end)

test("SpawnPick: the nearest player counts, not the average", function()
	local candidates = { { x = 0, z = 0 }, { x = 100, z = 0 } }
	-- candidate 1 is 10 away from one player, candidate 2 is 40 away from the nearest
	local others = { { x = 10, z = 0 }, { x = 140, z = 0 } }
	local best = SpawnPick.best(candidates, others)
	assertEquals(best and best.x, 100)
end)

test("SpawnPick: without other players the first candidate is used", function()
	local best = SpawnPick.best({ { x = 7, z = 8 }, { x = 1, z = 1 } }, {})
	assertEquals(best and best.x, 7)
end)

test("SpawnPick: ties go to the earlier candidate", function()
	local best = SpawnPick.best({ { x = -10, z = 0 }, { x = 10, z = 0 } }, { { x = 0, z = 0 } })
	assertEquals(best and best.x, -10)
end)

test("SpawnPick: no candidates gives nil", function()
	assertEquals(SpawnPick.best({}, { { x = 0, z = 0 } }), nil)
end)
