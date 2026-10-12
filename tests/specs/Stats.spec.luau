--!strict
local Framework = require("../Framework")
local Stats = require("../../src/shared/Stats")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertNear = Framework.assertNear

test("Stats: tick counts whole seconds and carries the rest", function()
	local whole, rest = Stats.tick(0, 0.4, 5)
	assertEquals(whole, 0)
	assertNear(rest, 0.4, 1e-9)
	whole, rest = Stats.tick(rest, 0.4, 5)
	assertEquals(whole, 0)
	assertNear(rest, 0.8, 1e-9)
	whole, rest = Stats.tick(rest, 0.4, 5)
	assertEquals(whole, 1)
	assertNear(rest, 0.2, 1e-9)
end)

test("Stats: no second is lost or counted twice over many steps", function()
	local total = 0
	local rest = 0
	for _ = 1, 100 do
		local whole
		whole, rest = Stats.tick(rest, 0.1, 5)
		total += whole
	end
	-- 100 steps of 0.1 s are 10 s (floating point may leave 9.999 seconds counted)
	assertEquals(total >= 9 and total <= 10, true, "counted " .. total)
end)

test("Stats: a long step counts only the maximum", function()
	local whole, rest = Stats.tick(0, 120, 5)
	assertEquals(whole, 5)
	assertNear(rest, 0, 1e-9)
end)

test("Stats: invalid steps and rests", function()
	local whole, rest = Stats.tick(0.5, 0 / 0, 5)
	assertEquals(whole, 0)
	assertNear(rest, 0.5, 1e-9)
	whole, rest = Stats.tick(0.5, -1, 5)
	assertEquals(whole, 0)
	assertNear(rest, 0.5, 1e-9)
	whole, rest = Stats.tick(0.5, math.huge, 5)
	assertEquals(whole, 0)
	whole, rest = Stats.tick(7, 0.5, 5)
	assertEquals(whole, 0, "a broken rest is dropped")
	assertNear(rest, 0.5, 1e-9)
end)

test("Stats: add never goes above the limit", function()
	assertEquals(Stats.add(10, 5, 100), 15)
	assertEquals(Stats.add(98, 5, 100), 100)
	assertEquals(Stats.add(100, 5, 100), 100)
	assertEquals(Stats.add(200, 5, 100), 100, "a value above the limit is cut")
end)

test("Stats: add takes whole numbers only and repairs bad values", function()
	assertEquals(Stats.add(10.7, 1.9, 100), 11)
	assertEquals(Stats.add(10, -5, 100), 10)
	assertEquals(Stats.add(10, 0 / 0, 100), 10)
	assertEquals(Stats.add(10, math.huge, 100), 10)
	assertEquals(Stats.add(-4, 5, 100), 5)
	assertEquals(Stats.add(0 / 0, 5, 100), 5)
end)
