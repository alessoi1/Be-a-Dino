--!strict
local Bounty = require("../../src/shared/Bounty")
local Framework = require("../Framework")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertTrue = Framework.assertTrue

test("Bounty: placing a bounty marks the player for the duration", function()
	local state: Bounty.State = {}
	assertTrue(Bounty.place(state, 7, 100, 120))
	assertTrue(Bounty.isActive(state, 7, 100))
	assertTrue(Bounty.isActive(state, 7, 219.9))
	assertTrue(not Bounty.isActive(state, 7, 220))
	assertTrue(not Bounty.isActive(state, 8, 100), "other players are not marked")
end)

test("Bounty: a second bounty renews the time and does not stack", function()
	local state: Bounty.State = {}
	assertTrue(Bounty.place(state, 7, 100, 120))
	assertTrue(not Bounty.place(state, 7, 150, 120), "renewed, not new")
	assertTrue(Bounty.isActive(state, 7, 269))
	assertEquals(Bounty.multiplierFor(state, 7, 200, 3), 3, "still only one multiplier")
end)

test("Bounty: placing again after it ended counts as new", function()
	local state: Bounty.State = {}
	Bounty.place(state, 7, 100, 10)
	assertTrue(Bounty.place(state, 7, 200, 10))
end)

test("Bounty: invalid input places nothing", function()
	local state: Bounty.State = {}
	assertTrue(not Bounty.place(state, 7, 100, 0))
	assertTrue(not Bounty.place(state, 7, 100, -5))
	assertTrue(not Bounty.place(state, 7, 0 / 0, 10))
	assertTrue(not Bounty.place(state, 0 / 0, 100, 10))
	assertEquals(next(state), nil)
end)

test("Bounty: the multiplier applies only while the bounty is active", function()
	local state: Bounty.State = {}
	assertEquals(Bounty.multiplierFor(state, 7, 100, 3), 1)
	Bounty.place(state, 7, 100, 120)
	assertEquals(Bounty.multiplierFor(state, 7, 100, 3), 3)
	assertEquals(Bounty.multiplierFor(state, 7, 220, 3), 1, "ended")
	assertEquals(Bounty.multiplierFor(state, 7, 150, 0.5), 1, "a multiplier below 1 is ignored")
	assertEquals(Bounty.multiplierFor(state, 7, 150, 0 / 0), 1)
end)

test("Bounty: claim reports an active bounty once and removes it", function()
	local state: Bounty.State = {}
	Bounty.place(state, 7, 100, 120)
	assertTrue(Bounty.claim(state, 7, 150))
	assertTrue(not Bounty.claim(state, 7, 150), "only once")
	assertTrue(not Bounty.isActive(state, 7, 150))
end)

test("Bounty: claiming an ended bounty gives nothing", function()
	local state: Bounty.State = {}
	Bounty.place(state, 7, 100, 10)
	assertTrue(not Bounty.claim(state, 7, 500))
	assertEquals(next(state), nil, "and it is removed")
end)

test("Bounty: clear removes a bounty", function()
	local state: Bounty.State = {}
	Bounty.place(state, 7, 100, 120)
	Bounty.clear(state, 7)
	assertTrue(not Bounty.isActive(state, 7, 100))
end)

test("Bounty: sweep removes only the ended ones and lists them", function()
	local state: Bounty.State = {}
	Bounty.place(state, 1, 100, 10)
	Bounty.place(state, 2, 100, 50)
	Bounty.place(state, 3, 100, 10)
	local ended = Bounty.sweep(state, 120)
	table.sort(ended)
	assertEquals(#ended, 2)
	assertEquals(ended[1], 1)
	assertEquals(ended[2], 3)
	assertTrue(Bounty.isActive(state, 2, 120))
	assertEquals(#Bounty.sweep(state, 120), 0)
end)

test("Bounty: targets are independent", function()
	local state: Bounty.State = {}
	Bounty.place(state, 1, 100, 120)
	Bounty.place(state, 2, 100, 120)
	Bounty.claim(state, 1, 110)
	assertTrue(Bounty.isActive(state, 2, 110))
end)
