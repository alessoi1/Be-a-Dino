--!strict
local Framework = require("../Framework")
local Arena = require("../../src/shared/Config/Arena")
local Lobby = require("../../src/shared/Config/Lobby")
local LobbyDecor = require("../../src/shared/Config/LobbyDecor")
local LobbyLayout = require("../../src/shared/LobbyLayout")
local Zones = require("../../src/shared/Zones")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertTrue = Framework.assertTrue

test("Lobby: the platform reaches the arena wall at the window and leaves no hole", function()
	local outer = Arena.radius + Arena.wallThickness
	local northEdge = Lobby.centerZ - Lobby.size / 2
	assertEquals(northEdge, outer - Lobby.northInset)
	-- Where the wall ring is farthest from the lobby edge (the platform corners), it still lies
	-- inside the platform's covered area.
	local corner = Lobby.size / 2
	local wallAtCorner = math.sqrt(outer * outer - corner * corner)
	assertTrue(northEdge < wallAtCorner, "the platform edge is behind the wall at the corners")
end)

test("Lobby: the platform stands on the side of the viewing window", function()
	assertEquals(Arena.windowAngleDegrees, 90)
	assertEquals(Lobby.centerX, 0)
	assertTrue(Lobby.centerZ > Arena.radius, "the lobby is on the +Z side, beside the dome")
end)

test("Lobby: the platform stays out of the dome and its circles are inside the visible part", function()
	local half = Lobby.size / 2
	assertTrue(Lobby.centerZ - half + Lobby.northInset >= Arena.radius, "the visible part starts at the wall")
	for _, zone in Lobby.zones do
		assertTrue(
			zone.z - zone.radius >= -half + Lobby.northInset + Lobby.spawnMargin,
			zone.id .. " not under the wall"
		)
	end
	assertEquals(table.concat(Zones.validate(Lobby.zones, Lobby.size, Lobby.spawnMargin), "; "), "")
end)

test("Lobby: the floor is just below the arena floor", function()
	assertTrue(Lobby.height < 0 and Lobby.height > -0.5)
end)

test("Lobby: the decoration lies inside the visible platform and clear of the glowing circles", function()
	local problems = LobbyLayout.validate(LobbyDecor, Lobby.size, Lobby.northInset, Lobby.zones)
	assertEquals(table.concat(problems, "; "), "")
end)

test("Lobby: the decoration list has every piece and its circles for the spawn", function()
	local circles = LobbyLayout.circles(LobbyDecor)
	assertEquals(#circles, #LobbyDecor.pillars + #LobbyDecor.benches + #LobbyDecor.planters + 1)
	for _, circle in circles do
		assertTrue(circle.radius > 0 and circle.dwell == 0)
	end
end)

test("Lobby: a misplaced decoration is found", function()
	local bad = table.clone(LobbyDecor)
	bad.benches = { { x = 0, z = 0 } }
	local problems = LobbyLayout.validate(bad, Lobby.size, Lobby.northInset, Lobby.zones)
	assertTrue(#problems > 0, "a bench in the play circle")
	local outside = table.clone(LobbyDecor)
	outside.planters = { { x = 80, z = 0 }, { x = 0, z = -60 } }
	assertTrue(#LobbyLayout.validate(outside, Lobby.size, Lobby.northInset, Lobby.zones) >= 2)
end)

test("Lobby: the roof is above the dome side wall and the lamps hang below it", function()
	assertTrue(LobbyDecor.roof.height > 20, "above the pillars of people and the boards")
	assertTrue(LobbyDecor.lampDrop > 0 and LobbyDecor.roof.height - LobbyDecor.lampDrop > 8)
	assertTrue(LobbyDecor.roof.skylightHalfWidth < LobbyDecor.roof.halfWidth)
end)
