--!strict
local Framework = require("../Framework")
local FoodKinds = require("../../src/shared/FoodKinds")
local FoodConfig = require("../../src/shared/Config/Food")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertTrue = Framework.assertTrue

local function kind(id: string, value: number, weight: number): FoodKinds.Kind
	return {
		id = id,
		value = value,
		weight = weight,
		size = 1,
		color = { r = 0, g = 0, b = 0 },
		variants = {
			{
				id = "plain",
				shape = "ball",
				meshId = 0,
				meshScale = { x = 1, y = 1, z = 1 },
				scale = { x = 1, y = 1, z = 1 },
				color = { r = 0, g = 0, b = 0 },
				weight = 1,
			},
		},
	}
end

local kinds = { kind("a", 1, 85), kind("b", 3, 12), kind("c", 10, 3) }

test("FoodKinds: pick follows the weights at the borders", function()
	assertEquals(FoodKinds.pick(kinds, 0), 1)
	assertEquals(FoodKinds.pick(kinds, 0.84), 1)
	assertEquals(FoodKinds.pick(kinds, 0.85), 2)
	assertEquals(FoodKinds.pick(kinds, 0.96), 2)
	assertEquals(FoodKinds.pick(kinds, 0.97), 3)
	assertEquals(FoodKinds.pick(kinds, 0.999999), 3)
end)

test("FoodKinds: out of range or invalid rolls stay valid", function()
	assertEquals(FoodKinds.pick(kinds, 1), 3)
	assertEquals(FoodKinds.pick(kinds, 5), 3)
	assertEquals(FoodKinds.pick(kinds, -1), 1)
	assertEquals(FoodKinds.pick(kinds, 0 / 0), 1)
end)

test("FoodKinds: all kinds are reachable", function()
	local seen: { [number]: boolean } = {}
	for i = 0, 99 do
		seen[FoodKinds.pick(kinds, i / 100)] = true
	end
	assertTrue(seen[1] and seen[2] and seen[3])
end)

test("FoodKinds: a valid config has no errors", function()
	assertEquals(#FoodKinds.validate(kinds), 0)
	assertEquals(#FoodKinds.validate(FoodConfig.kinds), 0, "the real config")
end)

test("FoodKinds: invalid configs are reported", function()
	assertTrue(#FoodKinds.validate({}) > 0, "empty")
	assertTrue(#FoodKinds.validate({ kind("a", 1, 0) }) > 0, "weight 0")
	assertTrue(#FoodKinds.validate({ kind("a", -1, 5) }) > 0, "negative value")
	assertTrue(#FoodKinds.validate({ kind("a", 1, 5), kind("a", 2, 5) }) > 0, "duplicate id")
end)

test("FoodKinds: pickWeighted follows the zone weights", function()
	local weights = { a = 40, b = 40, c = 20 }
	assertEquals(FoodKinds.pickWeighted(kinds, weights, 0), 1)
	assertEquals(FoodKinds.pickWeighted(kinds, weights, 0.39), 1)
	assertEquals(FoodKinds.pickWeighted(kinds, weights, 0.4), 2)
	assertEquals(FoodKinds.pickWeighted(kinds, weights, 0.79), 2)
	assertEquals(FoodKinds.pickWeighted(kinds, weights, 0.8), 3)
	assertEquals(FoodKinds.pickWeighted(kinds, weights, 1), 3)
end)

test("FoodKinds: pickWeighted skips kinds without weight and handles bad rolls", function()
	local weights = { b = 10 }
	assertEquals(FoodKinds.pickWeighted(kinds, weights, 0), 2)
	assertEquals(FoodKinds.pickWeighted(kinds, weights, 0.99), 2)
	assertEquals(FoodKinds.pickWeighted(kinds, { a = 1, b = 1, c = 1 }, 0 / 0), 1)
	assertEquals(FoodKinds.pickWeighted(kinds, {}, 0.5), FoodKinds.pick(kinds, 0.5), "no weights: the normal weights")
end)

local zones = { center = { radius = 60, count = 80, spawnClearance = 20, weights = { a = 40, b = 40, c = 20 } } }

test("FoodKinds: validateZones accepts a good zone", function()
	assertEquals(#FoodKinds.validateZones(kinds, zones, 300, 450, 4), 0)
end)

test("FoodKinds: the real zone config is valid", function()
	local errors = FoodKinds.validateZones(FoodConfig.kinds, FoodConfig.zones, 300, FoodConfig.count, FoodConfig.margin)
	assertEquals(table.concat(errors, "; "), "")
end)

test("FoodKinds: validateZones reports broken zones", function()
	local function problems(change: (zone: any) -> ()): { string }
		local zone = { radius = 60, count = 80, spawnClearance = 20, weights = { a = 40, b = 40, c = 20 } }
		change(zone)
		return FoodKinds.validateZones(kinds, { center = zone }, 300, 450, 4)
	end
	assertTrue(#problems(function(zone)
		zone.radius = 0
	end) > 0, "radius 0")
	assertTrue(#problems(function(zone)
		zone.radius = 298
	end) > 0, "disc leaves the arena")
	assertTrue(#problems(function(zone)
		zone.count = 500
	end) > 0, "more pieces than food")
	assertTrue(#problems(function(zone)
		zone.count = -1
	end) > 0, "negative count")
	assertTrue(#problems(function(zone)
		zone.weights = { x = 5 }
	end) > 0, "unknown kind")
	assertTrue(#problems(function(zone)
		zone.weights = { a = 0, b = 0 }
	end) > 0, "no weight")
	assertTrue(#problems(function(zone)
		zone.weights = { a = -1, b = 5 }
	end) > 0, "negative weight")
	assertTrue(#problems(function(zone)
		zone.spawnClearance = -5
	end) > 0, "negative clearance")
