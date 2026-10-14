--!strict
local Framework = require("../Framework")
local Combo = require("../../src/shared/Combo")
local ComboConfig = require("../../src/shared/Config/Combo")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertTrue = Framework.assertTrue

test("Combo: the first piece starts a combo of 1", function()
	local state = Combo.bump(nil, 10, 3)
	assertEquals(state.count, 1)
	assertEquals(state.lastAt, 10)
end)

test("Combo: pieces within the window raise the count", function()
	local state = Combo.bump(nil, 10, 3)
	state = Combo.bump(state, 12, 3)
	state = Combo.bump(state, 15, 3)
	assertEquals(state.count, 3)
end)

test("Combo: a piece after the window starts again", function()
	local state = Combo.bump(nil, 10, 3)
	state = Combo.bump(state, 12, 3)
	state = Combo.bump(state, 15.5, 3)
	assertEquals(state.count, 1)
end)

test("Combo: a clock that went back starts again", function()
	local state = Combo.bump({ count = 5, lastAt = 100 }, 90, 3)
	assertEquals(state.count, 1)
end)

test("Combo: invalid input never raises the count", function()
	assertEquals(Combo.bump({ count = 5, lastAt = 1 }, 0 / 0, 3).count, 1)
	assertEquals(Combo.bump({ count = 5, lastAt = 1 }, 2, 0).count, 1)
end)

test("Combo: the current count is 0 after the window", function()
	local state: Combo.State = { count = 4, lastAt = 10 }
	assertEquals(Combo.current(state, 12, 3), 4)
	assertEquals(Combo.current(state, 13, 3), 4)
	assertEquals(Combo.current(state, 13.1, 3), 0)
	assertEquals(Combo.current(nil, 12, 3), 0)
end)

test("Combo: the config is usable", function()
	assertTrue(ComboConfig.windowSeconds > 0)
	assertTrue(ComboConfig.minShown >= 1)
	assertTrue(ComboConfig.milestoneEvery >= 1)
end)
