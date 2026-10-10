--!strict
local Framework = require("../Framework")
local Log = require("../../src/shared/Log")
local RejectLimiter = require("../../src/server/RejectLimiter")

local test = Framework.test
local assertEquals = Framework.assertEquals

type Entry = { message: string, context: Log.Context? }

local function fakeLogger(entries: { Entry }): Log.Logger
	local function record(message: string, context: Log.Context?)
		table.insert(entries, { message = message, context = context })
	end
	local noop = function() end
	return { debug = noop, info = noop, warn = record, error = noop }
end

test("the same reason is logged once per interval and user", function()
	local entries: { Entry } = {}
	local now = 0
	local limiter = RejectLimiter.new(fakeLogger(entries), 5, function()
		return now
	end)
	limiter.reject(1, "Sell", "too_far")
	limiter.reject(1, "Sell", "too_far")
	assertEquals(#entries, 1)
	now = 5
	limiter.reject(1, "Sell", "too_far")
	assertEquals(#entries, 2)
end)

test("other reasons and other users are logged on their own", function()
	local entries: { Entry } = {}
	local limiter = RejectLimiter.new(fakeLogger(entries), 5, function()
		return 0
	end)
	limiter.reject(1, "Sell", "too_far")
	limiter.reject(1, "Sell", "cooldown")
	limiter.reject(2, "Sell", "too_far")
	assertEquals(#entries, 3)
end)

test("the log entry names remote, user and reason", function()
	local entries: { Entry } = {}
	local limiter = RejectLimiter.new(fakeLogger(entries), 5, function()
		return 0
	end)
	limiter.reject(42, "BuyUpgrade", "bad_id")
	local context = entries[1].context :: Log.Context
	assertEquals(context.remote, "BuyUpgrade")
	assertEquals(context.userId, 42)
	assertEquals(context.reason, "bad_id")
end)

test("forget clears the memory of a user", function()
	local entries: { Entry } = {}
	local limiter = RejectLimiter.new(fakeLogger(entries), 5, function()
		return 0
	end)
	limiter.reject(1, "Sell", "too_far")
	limiter.forget(1)
	limiter.reject(1, "Sell", "too_far")
	assertEquals(#entries, 2)
end)
