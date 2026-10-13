--!strict
local Framework = require("../Framework")
local FoodEffect = require("../../src/shared/FoodEffect")
local EffectConfig = require("../../src/shared/Config/FoodEffects")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertTrue = Framework.assertTrue

test("FoodEffect: more valuable food gives more particles, within the limits", function()
	local small = FoodEffect.emitCount(EffectConfig, 1)
	local medium = FoodEffect.emitCount(EffectConfig, 3)
	local large = FoodEffect.emitCount(EffectConfig, 10)
	assertEquals(small, EffectConfig.emitBase)
	assertTrue(medium > small and large > medium, "grows with the value")
	assertEquals(FoodEffect.emitCount(EffectConfig, 1e12), EffectConfig.emitMax)
end)

test("FoodEffect: invalid values give the base number", function()
	assertEquals(FoodEffect.emitCount(EffectConfig, 0), EffectConfig.emitBase)
	assertEquals(FoodEffect.emitCount(EffectConfig, -5), EffectConfig.emitBase)
	assertEquals(FoodEffect.emitCount(EffectConfig, 0 / 0), EffectConfig.emitBase)
	assertEquals(FoodEffect.emitCount(EffectConfig, math.huge), EffectConfig.emitBase)
end)

test("FoodEffect: at most so many effects per second, then a new second starts", function()
	local window = FoodEffect.newWindow()
	for _ = 1, 3 do
		assertTrue(FoodEffect.allow(window, 10, 3))
	end
	assertTrue(not FoodEffect.allow(window, 10.5, 3), "the fourth in the same second")
	assertTrue(FoodEffect.allow(window, 11.01, 3), "the next second")
end)

test("FoodEffect: bad clocks and limits do not break it", function()
	local window = FoodEffect.newWindow()
	assertTrue(not FoodEffect.allow(window, 0 / 0, 3))
	assertTrue(not FoodEffect.allow(window, 5, 0))
	assertTrue(FoodEffect.allow(window, 5, 1))
	assertTrue(FoodEffect.allow(window, 1, 1), "a clock that went backwards starts again")
end)

test("FoodEffect: the config is usable", function()
	assertTrue(EffectConfig.emitMax >= EffectConfig.emitBase)
	assertTrue(EffectConfig.pitchMax >= EffectConfig.pitchMin)
	assertTrue(EffectConfig.maxPerSecond > 0 and EffectConfig.effectRange > 0 and EffectConfig.hintSeconds > 0)
end)
