--!strict
local EatRules = require("../../src/shared/EatRules")
local Framework = require("../Framework")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertTrue = Framework.assertTrue

local config: EatRules.Config = { eatReachFactor = 2 }

local function eater(): EatRules.Combatant
	return { id = 1, scale = 3, points = 300, protectedUntil = 0 }
end

local function victim(): EatRules.Combatant
	return { id = 2, scale = 1, points = 100, protectedUntil = 0 }
end

test("EatRules: a player with more points in range may eat", function()
	local ok, reason = EatRules.canEat(config, eater(), victim(), 2, 100)
	assertTrue(ok)
	assertEquals(reason, nil)
end)

test("EatRules: one point more is enough, equal or fewer points are not", function()
	local e = eater()
	e.points = 101
	assertTrue(EatRules.canEat(config, e, victim(), 1, 100), "101 against 100")
	e.points = 100
	local ok, reason = EatRules.canEat(config, e, victim(), 1, 100)
	assertTrue(not ok, "equal points")
	assertEquals(reason, "fewer_points")
	e.points = 99
	local ok2, reason2 = EatRules.canEat(config, e, victim(), 1, 100)
	assertTrue(not ok2, "fewer points")
	assertEquals(reason2, "fewer_points")
end)

test("EatRules: only the points count, not the size or the dino", function()
	-- A smaller dino with more points eats a bigger one with fewer points.
	local small: EatRules.Combatant = { id = 1, scale = 1, points = 500, protectedUntil = 0 }
	local big: EatRules.Combatant = { id = 2, scale = 4, points = 400, protectedUntil = 0 }
	assertTrue(EatRules.canEat(config, small, big, 2, 100), "small with more points eats")
	local ok, reason = EatRules.canEat(config, big, small, 2, 100)
	assertTrue(not ok, "big with fewer points does not")
	assertEquals(reason, "fewer_points")
end)

test("EatRules: the reach grows with both sizes, so touching bodies are in range", function()
	local ok = EatRules.canEat(config, eater(), victim(), 8, 100)
	assertTrue(ok, "(3 + 1) * 2 = 8 is in range")
	local ok2, reason = EatRules.canEat(config, eater(), victim(), 8.1, 100)
	assertTrue(not ok2)
	assertEquals(reason, "too_far")
	-- A bigger victim is reached from farther away: a long body touches earlier.
	local big = victim()
	big.scale = 2
	local ok3 = EatRules.canEat(config, eater(), big, 9.9, 100)
	assertTrue(ok3, "(3 + 2) * 2 = 10")
end)

test("EatRules: running into a dino with fewer points from a body length away is enough", function()
	-- The log of a real test: scales 1.24 and 1.03, middles 5 studs apart (bodies about 9 long).
	local real: EatRules.Config = { eatReachFactor = 2.2 }
	local ok = EatRules.canEat(
		real,
		{ id = 1, scale = 1.24, points = 5700, protectedUntil = 0 },
		{ id = 2, scale = 1.03, points = 800, protectedUntil = 0 },
		4.9,
		100
	)
	assertTrue(ok)
end)

test("EatRules: protected victim cannot be eaten until protection ends", function()
	local v = victim()
	v.protectedUntil = 104
	local ok, reason = EatRules.canEat(config, eater(), v, 1, 103.9)
	assertTrue(not ok)
	assertEquals(reason, "protected")
	local ok2 = EatRules.canEat(config, eater(), v, 1, 104)
	assertTrue(ok2, "protection over at protectedUntil")
end)

test("EatRules: nobody eats themselves", function()
	local e = eater()
	local ok, reason = EatRules.canEat(config, e, e, 0, 100)
	assertTrue(not ok)
	assertEquals(reason, "self")
end)

test("EatRules: invalid numbers are rejected", function()
	for _, distance in { -1, 0 / 0, math.huge } do
		local ok, reason = EatRules.canEat(config, eater(), victim(), distance, 100)
		assertTrue(not ok, "distance " .. tostring(distance))
		assertEquals(reason, "invalid")
	end
	for _, points in { 0 / 0, math.huge } do
		local e = eater()
		e.points = points
		local ok, reason = EatRules.canEat(config, e, victim(), 1, 100)
		assertTrue(not ok, "points " .. tostring(points))
		assertEquals(reason, "invalid")
	end
end)

