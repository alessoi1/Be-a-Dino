--!strict
local CameraRig = require("../../src/shared/CameraRig")
local Framework = require("../Framework")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertNear = Framework.assertNear
local assertTrue = Framework.assertTrue

local config: CameraRig.Config = {
	distancePerScale = 12,
	minDistance = 10,
	smoothing = 5,
	deathHeight = 200,
	deathRadius = 100,
	deathTurnSpeed = 0.5,
	deathBlendSeconds = 2,
}

test("CameraRig: distance grows with the scale", function()
	assertEquals(CameraRig.distanceFor(config, 1), 12)
	assertEquals(CameraRig.distanceFor(config, 5), 60)
	local previous = 0
	for _, scale in { 1, 1.8, 3, 5 } do
		local distance = CameraRig.distanceFor(config, scale)
		assertTrue(distance > previous, "monotonic at " .. scale)
		previous = distance
	end
end)

test("CameraRig: distance never falls below the minimum", function()
	assertEquals(CameraRig.distanceFor(config, 0.1), 10)
	assertEquals(CameraRig.distanceFor(config, 0 / 0), 10)
	assertEquals(CameraRig.distanceFor(config, -3), 10)
end)

test("CameraRig: smooth moves toward the target without overshoot", function()
	local value = 12
	for _ = 1, 10 do
		local nextValue = CameraRig.smooth(config, value, 60, 0.1)
		assertTrue(nextValue > value and nextValue <= 60)
		value = nextValue
	end
	assertNear(CameraRig.smooth(config, 60, 60, 0.1), 60, 1e-9)
end)

test("CameraRig: smooth with a huge or invalid step stays valid", function()
	assertNear(CameraRig.smooth(config, 12, 60, 1000), 60, 1e-6)
	assertEquals(CameraRig.smooth(config, 12, 60, 0 / 0), 12)
	assertEquals(CameraRig.smooth(config, 12, 60, -1), 12)
end)

test("CameraRig: the death view hovers high above the arena at a fixed distance", function()
	for _, seconds in { 0, 1, 7.5, 30 } do
		local x, y, z = CameraRig.deathView(config, seconds)
		assertEquals(y, 200)
		assertNear(math.sqrt(x * x + z * z), 100, 1e-9)
	end
end)

test("CameraRig: the death view starts at the same place and turns over time", function()
	local x0, _, z0 = CameraRig.deathView(config, 0)
	assertNear(x0, 0, 1e-9)
	assertNear(z0, 100, 1e-9)
	local x1, _, z1 = CameraRig.deathView(config, 1)
	assertTrue(math.abs(x1 - x0) > 1 or math.abs(z1 - z0) > 1, "the view moves")
	local bx, by, bz = CameraRig.deathView(config, 0 / 0)
	assertNear(bx, 0, 1e-9)
	assertEquals(by, 200)
	assertNear(bz, 100, 1e-9)
end)

test("CameraRig: the blend goes smoothly from 0 to 1 and stays inside", function()
	assertEquals(CameraRig.blend(config, 0), 0)
	assertEquals(CameraRig.blend(config, 2), 1)
	assertEquals(CameraRig.blend(config, 10), 1)
	assertEquals(CameraRig.blend(config, -3), 0)
	assertNear(CameraRig.blend(config, 1), 0.5, 1e-9)
	local previous = -1
	for step = 0, 20 do
		local value = CameraRig.blend(config, step / 10)
		assertTrue(value >= previous, "monotonic")
		previous = value
	end
	assertEquals(CameraRig.blend(config, 0 / 0), 1)
end)
