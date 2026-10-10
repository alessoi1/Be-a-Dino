--!strict
local Framework = require("../Framework")
local Log = require("../../src/shared/Log")

local test = Framework.test
local assertEquals = Framework.assertEquals

local function capture(): ({ { level: string, text: string } }, () -> ())
	local lines = {}
	local previous = Log.setSink(function(level: Log.Level, text: string)
		table.insert(lines, { level = level, text = text })
	end)
	return lines, function()
		Log.setSink(previous)
	end
end

test("log lines carry game name, tag and message", function()
	local lines, restore = capture()
	Log.new("Dig").info("block dug")
	restore()
	assertEquals(#lines, 1)
	assertEquals(lines[1].level, "info")
	assertEquals(lines[1].text, "[BeDino][Dig] block dug")
end)

test("context is appended as sorted key=value pairs", function()
	local lines, restore = capture()
	Log.new("Shop").warn("receipt rejected", { userId = 42, productId = 7, reason = "duplicate" })
	restore()
	assertEquals(lines[1].level, "warn")
	assertEquals(lines[1].text, "[BeDino][Shop] receipt rejected productId=7 reason=duplicate userId=42")
end)

test("error level is delivered as error", function()
	local lines, restore = capture()
	Log.new("Data").error("save failed", { userId = 1 })
	restore()
	assertEquals(lines[1].level, "error")
end)

test("debug lines are dropped unless debug is enabled", function()
	local lines, restore = capture()
	local logger = Log.new("Dig")
	logger.debug("hidden")
	Log.setDebugEnabled(true)
	logger.debug("shown")
	Log.setDebugEnabled(false)
	restore()
	assertEquals(#lines, 1)
	assertEquals(lines[1].text, "[BeDino][Dig] shown")
end)
