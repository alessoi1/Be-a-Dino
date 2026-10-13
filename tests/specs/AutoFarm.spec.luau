--!strict
local AutoFarm = require("../../src/shared/AutoFarm")
local AutoFarmConfig = require("../../src/shared/Config/AutoFarm")
local Arena = require("../../src/shared/Config/Arena")
local Framework = require("../Framework")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertNear = Framework.assertNear
local assertTrue = Framework.assertTrue

local config: AutoFarm.Config = {
	dangerMargin = 25,
	fleeDistance = 40,
	valueBias = 10,
	arenaMargin = 6,
}
local rules: AutoFarm.Rules = { eatRatio = 1.2, eatReachFactor = 2 }
-- The radius of the round arena.
local ARENA = 300

local me: AutoFarm.Me = { x = 0, z = 0, scale = 1 }

local function food(x: number, z: number, value: number): AutoFarm.Food
	return { x = x, z = z, value = value }
end

test("AutoFarm: walks to the nearest piece of the same value", function()
	local target = AutoFarm.pickTarget(
		config,
		rules,
		me,
		{ food(50, 0, 1), food(10, 0, 1), food(-30, 0, 1) },
		{},
		ARENA
	)
	assertEquals(target.kind, "food")
	assertEquals(target.x, 10)
	assertEquals(target.z, 0)
end)

test("AutoFarm: a big piece is worth a detour", function()
	-- value / (distance + 10): the small piece at 10 scores 1/20, the big one at 60 scores 10/70
	local target = AutoFarm.pickTarget(config, rules, me, { food(10, 0, 1), food(60, 0, 10) }, {}, ARENA)
	assertEquals(target.x, 60)
end)

test("AutoFarm: without food or with only invalid food it stays", function()
	local target = AutoFarm.pickTarget(config, rules, me, {}, {}, ARENA)
	assertEquals(target.kind, "idle")
	assertEquals(target.x, 0)
	local broken = AutoFarm.pickTarget(
		config,
		rules,
		me,
		{ food(0 / 0, 0, 1), food(5, 5, 0), food(5, 5, -3) },
		{},
		ARENA
	)
	assertEquals(broken.kind, "idle")
end)

test("AutoFarm: ties are decided the same way every time", function()
	local first = AutoFarm.pickTarget(config, rules, me, { food(10, 0, 1), food(-10, 0, 1) }, {}, ARENA)
	local second = AutoFarm.pickTarget(config, rules, me, { food(-10, 0, 1), food(10, 0, 1) }, {}, ARENA)
	assertEquals(first.x, second.x)
	assertEquals(first.x, -10, "the smaller x wins")
end)

test("AutoFarm: smaller or equal players are no danger", function()
	local others: { AutoFarm.Other } =
		{ { x = 5, z = 0, scale = 1 }, { x = 6, z = 0, scale = 0.5 }, { x = 7, z = 0, scale = 1.19 } }
	local target = AutoFarm.pickTarget(config, rules, me, { food(10, 0, 1) }, others, ARENA)
	assertEquals(target.kind, "food")
end)

test("AutoFarm: a player who could eat me and is close makes me run away", function()
	local others: { AutoFarm.Other } = { { x = 20, z = 0, scale = 3 } }
	local target = AutoFarm.pickTarget(config, rules, me, { food(-50, 0, 1) }, others, ARENA)
	assertEquals(target.kind, "flee")
	assertTrue(target.x < 0, "away from the danger")
	assertNear(target.x, -40, 1e-9)
	assertNear(target.z, 0, 1e-9)
end)

test("AutoFarm: no flight while the danger is outside its reach", function()
	-- reach = (3 + 1) * 2 + 25 = 33
	local far: { AutoFarm.Other } = { { x = 40, z = 0, scale = 3 } }
	assertEquals(AutoFarm.pickTarget(config, rules, me, { food(-50, 0, 1) }, far, ARENA).kind, "food")
	local near: { AutoFarm.Other } = { { x = 29, z = 0, scale = 3 } }
	assertEquals(AutoFarm.pickTarget(config, rules, me, { food(-50, 0, 1) }, near, ARENA).kind, "flee")
end)

