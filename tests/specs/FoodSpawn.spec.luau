--!strict
local Framework = require("../Framework")
local FoodSpawn = require("../../src/shared/FoodSpawn")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertTrue = Framework.assertTrue

test("FoodSpawn: missing count fills up to the target, never above", function()
	assertEquals(FoodSpawn.missingCount(290, 0, 300), 10)
	assertEquals(FoodSpawn.missingCount(300, 0, 300), 0)
	assertEquals(FoodSpawn.missingCount(310, 0, 300), 0)
end)

test("FoodSpawn: pending respawns count against the target", function()
	assertEquals(FoodSpawn.missingCount(290, 10, 300), 0)
	assertEquals(FoodSpawn.missingCount(280, 10, 300), 10)
end)

test("FoodSpawn: respawn is due exactly after the wait time", function()
	local queue = { FoodSpawn.schedule(7, 100, 8) }
	local due, remaining = FoodSpawn.takeDue(queue, 107.9)
	assertEquals(#due, 0)
	assertEquals(#remaining, 1)
	local due2, remaining2 = FoodSpawn.takeDue(queue, 108)
	assertEquals(#due2, 1)
	assertEquals(due2[1], 7)
	assertEquals(#remaining2, 0)
end)

test("FoodSpawn: takeDue splits mixed queues", function()
	local queue = { FoodSpawn.schedule(1, 0, 8), FoodSpawn.schedule(2, 5, 8), FoodSpawn.schedule(3, 6, 8) }
	local due, remaining = FoodSpawn.takeDue(queue, 13)
	assertEquals(#due, 2)
	assertEquals(#remaining, 1)
	assertEquals(remaining[1].id, 3)
end)

test("FoodSpawn: positions stay inside the arena", function()
	local seed = 0
	local function rng(): number
		seed = (seed * 37 + 11) % 101
		return seed / 100
	end
	for _ = 1, 500 do
		local x, z = FoodSpawn.pickPosition(400, 4, rng)
		assertTrue(x >= -196 and x <= 196, "x " .. x)
		assertTrue(z >= -196 and z <= 196, "z " .. z)
	end
end)

test("FoodSpawn: rng extremes map to the borders", function()
	local x, z = FoodSpawn.pickPosition(400, 0, function()
		return 0
	end)
	assertEquals(x, -200)
	assertEquals(z, -200)
	local x2 = FoodSpawn.pickPosition(400, 0, function()
		return 1
	end)
	assertEquals(x2, 200)
end)
