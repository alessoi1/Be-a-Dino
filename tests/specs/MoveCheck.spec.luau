--!strict
local Framework = require("../Framework")
local MoveCheck = require("../../src/shared/MoveCheck")

local test = Framework.test
local assertEquals = Framework.assertEquals

local config: MoveCheck.Config = { speedTolerance = 1.5, moveSlack = 2 }

test("MoveCheck: normal movement is ok", function()
	-- speed 20 for 0.1 s = 2 studs
	assertEquals(MoveCheck.check(config, { x = 0, z = 0 }, { x = 2, z = 0 }, 0.1, 20), "ok")
end)

test("MoveCheck: the limit is speed * dt * tolerance + slack", function()
	-- 20 * 0.1 * 1.5 + 2 = 5
	assertEquals(MoveCheck.check(config, { x = 0, z = 0 }, { x = 5, z = 0 }, 0.1, 20), "ok")
	assertEquals(MoveCheck.check(config, { x = 0, z = 0 }, { x = 5.1, z = 0 }, 0.1, 20), "rubberband")
end)

test("MoveCheck: distance is measured diagonally", function()
	assertEquals(MoveCheck.check(config, { x = 0, z = 0 }, { x = 3, z = 4 }, 0.1, 20), "ok")
	assertEquals(MoveCheck.check(config, { x = 0, z = 0 }, { x = 4, z = 4 }, 0.1, 20), "rubberband")
end)

test("MoveCheck: a teleport is rejected", function()
	assertEquals(MoveCheck.check(config, { x = 0, z = 0 }, { x = 150, z = -80 }, 0.1, 20), "rubberband")
end)

test("MoveCheck: a higher speed (sprint) raises the limit", function()
	assertEquals(MoveCheck.check(config, { x = 0, z = 0 }, { x = 6, z = 0 }, 0.1, 20), "rubberband")
	assertEquals(MoveCheck.check(config, { x = 0, z = 0 }, { x = 6, z = 0 }, 0.1, 30), "ok")
end)

test("MoveCheck: no previous position is ok", function()
	assertEquals(MoveCheck.check(config, nil, { x = 100, z = 100 }, 0.1, 20), "ok")
end)

test("MoveCheck: invalid numbers are rejected", function()
	assertEquals(MoveCheck.check(config, { x = 0, z = 0 }, { x = 0 / 0, z = 0 }, 0.1, 20), "rubberband")
	assertEquals(MoveCheck.check(config, { x = 0, z = 0 }, { x = math.huge, z = 0 }, 0.1, 20), "rubberband")
	assertEquals(MoveCheck.check(config, { x = 0, z = 0 }, { x = 1, z = 0 }, -1, 20), "rubberband")
end)
