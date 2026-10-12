--!strict
local Eggs = require("../../src/shared/Eggs")
local EggConfig = require("../../src/shared/Config/Eggs")
local Framework = require("../Framework")
local VariantConfig = require("../../src/shared/Config/Variants")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertNear = Framework.assertNear
local assertTrue = Framework.assertTrue

local order = { "glowing", "gold", "shadow", "rainbow" }
local weights = { glowing = 70, gold = 22, shadow = 6, rainbow = 2 }
local config: Eggs.Config = { price = 200, weights = weights, duplicateRefundShare = 0.5, cooldownSeconds = 1 }

local function owns(_dinoId: string, _variantId: string): boolean
	return false
end

local function sum(values: { [string]: number }): number
	local total = 0
	for _, value in values do
		total += value
	end
	return total
end

test("Eggs: the real config is valid", function()
	local ids: { [string]: boolean } = {}
	local variantOrder: { string } = {}
	for _, variant in VariantConfig.variants do
		ids[variant.id] = true
		table.insert(variantOrder, variant.id)
	end
	assertEquals(table.concat(Eggs.validate(EggConfig, ids), "; "), "")
	-- Every variant can be found in an egg, and the chances add up to 100.
	local percents = Eggs.percentages(EggConfig.weights, variantOrder)
	for _, id in variantOrder do
		assertTrue(percents[id] > 0, id .. " has a chance")
	end
	assertNear(sum(percents), 100, 1e-9)
end)

test("Eggs: percentages show the chances with one decimal and add up to 100", function()
	local percents = Eggs.percentages(weights, order)
	assertEquals(percents.glowing, 70)
	assertEquals(percents.gold, 22)
	assertEquals(percents.shadow, 6)
	assertEquals(percents.rainbow, 2)
end)

test("Eggs: uneven chances still add up to exactly 100", function()
	local percents = Eggs.percentages({ glowing = 1, gold = 1, shadow = 1 }, { "glowing", "gold", "shadow" })
	assertNear(sum(percents), 100, 1e-9)
	assertEquals(percents.glowing, 33.4, "the largest remainder goes first, ties by id")
	assertEquals(percents.gold, 33.3)
	local odd = Eggs.percentages({ glowing = 3, gold = 7 }, { "glowing", "gold" })
	assertEquals(odd.glowing, 30)
	assertEquals(odd.gold, 70)
	local small = Eggs.percentages({ glowing = 999, gold = 1 }, { "glowing", "gold" })
	assertNear(sum(small), 100, 1e-9)
end)

test("Eggs: percentages without weights are 0", function()
	local percents = Eggs.percentages({}, order)
	assertEquals(percents.gold, 0)
	local negative = Eggs.percentages({ glowing = -5, gold = 5 }, order)
	assertEquals(negative.glowing, 0)
	assertEquals(negative.gold, 100)
end)

test("Eggs: the variant follows the chances at the borders", function()
	assertEquals(Eggs.pickVariant(weights, order, 0), "glowing")
	assertEquals(Eggs.pickVariant(weights, order, 0.69), "glowing")
	assertEquals(Eggs.pickVariant(weights, order, 0.7), "gold")
	assertEquals(Eggs.pickVariant(weights, order, 0.91), "gold")
	assertEquals(Eggs.pickVariant(weights, order, 0.92), "shadow")
	assertEquals(Eggs.pickVariant(weights, order, 0.97), "shadow")
	assertEquals(Eggs.pickVariant(weights, order, 0.98), "rainbow")
	assertEquals(Eggs.pickVariant(weights, order, 0.9999), "rainbow")
end)

test("Eggs: rolls outside 0 to 1 and invalid rolls stay valid", function()
	assertEquals(Eggs.pickVariant(weights, order, 1), "rainbow")
	assertEquals(Eggs.pickVariant(weights, order, 7), "rainbow")
	assertEquals(Eggs.pickVariant(weights, order, -1), "glowing")
	assertEquals(Eggs.pickVariant(weights, order, 0 / 0), "glowing")
end)

test("Eggs: a variant without a weight is never chosen", function()
	assertEquals(Eggs.pickVariant({ gold = 5 }, order, 0), "gold")
	assertEquals(Eggs.pickVariant({ gold = 5 }, order, 0.99), "gold")
	assertEquals(Eggs.pickVariant({}, order, 0.5), nil)
end)

