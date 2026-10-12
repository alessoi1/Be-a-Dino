--!strict
local Framework = require("../Framework")
local TimeFormat = require("../../src/shared/TimeFormat")

local test = Framework.test
local assertEquals = Framework.assertEquals

test("TimeFormat: seconds", function()
	assertEquals(TimeFormat.compact(0), "0s")
	assertEquals(TimeFormat.compact(1), "1s")
	assertEquals(TimeFormat.compact(45), "45s")
	assertEquals(TimeFormat.compact(59.9), "59s", "cut off")
end)

test("TimeFormat: minutes", function()
	assertEquals(TimeFormat.compact(60), "1m")
	assertEquals(TimeFormat.compact(750), "12m")
	assertEquals(TimeFormat.compact(3599), "59m")
end)

test("TimeFormat: hours and minutes", function()
	assertEquals(TimeFormat.compact(3600), "1h")
	assertEquals(TimeFormat.compact(3660), "1h 1m")
	assertEquals(TimeFormat.compact(12000), "3h 20m")
	assertEquals(TimeFormat.compact(86399), "23h 59m")
end)

test("TimeFormat: days and hours", function()
	assertEquals(TimeFormat.compact(86400), "1d")
	assertEquals(TimeFormat.compact(446400), "5d 4h")
	assertEquals(TimeFormat.compact(86400 * 30 + 3600 * 5 + 59), "30d 5h")
end)

test("TimeFormat: invalid input", function()
	assertEquals(TimeFormat.compact(-5), "0s")
	assertEquals(TimeFormat.compact(0 / 0), "0s")
	assertEquals(TimeFormat.compact(math.huge), "0s")
	assertEquals(TimeFormat.compact("5" :: any), "0s")
end)