end)

local function twoVariants(): FoodKinds.Kind
	local base = kind("v", 1, 1)
	local first = base.variants[1]
	local second = table.clone(first)
	second.id = "second"
	second.weight = 3
	base.variants = { first, second }
	return base
end

test("FoodKinds: pickVariant follows the variant weights", function()
	local food = twoVariants()
	assertEquals(FoodKinds.pickVariant(food, 0), 1)
	assertEquals(FoodKinds.pickVariant(food, 0.24), 1)
	assertEquals(FoodKinds.pickVariant(food, 0.25), 2)
	assertEquals(FoodKinds.pickVariant(food, 0.999), 2)
	assertEquals(FoodKinds.pickVariant(food, 5), 2, "too big a roll")
	assertEquals(FoodKinds.pickVariant(food, 0 / 0), 1, "invalid roll")
end)

test("FoodKinds: a variant without weight is never picked, no variants give 0", function()
	local food = twoVariants()
	food.variants[1].weight = 0
	for i = 0, 9 do
		assertEquals(FoodKinds.pickVariant(food, i / 10), 2)
	end
	food.variants = {}
	assertEquals(FoodKinds.pickVariant(food, 0.5), 0)
end)

test("FoodKinds: broken variants are reported", function()
	local function problems(change: (variant: FoodKinds.Variant) -> ()): number
		local food = kind("a", 1, 5)
		change(food.variants[1])
		return #FoodKinds.validate({ food })
	end
	assertTrue(problems(function(variant)
		variant.shape = "cube"
	end) > 0, "unknown shape")
	assertTrue(problems(function(variant)
		variant.scale = { x = 1, y = 0, z = 1 }
	end) > 0, "scale 0")
	assertTrue(problems(function(variant)
		variant.weight = 0
	end) > 0, "no weight at all")
	assertTrue(problems(function(variant)
		variant.meshId = -3
	end) > 0, "negative mesh id")
	local none = kind("a", 1, 5)
	none.variants = {}
	assertTrue(#FoodKinds.validate({ none }) > 0, "no variants")
end)

test("FoodKinds: every kind in the real config has several looks", function()
	for _, food in FoodConfig.kinds do
		assertTrue(#food.variants >= 2, food.id .. " should have at least two looks")
	end
end)
