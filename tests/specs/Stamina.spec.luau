--!strict
local Framework = require("../Framework")
local Stamina = require("../../src/shared/Stamina")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertNear = Framework.assertNear
local assertTrue = Framework.assertTrue

local config: Stamina.Config = {
	staminaMax = 100,
	staminaDrainPerSecond = 25,
	staminaRegenPerSecond = 15,
	staminaRegenDelay = 1,
	staminaMinToStart = 10,
}

test("Stamina: starts full and not sprinting", function()
	local state = Stamina.new(config)
	assertEquals(state.value, 100)
	assertTrue(not state.sprinting)
end)

test("Stamina: sprinting drains per second", function()
	local state, sprinting = Stamina.step(config, Stamina.new(config), true, 2)
	assertTrue(sprinting)
	assertNear(state.value, 50, 1e-9)
end)

test("Stamina: running out ends the sprint and stays at zero", function()
	local state, sprinting = Stamina.step(config, Stamina.new(config), true, 10)
	assertTrue(not sprinting)
	assertEquals(state.value, 0)
end)

test("Stamina: regrowth starts only after the delay", function()
	local state = Stamina.step(config, Stamina.new(config), true, 2)
	local s1 = Stamina.step(config, state, false, 1)
	assertNear(s1.value, 50, 1e-9, "still waiting")
	local s2 = Stamina.step(config, s1, false, 1)
	assertNear(s2.value, 65, 1e-9, "one second of regrowth")
end)

test("Stamina: delay boundary inside one big step", function()
	local state = Stamina.step(config, Stamina.new(config), true, 2)
	local after = Stamina.step(config, state, false, 1.5)
	assertNear(after.value, 50 + 0.5 * 15, 1e-9)
end)

test("Stamina: sprint cannot start below the minimum", function()
	local state: Stamina.State = { value = 9, idle = 5, sprinting = false }
	local after, sprinting = Stamina.step(config, state, true, 0.1)
	assertTrue(not sprinting)
	assertTrue(after.value >= 9, "no drain")
	local ok: Stamina.State = { value = 10, idle = 5, sprinting = false }
	local _, sprinting2 = Stamina.step(config, ok, true, 0.1)
	assertTrue(sprinting2)
end)

test("Stamina: a running sprint may continue below the minimum", function()
	local state: Stamina.State = { value = 5, idle = 0, sprinting = true }
	local after, sprinting = Stamina.step(config, state, true, 0.1)
	assertTrue(sprinting)
	assertNear(after.value, 2.5, 1e-9)
end)

test("Stamina: releasing stops the sprint and value never exceeds the maximum", function()
	local state = Stamina.step(config, Stamina.new(config), true, 1)
	local released, sprinting = Stamina.step(config, state, false, 100)
	assertTrue(not sprinting)
	assertEquals(released.value, 100)
end)

test("Stamina: invalid time steps leave the state unchanged", function()
	local state = Stamina.step(config, Stamina.new(config), true, 1)
	for _, dt in { -1, 0 / 0, math.huge } do
		local after, sprinting = Stamina.step(config, state, true, dt)
		assertEquals(after.value, state.value, "dt " .. tostring(dt))
		assertEquals(sprinting, state.sprinting)
	end
end)

test("Stamina: fraction is between 0 and 1", function()
	assertEquals(Stamina.fraction(config, { value = 50, idle = 0, sprinting = false }), 0.5)
	assertEquals(Stamina.fraction(config, { value = 500, idle = 0, sprinting = false }), 1)
end)