test("Eggs: the dino is chosen evenly among the reached ones", function()
	local reached = { "compy", "raptor", "trex" }
	local function dinoFor(roll: number): string
		local result = Eggs.roll(config, order, reached, owns, 0, roll) :: Eggs.Result
		return result.dinoId
	end
	assertEquals(dinoFor(0), "compy")
	assertEquals(dinoFor(0.33), "compy")
	assertEquals(dinoFor(0.34), "raptor")
	assertEquals(dinoFor(0.66), "raptor")
	assertEquals(dinoFor(0.67), "trex")
	assertEquals(dinoFor(1), "trex")
	assertEquals(dinoFor(5), "trex")
end)

test("Eggs: only reached dinos can come out, so there are none without one", function()
	assertEquals(Eggs.roll(config, order, {}, owns, 0.5, 0.5), nil)
	local result = Eggs.roll(config, order, { "compy" }, owns, 0.5, 0.5) :: Eggs.Result
	assertEquals(result.dinoId, "compy")
end)

test("Eggs: a variant the player owns is a duplicate", function()
	local function ownsGold(dinoId: string, variantId: string): boolean
		return dinoId == "compy" and variantId == "gold"
	end
	local duplicate = Eggs.roll(config, order, { "compy" }, ownsGold, 0.8, 0) :: Eggs.Result
	assertEquals(duplicate.variantId, "gold")
	assertTrue(duplicate.duplicate)
	local fresh = Eggs.roll(config, order, { "compy" }, ownsGold, 0.1, 0) :: Eggs.Result
	assertEquals(fresh.variantId, "glowing")
	assertTrue(not fresh.duplicate)
	local otherDino = Eggs.roll(config, order, { "raptor" }, ownsGold, 0.8, 0) :: Eggs.Result
	assertTrue(not otherDino.duplicate, "per dino")
end)

test("Eggs: the chances of many rolls match the weights", function()
	local counts: { [string]: number } = {}
	local state = 12345
	local function rng(): number
		state = (state * 16807) % 2147483647
		return state / 2147483647
	end
	local total = 20000
	for _ = 1, total do
		local id = Eggs.pickVariant(weights, order, rng()) :: string
		counts[id] = (counts[id] or 0) + 1
	end
	assertNear(counts.glowing / total, 0.7, 0.02)
	assertNear(counts.gold / total, 0.22, 0.02)
	assertNear(counts.shadow / total, 0.06, 0.01)
	assertTrue((counts.rainbow or 0) > 0, "rainbow comes up")
end)

test("Eggs: the refund is a share of the price, rounded down", function()
	assertEquals(Eggs.refund(200, 0.5), 100)
	assertEquals(Eggs.refund(201, 0.5), 100)
	assertEquals(Eggs.refund(200, 0), 0)
	assertEquals(Eggs.refund(200, 5), 200, "never more than the price")
	assertEquals(Eggs.refund(-5, 0.5), 0)
	assertEquals(Eggs.refund(200, 0 / 0), 0)
end)

test("Eggs: validate reports broken configs", function()
	local ids = { glowing = true, gold = true }
	local function problems(change: (c: any) -> ()): { string }
		local copy: any =
			{ price = 200, weights = { glowing = 1, gold = 1 }, duplicateRefundShare = 0.5, cooldownSeconds = 1 }
		change(copy)
		return Eggs.validate(copy, ids)
	end
	assertEquals(#problems(function() end), 0)
	assertTrue(#problems(function(c)
		c.price = 0
	end) > 0, "price 0")
	assertTrue(#problems(function(c)
		c.price = 10.5
	end) > 0, "price not whole")
	assertTrue(#problems(function(c)
		c.duplicateRefundShare = 2
	end) > 0, "share above 1")
	assertTrue(#problems(function(c)
		c.cooldownSeconds = -1
	end) > 0, "negative cooldown")
	assertTrue(#problems(function(c)
		c.weights = { chrome = 5 }
	end) > 0, "unknown variant")
	assertTrue(#problems(function(c)
		c.weights = { glowing = 0, gold = 0 }
	end) > 0, "no weight")
	assertTrue(#problems(function(c)
		c.weights = { glowing = -1, gold = 5 }
	end) > 0, "negative weight")
end)
