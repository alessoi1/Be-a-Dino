--!strict
local Framework = require("../Framework")
local FoodKinds = require("../../src/shared/FoodKinds")
local FoodConfig = require("../../src/shared/Config/Food")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertTrue = Framework.assertTrue

local function kind(id: string, value: number, weight: number): FoodKinds.Kind
	return { id = id, value = value, weight = weight, size = 1, color = { r = 0, g = 0, b = 0 } }
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
