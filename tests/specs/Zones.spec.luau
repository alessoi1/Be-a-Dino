--!strict
local Framework = require("../Framework")
local LobbyConfig = require("../../src/shared/Config/Lobby")
local Zones = require("../../src/shared/Zones")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertNear = Framework.assertNear
local assertTrue = Framework.assertTrue

local play: Zones.Zone = { id = "play", x = 0, z = 0, radius = 12, dwell = 2 }
local shop: Zones.Zone = { id = "shop", x = -45, z = 0, radius = 7, dwell = 0 }
local zones = { play, shop }

test("Zones: zoneAt finds the circle a point is in, border included", function()
	assertEquals((Zones.zoneAt(zones, 0, 0) :: Zones.Zone).id, "play")
	assertEquals((Zones.zoneAt(zones, 12, 0) :: Zones.Zone).id, "play")
	assertEquals(Zones.zoneAt(zones, 12.01, 0), nil)
	assertEquals((Zones.zoneAt(zones, -45, 7) :: Zones.Zone).id, "shop")
end)

test("Zones: zoneAt gives nothing between circles and for invalid points", function()
	assertEquals(Zones.zoneAt(zones, 25, 25), nil)
	assertEquals(Zones.zoneAt(zones, 0 / 0, 0), nil)
	assertEquals(Zones.zoneAt(zones, math.huge, 0), nil)
	assertEquals(Zones.zoneAt({}, 0, 0), nil)
end)

test("Zones: with overlapping circles the nearest center wins", function()
	local a: Zones.Zone = { id = "a", x = 0, z = 0, radius = 10, dwell = 0 }
	local b: Zones.Zone = { id = "b", x = 8, z = 0, radius = 10, dwell = 0 }
	assertEquals((Zones.zoneAt({ a, b }, 2, 0) :: Zones.Zone).id, "a")
	assertEquals((Zones.zoneAt({ a, b }, 6, 0) :: Zones.Zone).id, "b")
end)

test("Zones: isClear keeps a margin to every circle", function()
	assertTrue(Zones.isClear(zones, 30, 30, 6))
	assertTrue(not Zones.isClear(zones, 14, 0, 6), "inside the margin of the play circle")
	assertTrue(Zones.isClear(zones, 18, 0, 6), "exactly at the margin")
	assertTrue(not Zones.isClear(zones, -38, 0, 6), "inside the shop circle")
end)

test("Zones: validate accepts a good layout", function()
	assertEquals(#Zones.validate(zones, 140, 8), 0)
end)

test("Zones: the real lobby config is valid", function()
	local errors = Zones.validate(LobbyConfig.zones, LobbyConfig.size, LobbyConfig.spawnMargin)
	assertEquals(table.concat(errors, "; "), "")
end)

test("Zones: validate reports broken layouts", function()
	local function problems(list: { Zones.Zone }): { string }
		return Zones.validate(list, 140, 8)
	end
	assertTrue(#problems({ { id = "a", x = 0, z = 0, radius = 0, dwell = 0 } }) > 0, "radius 0")
	assertTrue(#problems({ { id = "a", x = 0, z = 0, radius = 5, dwell = -1 } }) > 0, "negative dwell")
	assertTrue(#problems({ { id = "a", x = 65, z = 0, radius = 7, dwell = 0 } }) > 0, "outside the platform")
	assertTrue(
		#problems({
				{ id = "a", x = 0, z = 0, radius = 5, dwell = 0 },
				{ id = "a", x = 30, z = 0, radius = 5, dwell = 0 },
			}) > 0,
		"duplicate id"
	)
	assertTrue(
		#problems({
				{ id = "a", x = 0, z = 0, radius = 10, dwell = 0 },
				{ id = "b", x = 15, z = 0, radius = 10, dwell = 0 },
			}) > 0,
		"overlap"
	)
	assertTrue(#problems({ { id = "a", x = 0 / 0, z = 0, radius = 5, dwell = 0 } }) > 0, "nan position")
end)

test("Zones: a circle triggers once, after the dwell time", function()
	local state = Zones.newDwell()
	local fired: boolean
	state, fired = Zones.step(state, play, 10)
	assertTrue(not fired, "just entered")
	state, fired = Zones.step(state, play, 11.9)
	assertTrue(not fired, "not yet")
	state, fired = Zones.step(state, play, 12)
	assertTrue(fired, "after 2 seconds")
	state, fired = Zones.step(state, play, 13)
	assertTrue(not fired, "only once per stay")
end)

test("Zones: a circle with no dwell triggers at once, once", function()
	local state, fired = Zones.step(Zones.newDwell(), shop, 5)
	assertTrue(fired)
	local _, again = Zones.step(state, shop, 6)
	assertTrue(not again)
end)

test("Zones: leaving resets, and entering again starts over", function()
	local state = Zones.newDwell()
	state = Zones.step(state, play, 10)
	state = Zones.step(state, nil, 11)
	assertEquals(state.zoneId, nil)
	local fired: boolean
	state, fired = Zones.step(state, play, 11.5)
	assertTrue(not fired)
	state, fired = Zones.step(state, play, 13.4)
	assertTrue(not fired, "the time counts from the new entry")
	_, fired = Zones.step(state, play, 13.5)
	assertTrue(fired)
end)

test("Zones: changing to another circle starts that circle", function()
	local state = Zones.step(Zones.newDwell(), play, 10)
	local fired: boolean
	state, fired = Zones.step(state, shop, 10.5)
	assertTrue(fired, "the shop has no dwell")
	assertEquals(state.zoneId, "shop")
end)

test("Zones: step does not change the old state", function()
	local old = Zones.newDwell()
	Zones.step(old, play, 10)
	assertEquals(old.zoneId, nil)
end)

test("Zones: remaining counts down and stops at zero", function()
	local state = Zones.step(Zones.newDwell(), play, 10)
	assertNear(Zones.remaining(state, play, 10.5), 1.5, 1e-9)
	assertEquals(Zones.remaining(state, play, 20), 0)
	assertEquals(Zones.remaining(state, nil, 10.5), 0)
	assertEquals(Zones.remaining(state, shop, 10.5), 0, "another circle")
	local fired = Zones.step(state, play, 12)
	assertEquals(Zones.remaining(fired, play, 12), 0, "already fired")
end)
