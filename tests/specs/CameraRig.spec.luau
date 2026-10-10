--!strict
local CameraRig = require("../../src/shared/CameraRig")
local Framework = require("../Framework")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertNear = Framework.assertNear
local assertTrue = Framework.assertTrue

local config: CameraRig.Config = { distancePerScale = 12, minDistance = 10, smoothing = 5 }

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