test("AutoFarm: flight stays inside the arena", function()
	local corner: AutoFarm.Me = { x = 200, z = 200, scale = 1 }
	local others: { AutoFarm.Other } = { { x = 180, z = 180, scale = 3 } }
	local target = AutoFarm.pickTarget(config, rules, corner, {}, others, ARENA)
	assertEquals(target.kind, "flee")
	assertTrue(math.sqrt(target.x * target.x + target.z * target.z) <= ARENA - config.arenaMargin + 1e-9)
end)

test("AutoFarm: standing on the danger still gives a direction", function()
	local others: { AutoFarm.Other } = { { x = 0, z = 0, scale = 3 } }
	local target = AutoFarm.pickTarget(config, rules, me, {}, others, ARENA)
	assertEquals(target.kind, "flee")
	assertTrue(target.x ~= 0 or target.z ~= 0)
end)

test("AutoFarm: food inside the reach of a danger is skipped", function()
	local others: { AutoFarm.Other } = { { x = 100, z = 0, scale = 3 } }
	-- the piece at 90 is next to the danger (reach 29.5), the one at -60 is safe
	local target = AutoFarm.pickTarget(config, rules, me, { food(90, 0, 10), food(-60, 0, 1) }, others, ARENA)
	assertEquals(target.kind, "food")
	assertEquals(target.x, -60)
end)

test("AutoFarm: when every piece is in danger it stays", function()
	local others: { AutoFarm.Other } = { { x = 100, z = 0, scale = 3 } }
	local target = AutoFarm.pickTarget(config, rules, me, { food(90, 0, 1), food(110, 0, 1) }, others, ARENA)
	assertEquals(target.kind, "idle")
end)

test("AutoFarm: the deepest danger decides the direction of the flight", function()
	local others: { AutoFarm.Other } = { { x = 25, z = 0, scale = 3 }, { x = 0, z = 10, scale = 3 } }
	local target = AutoFarm.pickTarget(config, rules, me, {}, others, ARENA)
	assertEquals(target.kind, "flee")
	assertTrue(target.z < 0, "away from the closest one")
end)

test("AutoFarm: invalid positions of others are ignored", function()
	local others: { AutoFarm.Other } = { { x = 0 / 0, z = 0, scale = 3 }, { x = 5, z = math.huge, scale = 3 } }
	local target = AutoFarm.pickTarget(config, rules, me, { food(10, 0, 1) }, others, ARENA)
	assertEquals(target.kind, "food")
end)

test("AutoFarm: an invalid own position gives idle", function()
	local broken: AutoFarm.Me = { x = 0 / 0, z = 0, scale = 1 }
	assertEquals(AutoFarm.pickTarget(config, rules, broken, { food(1, 1, 1) }, {}, ARENA).kind, "idle")
end)

test("AutoFarm: the real config works with the real eating rules", function()
	local real: AutoFarm.Config = AutoFarmConfig
	local realRules: AutoFarm.Rules = Arena
	local big: { AutoFarm.Other } = { { x = 20, z = 0, scale = 5 } }
	assertEquals(AutoFarm.pickTarget(real, realRules, me, { food(-50, 0, 1) }, big, Arena.radius).kind, "flee")
	assertEquals(AutoFarm.pickTarget(real, realRules, me, { food(-50, 0, 1) }, {}, Arena.radius).kind, "food")
end)

test("AutoFarm: a session ends after the maximum time", function()
	assertTrue(AutoFarm.sessionActive(100, 100, 600))
	assertTrue(AutoFarm.sessionActive(100, 699.9, 600))
	assertTrue(not AutoFarm.sessionActive(100, 700, 600))
	assertTrue(not AutoFarm.sessionActive(100, 5000, 600))
end)

test("AutoFarm: invalid session values are never active", function()
	assertTrue(not AutoFarm.sessionActive(0 / 0, 100, 600))
	assertTrue(not AutoFarm.sessionActive(100, 0 / 0, 600))
	assertTrue(not AutoFarm.sessionActive(100, 110, 0))
	assertTrue(not AutoFarm.sessionActive(100, 90, 600), "a start in the future")
end)
