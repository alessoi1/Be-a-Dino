--!strict
local Framework = require("../Framework")
local ProfileData = require("../../src/server/ProfileData")
local Migrations = require("../../src/server/Migrations")
local Profile = require("../../src/shared/Config/Profile")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertTrue = Framework.assertTrue

test("ProfileData: a new profile is valid and has the current version", function()
	local data = ProfileData.new(1000)
	assertEquals(data.version, ProfileData.VERSION)
	assertEquals(data.createdAt, 1000)
	assertEquals(data.bestPoints, 0)
	local ok, reason = ProfileData.validate(data, Profile)
	assertTrue(ok, tostring(reason))
end)

test("ProfileData: validate rejects wrong types and values", function()
	local function rejects(change: (data: any) -> (), label: string)
		local data: any = ProfileData.new(1000)
		change(data)
		local ok = ProfileData.validate(data, Profile)
		assertTrue(not ok, label)
	end
	rejects(function(data)
		data.version = 99
	end, "wrong version")
	rejects(function(data)
		data.createdAt = "yesterday"
	end, "createdAt type")
	rejects(function(data)
		data.bestPoints = -1
	end, "negative best")
	rejects(function(data)
		data.bestPoints = 0 / 0
	end, "nan best")
	rejects(function(data)
		data.reachedStages = 5
	end, "reachedStages type")
	rejects(function(data)
		data.reachedStages = { compy = "yes" }
	end, "reachedStages value")
	rejects(function(data)
		data.reachedStages = { [1] = true }
	end, "reachedStages key")
end)

test("ProfileData: too many reached stages are rejected", function()
	local data: any = ProfileData.new(1000)
	for index = 1, 100 do
		data.reachedStages["stage" .. index] = true
	end
	assertTrue(not ProfileData.validate(data, Profile))
end)

test("ProfileData: the real migration list covers every old version", function()
	-- There is one migration per old version: version 1 needs none yet.
	assertEquals(#Migrations, ProfileData.VERSION - 1)
end)

test("ProfileData: migrate runs the steps in order and does not change the input", function()
	local calls: { number } = {}
	local migrations: { ProfileData.Migration } = {
		function(data)
			table.insert(calls, 1)
			data.version = 2
			data.addedInTwo = true
			return data
		end,
		function(data)
			table.insert(calls, 2)
			data.version = 3
			return data
		end,
	}
	local raw: any = { version = 1, createdAt = 5 }
	local result = ProfileData.migrate(raw, migrations, 3)
	assertTrue(result ~= nil)
	assertEquals((result :: any).version, 3)
	assertEquals((result :: any).addedInTwo, true)
	assertEquals(calls[1], 1)
	assertEquals(calls[2], 2)
	assertEquals(raw.version, 1, "input stays untouched")
	assertEquals(raw.addedInTwo, nil)
end)

test("ProfileData: migrate returns the data when it is already current", function()
	local raw: any = ProfileData.new(1)
	local result = ProfileData.migrate(raw, {}, ProfileData.VERSION)
	assertTrue(result ~= nil)
end)

test("ProfileData: a newer or invalid version is refused", function()
	local newer, reason = ProfileData.migrate({ version = 9 }, {}, 3)
	assertEquals(newer, nil)
	assertTrue(reason ~= nil)
	assertEquals((ProfileData.migrate({ version = 0 }, {}, 3)), nil)
	assertEquals((ProfileData.migrate({ version = 1.5 }, {}, 3)), nil)
	assertEquals((ProfileData.migrate({}, {}, 3)), nil)
end)

test("ProfileData: a failing or missing migration stops the load", function()
	local failing: { ProfileData.Migration } = {
		function(_data)
			error("boom")
		end,
	}
	assertEquals((ProfileData.migrate({ version = 1 }, failing, 2)), nil)
	assertEquals((ProfileData.migrate({ version = 1 }, {}, 2)), nil, "missing step")
	local wrongVersion: { ProfileData.Migration } = {
		function(data)
			return data
		end,
	}
	assertEquals((ProfileData.migrate({ version = 1 }, wrongVersion, 2)), nil, "step must set the next version")
end)
