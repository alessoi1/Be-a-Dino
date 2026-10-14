--!strict
local Framework = require("../Framework")
local Frenzy = require("../../src/shared/Frenzy")
local FrenzyConfig = require("../../src/shared/Config/Frenzy")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertTrue = Framework.assertTrue

local config: Frenzy.Config = { calmSeconds = 100, durationSeconds = 20, firstCalmSeconds = 30, pointsFactor = 2 }

test("Frenzy: no frenzy during the first calm period", function()
	local phase = Frenzy.phase(10, config)
	assertTrue(not phase.active)
	assertEquals(phase.secondsToNext, 20)
	assertEquals(phase.secondsLeft, 0)
end)

test("Frenzy: the first frenzy starts after the first calm period", function()
	local phase = Frenzy.phase(30, config)
	assertTrue(phase.active)
	assertEquals(phase.secondsLeft, 20)
	assertEquals(phase.secondsToNext, 0)
	assertEquals(Frenzy.phase(45, config).secondsLeft, 5)
end)

test("Frenzy: calm period after a frenzy, then the next one", function()
	local calm = Frenzy.phase(50, config)
	assertTrue(not calm.active)
	assertEquals(calm.secondsToNext, 100)
	assertTrue(Frenzy.phase(150, config).active, "second frenzy starts 120 seconds after the first")
	assertTrue(not Frenzy.phase(149.9, config).active)
end)

test("Frenzy: invalid input gives no frenzy", function()
	assertTrue(not Frenzy.phase(-1, config).active)
	assertTrue(not Frenzy.phase(0 / 0, config).active)
	local broken: Frenzy.Config = { calmSeconds = 0, durationSeconds = 20, firstCalmSeconds = 0, pointsFactor = 2 }
	assertTrue(not Frenzy.phase(100, broken).active)
end)

test("Frenzy: the factor is 1 outside a frenzy", function()
	assertEquals(Frenzy.factor(Frenzy.phase(10, config), config), 1)
	assertEquals(Frenzy.factor(Frenzy.phase(35, config), config), 2)
	local noBonus: Frenzy.Config = { calmSeconds = 100, durationSeconds = 20, firstCalmSeconds = 0, pointsFactor = 1 }
	assertEquals(Frenzy.factor(Frenzy.phase(5, noBonus), noBonus), 1)
end)

test("Frenzy: the real config is valid", function()
	local errors = Frenzy.validate(FrenzyConfig)
	assertEquals(#errors, 0, table.concat(errors, "; "))
end)

test("Frenzy: a broken config is reported", function()
	assertTrue(#Frenzy.validate({ calmSeconds = 0, durationSeconds = 5, firstCalmSeconds = 0, pointsFactor = 2 }) > 0)
	assertTrue(#Frenzy.validate({ calmSeconds = 5, durationSeconds = 5, firstCalmSeconds = -1, pointsFactor = 2 }) > 0)
	assertTrue(#Frenzy.validate({ calmSeconds = 5, durationSeconds = 5, firstCalmSeconds = 0, pointsFactor = 0.5 }) > 0)
end)
