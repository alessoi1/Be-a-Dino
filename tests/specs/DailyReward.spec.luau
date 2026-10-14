--!strict
local Framework = require("../Framework")
local Daily = require("../../src/shared/Config/Daily")
local DailyReward = require("../../src/shared/DailyReward")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertTrue = Framework.assertTrue

test("DailyReward: the day number follows the server time", function()
	assertEquals(DailyReward.dayOf(0, 86400), 0)
	assertEquals(DailyReward.dayOf(86399, 86400), 0)
	assertEquals(DailyReward.dayOf(86400, 86400), 1)
	assertEquals(DailyReward.dayOf(-5, 86400), 0)
	assertEquals(DailyReward.dayOf(10, 0), 0)
	assertEquals(DailyReward.dayOf(0 / 0, 86400), 0)
end)

test("DailyReward: the first claim starts the streak at day 1", function()
	local status = DailyReward.status(0, 0, 20000)
	assertTrue(status.canClaim)
	assertEquals(status.nextStreak, 1)
end)

test("DailyReward: the next day continues the streak", function()
	local status = DailyReward.status(20000, 3, 20001)
	assertTrue(status.canClaim)
	assertEquals(status.nextStreak, 4)
end)

test("DailyReward: a missed day starts the streak again", function()
	local status = DailyReward.status(20000, 5, 20002)
	assertTrue(status.canClaim)
	assertEquals(status.nextStreak, 1)
end)

test("DailyReward: nothing to claim twice on the same day or when the clock went back", function()
	assertTrue(not DailyReward.status(20000, 2, 20000).canClaim)
	assertTrue(not DailyReward.status(20000, 2, 19990).canClaim)
end)

test("DailyReward: invalid input gives no gift", function()
	assertTrue(not DailyReward.status(0 / 0, 1, 5).canClaim)
	assertTrue(not DailyReward.status(0, 0, 0).canClaim)
end)

test("DailyReward: the reward list cycles after the last day", function()
	local rewards = { 10, 20, 30 }
	assertEquals(DailyReward.reward(1, rewards), 10)
	assertEquals(DailyReward.reward(3, rewards), 30)
	assertEquals(DailyReward.reward(4, rewards), 10)
	assertEquals(DailyReward.reward(7, rewards), 10)
	assertEquals(DailyReward.reward(0, rewards), 10, "invalid streak falls back to day 1")
	assertEquals(DailyReward.reward(1, {}), 0)
end)

test("DailyReward: the real config is valid", function()
	local errors = DailyReward.validate(Daily)
	assertEquals(#errors, 0, table.concat(errors, "; "))
end)

test("DailyReward: a broken config is reported", function()
	assertTrue(#DailyReward.validate({ rewards = {}, secondsPerDay = 86400 }) > 0)
	assertTrue(#DailyReward.validate({ rewards = { 0 }, secondsPerDay = 86400 }) > 0)
	assertTrue(#DailyReward.validate({ rewards = { 5 }, secondsPerDay = 0 }) > 0)
end)
