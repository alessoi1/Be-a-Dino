--!strict
local Animation = require("../../src/shared/Config/Animation")
local DinoAnim = require("../../src/shared/DinoAnim")
local Framework = require("../Framework")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertNear = Framework.assertNear
local assertTrue = Framework.assertTrue

local config = Animation

test("DinoAnim: the real config is valid", function()
	assertEquals(#DinoAnim.validate(config), 0)
end)

test("DinoAnim: bad values are reported", function()
	local bad = table.clone(config)
	bad.strideLength = 0
	bad.legSwing = 3
	bad.tailSwing = -1
	local errors = DinoAnim.validate(bad)
	assertEquals(#errors, 3)
	local tooFar = table.clone(config)
	tooFar.quadLegSwing = 2
	assertEquals(#DinoAnim.validate(tooFar), 1)
end)

test("DinoAnim: standing still gives no swing, full speed gives the full swing", function()
	assertEquals(DinoAnim.amount(config, 0), 0)
	assertEquals(DinoAnim.amount(config, config.standSpeed), 0)
	assertEquals(DinoAnim.amount(config, config.fullSpeed), 1)
	assertEquals(DinoAnim.amount(config, config.fullSpeed * 3), 1)
	assertNear(DinoAnim.amount(config, config.fullSpeed / 2), 0.5, 0.0001)
end)

test("DinoAnim: invalid speeds do not swing", function()
	assertEquals(DinoAnim.amount(config, 0 / 0), 0)
	assertEquals(DinoAnim.amount(config, -5), 0)
	assertEquals(DinoAnim.amount(config, math.huge), 0)
end)

test("DinoAnim: the step cycle advances with the distance walked", function()
	local state = DinoAnim.newState()
	-- Walking one full stride turns the phase once around, so it ends where it began.
	local after = DinoAnim.step(config, state, 10, 1, config.strideLength / 10)
	assertNear(after.phase, 0, 0.0001)
	local half = DinoAnim.step(config, state, 10, 1, config.strideLength / 10 / 2)
	assertNear(half.phase, math.pi, 0.0001)
end)

test("DinoAnim: running faster never takes quicker steps than the limit", function()
	local state = DinoAnim.newState()
	local dt = 0.01
	local limit = 2 * math.pi * config.maxCyclesPerSecond * dt
	local fast = DinoAnim.step(config, state, 33, 1, dt)
	local faster = DinoAnim.step(config, state, 300, 1, dt)
	assertNear(faster.phase, limit, 0.0001)
	assertTrue(fast.phase <= limit + 0.0001)
	-- Even a slow frame (10 fps) stays below a quarter cycle, so the limbs never skip across it.
	assertTrue(2 * math.pi * config.maxCyclesPerSecond * 0.1 < math.pi)
end)

test("DinoAnim: a bigger dino takes longer steps", function()
	local state = DinoAnim.newState()
	local small = DinoAnim.step(config, state, 10, 1, 0.1)
	local big = DinoAnim.step(config, state, 10, 2, 0.1)
	assertNear(big.phase * 2, small.phase, 0.0001)
end)

test("DinoAnim: standing still does not move the step cycle but runs the idle clock", function()
	local state = { phase = 1, idle = 0 }
	local after = DinoAnim.step(config, state, 0, 1, 0.5)
	assertEquals(after.phase, 1)
	assertNear(after.idle, 0.5, 0.0001)
end)

test("DinoAnim: the idle clock wraps around", function()
	local after = DinoAnim.step(config, { phase = 0, idle = config.tailIdleSeconds - 0.1 }, 0, 1, 0.3)
	assertTrue(after.idle < config.tailIdleSeconds)
	assertNear(after.idle, 0.2, 0.0001)
end)

test("DinoAnim: invalid time or scale leaves the state as it is", function()
	local state = { phase = 1, idle = 1 }
	assertEquals(DinoAnim.step(config, state, 10, 1, 0), state)
	assertEquals(DinoAnim.step(config, state, 10, 1, -1), state)
	assertEquals(DinoAnim.step(config, state, 10, 0, 0.1), state)
	assertEquals(DinoAnim.step(config, state, 10, 0 / 0, 0.1), state)
	assertEquals(DinoAnim.step(config, state, 10, 1, 0 / 0), state)
end)

test("DinoAnim: the legs swing against each other", function()
	local state = { phase = 1, idle = 0 }
	local left = DinoAnim.angle(config, state, "legLeft", 1)
	local right = DinoAnim.angle(config, state, "legRight", 1)
	assertNear(left, -right, 0.0001)
	assertTrue(math.abs(left) <= config.legSwing + 0.0001)
	assertTrue(math.abs(left) > 0)
end)

test("DinoAnim: the legs are straight when standing", function()
	local state = { phase = 1, idle = 0 }
	assertEquals(DinoAnim.angle(config, state, "legLeft", 0), 0)
	assertEquals(DinoAnim.angle(config, state, "legRight", 0), 0)
end)

test("DinoAnim: the swing never goes beyond the limit", function()
	for step = 0, 63 do
		local state = { phase = step / 64 * 2 * math.pi, idle = step / 64 * config.tailIdleSeconds }
		for _, amount in { 0, 0.3, 1, 5 } do
			assertTrue(math.abs(DinoAnim.angle(config, state, "legLeft", amount)) <= config.legSwing + 0.0001)
			assertTrue(
				math.abs(DinoAnim.angle(config, state, "tail", amount)) <= config.tailSwing + config.tailIdleSwing
			)
		end
	end
end)

test("DinoAnim: the tail sways slowly while standing and with the steps while walking", function()
	local early = DinoAnim.angle(config, { phase = 0, idle = config.tailIdleSeconds / 4 }, "tail", 0)
	assertNear(early, config.tailIdleSwing, 0.0001)
	local walking = DinoAnim.angle(config, { phase = math.pi / 2, idle = 0 }, "tail", 1)
	assertNear(walking, config.tailSwing, 0.0001)
end)

test("DinoAnim: an unknown limb does not move", function()
	assertEquals(DinoAnim.angle(config, DinoAnim.newState(), "wing", 1), 0)
end)

test("DinoAnim: the four-legged walk moves the legs across each other", function()
	local state = { phase = 1, idle = 0 }
	local frontLeft = DinoAnim.angle(config, state, "legFrontLeft", 1)
	local backRight = DinoAnim.angle(config, state, "legBackRight", 1)
	local frontRight = DinoAnim.angle(config, state, "legFrontRight", 1)
	local backLeft = DinoAnim.angle(config, state, "legBackLeft", 1)
	assertNear(frontLeft, backRight, 0.0001)
	assertNear(frontRight, backLeft, 0.0001)
	assertNear(frontLeft, -frontRight, 0.0001)
	assertTrue(math.abs(frontLeft) > 0)
	assertTrue(math.abs(frontLeft) <= config.quadLegSwing + 0.0001)
end)

test("DinoAnim: the four-legged legs are straight when standing", function()
	for _, limb in { "legFrontLeft", "legFrontRight", "legBackLeft", "legBackRight" } do
		assertEquals(DinoAnim.angle(config, { phase = 2, idle = 0 }, limb, 0), 0)
		assertTrue(DinoAnim.LIMBS[limb])
	end
end)

test("DinoAnim: bad values of the body motion are reported", function()
	local bad = table.clone(config)
	bad.eatSeconds = 0
	bad.breathLift = -1
	bad.eatPitch = 3
	assertEquals(#DinoAnim.validate(bad), 3)
end)

test("DinoAnim: the munch runs from 0 to 1 and then is over", function()
	assertEquals(DinoAnim.eatProgress(config, nil, 5), nil)
	assertEquals(DinoAnim.eatProgress(config, 5, 5), 0)
	assertNear(DinoAnim.eatProgress(config, 5, 5 + config.eatSeconds / 2) :: number, 0.5, 0.0001)
	assertEquals(DinoAnim.eatProgress(config, 5, 5 + config.eatSeconds + 0.001), nil)
	assertEquals(DinoAnim.eatProgress(config, 5, 4), nil, "a clock that went backwards")
	assertEquals(DinoAnim.eatProgress(config, 5, 0 / 0), nil)
end)

test("DinoAnim: standing the body breathes, rising and falling around the middle", function()
	local top = DinoAnim.bodyPose(config, { phase = 0, idle = config.tailIdleSeconds / 4 }, 0, nil)
	local bottom = DinoAnim.bodyPose(config, { phase = 0, idle = config.tailIdleSeconds * 3 / 4 }, 0, nil)
	assertNear(top.lift, config.breathLift, 0.0001)
	assertNear(bottom.lift, -config.breathLift, 0.0001)
	assertEquals(top.pitch, 0)
end)

test("DinoAnim: walking the body bobs twice per step and leans forward", function()
	local atZero = DinoAnim.bodyPose(config, { phase = 0, idle = 0 }, 1, nil)
	local atQuarter = DinoAnim.bodyPose(config, { phase = math.pi / 2, idle = 0 }, 1, nil)
	local atHalf = DinoAnim.bodyPose(config, { phase = math.pi, idle = 0 }, 1, nil)
	assertNear(atZero.lift, config.bobLift, 0.0001)
	assertNear(atQuarter.lift, -config.bobLift, 0.0001)
	assertNear(atHalf.lift, config.bobLift, 0.0001, "the second bob of the cycle")
	assertTrue(atZero.pitch < 0, "nose a little down")
end)

test("DinoAnim: munching nods down most in the middle and ends where it began", function()
	local state = { phase = 0, idle = 0 }
	local calm = DinoAnim.bodyPose(config, state, 0, nil)
	local start = DinoAnim.bodyPose(config, state, 0, 0)
	local middle = DinoAnim.bodyPose(config, state, 0, 0.5)
	local finish = DinoAnim.bodyPose(config, state, 0, 1)
	assertNear(start.pitch, calm.pitch, 0.0001)
	assertNear(finish.pitch, calm.pitch, 0.0001)
	assertNear(middle.pitch, calm.pitch - config.eatPitch, 0.0001)
	assertNear(middle.lift, calm.lift - config.eatDip, 0.0001)
end)

test("DinoAnim: the body joint is one of the animated limbs, and gets no angle of its own", function()
	assertTrue(DinoAnim.LIMBS.body == true)
	assertEquals(DinoAnim.angle(config, { phase = 1, idle = 1 }, "body", 1), 0)
end)