test("EatRules: eater gets a share of the victim points, rounded down", function()
	assertEquals(EatRules.pointsGained(0.5, 100), 50)
	assertEquals(EatRules.pointsGained(0.5, 51), 25)
	assertEquals(EatRules.pointsGained(0.5, 0), 0)
	assertEquals(EatRules.pointsGained(0.5, -10), 0)
end)

local function player(id: number, x: number, points: number, scale: number?): EatRules.Player
	return { id = id, x = x, z = 0, scale = scale or 2, points = points, protectedUntil = 0, alive = true }
end

test("EatRules.findEats: a player with more points in range eats the other one", function()
	local eats = EatRules.findEats(config, { player(1, 0, 300), player(2, 2, 100) }, 100)
	assertEquals(#eats, 1)
	assertEquals(eats[1].eaterId, 1)
	assertEquals(eats[1].victimId, 2)
	assertEquals(eats[1].distance, 2)
end)

test("EatRules.findEats: equal points never eat each other, whatever the size", function()
	assertEquals(#EatRules.findEats(config, { player(1, 0, 300, 3), player(2, 0.5, 300, 1) }, 100), 0)
end)

test("EatRules.findEats: out of range, protected or dead players are skipped", function()
	assertEquals(#EatRules.findEats(config, { player(1, 0, 300), player(2, 50, 100) }, 100), 0, "too far")
	local protected = player(2, 1, 100)
	protected.protectedUntil = 200
	assertEquals(#EatRules.findEats(config, { player(1, 0, 300), protected }, 100), 0, "protected")
	local dead = player(2, 1, 100)
	dead.alive = false
	assertEquals(#EatRules.findEats(config, { player(1, 0, 300), dead }, 100), 0, "dead victim")
	local deadEater = player(1, 0, 300)
	deadEater.alive = false
	assertEquals(#EatRules.findEats(config, { deadEater, player(2, 1, 100) }, 100), 0, "dead eater")
end)

test("EatRules.findEats: the most points eat first, an eaten player eats nobody", function()
	local eats = EatRules.findEats(config, { player(1, 0, 300), player(3, 0.5, 500), player(2, 1, 100) }, 100)
	-- player 3 (500 points) eats first and takes player 1 and player 2,
	-- so player 1 (300 points) no longer eats player 2.
	local byVictim: { [number]: number } = {}
	for _, eat in eats do
		byVictim[eat.victimId] = eat.eaterId
	end
	assertEquals(byVictim[1], 3)
	assertEquals(byVictim[2], 3)
	assertEquals(#eats, 2)
end)

test("EatRules.findEats: with equal points nobody is eaten, a third player with fewer points is", function()
	local eats = EatRules.findEats(config, { player(1, 0, 300), player(2, 0.2, 300), player(3, 1, 100) }, 100)
	-- Player 1 (lower id) acts first and eats player 3; player 2 finds nobody left to eat.
	assertEquals(#eats, 1)
	assertEquals(eats[1].eaterId, 1)
	assertEquals(eats[1].victimId, 3)
end)

test("EatRules.findEats: every victim is eaten at most once", function()
	local eats = EatRules.findEats(config, { player(1, 0, 300), player(2, 0.2, 300), player(3, 1, 100) }, 100)
	local seen: { [number]: boolean } = {}
	for _, eat in eats do
		assertTrue(not seen[eat.victimId], "victim " .. eat.victimId .. " once")
		seen[eat.victimId] = true
	end
end)

test("EatRules.findEats: one eater may eat several victims, nearest first", function()
	local eats = EatRules.findEats(config, { player(1, 0, 500), player(2, 3, 100), player(3, 1, 100) }, 100)
	assertEquals(#eats, 2)
	assertEquals(eats[1].victimId, 3)
	assertEquals(eats[2].victimId, 2)
end)

test("EatRules.findEats: ties are decided by id, so the result is stable", function()
	local players = { player(5, 0, 500), player(2, 1, 100), player(3, -1, 100) }
	local eats = EatRules.findEats(config, players, 100)
	assertEquals(eats[1].victimId, 2)
	assertEquals(eats[2].victimId, 3)
end)

test("EatRules.findEats: nobody eats themselves and invalid positions are ignored", function()
	assertEquals(#EatRules.findEats(config, { player(1, 0, 300) }, 100), 0)
	assertEquals(#EatRules.findEats(config, { player(1, 0, 300), player(2, 0 / 0, 100) }, 100), 0)
end)
