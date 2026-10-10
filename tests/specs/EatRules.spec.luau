--!strict
local EatRules = require("../../src/shared/EatRules")
local Framework = require("../Framework")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertTrue = Framework.assertTrue

local config: EatRules.Config = { eatRatio = 1.2, eatDistanceFactor = 1.5 }

local function eater(): EatRules.Combatant
	return { id = 1, scale = 3, protectedUntil = 0 }
end

local function victim(): EatRules.Combatant
	return { id = 2, scale = 1, protectedUntil = 0 }
end

test("EatRules: bigger player in range may eat", function()
	local ok, reason = EatRules.canEat(config, eater(), victim(), 2, 100)
	assertTrue(ok)
	assertEquals(reason, nil)
end)

test("EatRules: size ratio threshold is exact", function()
	local e = eater()
	e.scale = 1.2
	local ok = EatRules.canEat(config, e, victim(), 1, 100)
	assertTrue(ok, "1.2 is enough")
	e.scale = 1.19
	local ok2, reason = EatRules.canEat(config, e, victim(), 1, 100)
	assertTrue(not ok2)
	assertEquals(reason, "too_small")
end)

test("EatRules: distance limit scales with eater size", function()
	local ok = EatRules.canEat(config, eater(), victim(), 4.5, 100)
	assertTrue(ok, "3 * 1.5 = 4.5 is in range")
	local ok2, reason = EatRules.canEat(config, eater(), victim(), 4.6, 100)
	assertTrue(not ok2)
	assertEquals(reason, "too_far")
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
end)

test("EatRules: eater gets a share of the victim points, rounded down", function()
	assertEquals(EatRules.pointsGained(0.5, 100), 50)
	assertEquals(EatRules.pointsGained(0.5, 51), 25)
	assertEquals(EatRules.pointsGained(0.5, 0), 0)
	assertEquals(EatRules.pointsGained(0.5, -10), 0)
end)
