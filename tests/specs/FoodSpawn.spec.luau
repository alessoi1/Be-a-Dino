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

local function lcg(seed: number): () -> number
	local state = seed
	return function(): number
		state = (state * 16807) % 2147483647
		return state / 2147483647
	end
end

test("FoodSpawn: pickPositionInDisc stays inside the disc around its center", function()
	local rng = lcg(7)
	for _ = 1, 1000 do
		local x, z = FoodSpawn.pickPositionInDisc(10, -20, 60, rng)
		local dx = x - 10
		local dz = z + 20
		assertTrue(math.sqrt(dx * dx + dz * dz) <= 60 + 1e-9, "inside the radius")
	end
end)

test("FoodSpawn: pickPositionInDisc is even over the area, not piled up in the middle", function()
	local rng = lcg(11)
	local inner = 0
	local total = 4000
	for _ = 1, total do
		local x, z = FoodSpawn.pickPositionInDisc(0, 0, 100, rng)
		if math.sqrt(x * x + z * z) < 50 then
			inner += 1
		end
	end
	-- half the radius is a quarter of the area
	local share = inner / total
	assertTrue(share > 0.2 and share < 0.3, "share " .. share)
end)

test("FoodSpawn: pickPositionInDisc reaches the border with the extreme rolls", function()
	local rolls = { 0, 1 }
	local index = 0
	local function rng(): number
		index += 1
		return rolls[(index - 1) % 2 + 1]
	end
	local x, z = FoodSpawn.pickPositionInDisc(0, 0, 50, rng)
	assertEquals(math.floor(x + 0.5), 50)
	assertEquals(math.floor(z + 0.5), 0)
end)

test("FoodSpawn: pickPositionOutsideDisc keeps out of the disc and inside the arena", function()
	local rng = lcg(5)
	for _ = 1, 1000 do
		local x, z = FoodSpawn.pickPositionOutsideDisc(500, 4, 0, 0, 60, rng, 20)
		assertTrue(math.sqrt(x * x + z * z) > 60, "outside the disc")
		assertTrue(math.abs(x) <= 246 and math.abs(z) <= 246, "inside the arena")
	end
end)

test("FoodSpawn: pickPositionOutsideDisc gives up after the tries and still returns a position", function()
	-- an rng that always picks the center, so every try is inside the disc
	local x, z = FoodSpawn.pickPositionOutsideDisc(500, 4, 0, 0, 60, function()
		return 0.5
	end, 3)
	assertEquals(x, 0)
	assertEquals(z, 0)
end)
