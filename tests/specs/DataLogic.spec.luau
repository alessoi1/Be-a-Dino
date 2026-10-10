--!strict
local Framework = require("../Framework")
local DataLogic = require("../../src/server/DataLogic")
local ProfileData = require("../../src/server/ProfileData")
local Migrations = require("../../src/server/Migrations")
local Profile = require("../../src/shared/Config/Profile")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertTrue = Framework.assertTrue

test("DataLogic: profileKey accepts only positive whole numbers", function()
	assertEquals(DataLogic.profileKey(12345), "Player_12345")
	assertEquals(DataLogic.profileKey(0), nil)
	assertEquals(DataLogic.profileKey(-3), nil)
	assertEquals(DataLogic.profileKey(1.5), nil)
	assertEquals(DataLogic.profileKey(0 / 0), nil)
	assertEquals(DataLogic.profileKey(math.huge), nil)
	assertEquals(DataLogic.profileKey("7" :: any), nil)
end)

test("DataLogic: an empty table gives a new profile", function()
	local outcome = DataLogic.prepare({}, ProfileData, Migrations, 500, Profile)
	assertEquals(outcome.status, "new")
	assertTrue(outcome.data ~= nil)
	assertEquals((outcome.data :: any).createdAt, 500)
end)

test("DataLogic: a valid current profile is loaded as it is", function()
	local raw = ProfileData.new(10)
	raw.bestPoints = 42
	local outcome = DataLogic.prepare(raw, ProfileData, Migrations, 500, Profile)
	assertEquals(outcome.status, "loaded")
	assertEquals((outcome.data :: any).bestPoints, 42)
end)

test("DataLogic: an older profile is migrated", function()
	local api = {
		VERSION = 2,
		new = ProfileData.new,
		validate = function(data: any)
			return type(data) == "table" and data.version == 2 and data.extra == true, "invalid"
		end,
		migrate = ProfileData.migrate,
	}
	local migrations: { ProfileData.Migration } = {
		function(data)
			data.version = 2
			data.extra = true
			return data
		end,
	}
	local outcome = DataLogic.prepare({ version = 1 }, api :: any, migrations, 500, Profile)
	assertEquals(outcome.status, "migrated")
	assertEquals((outcome.data :: any).extra, true)
end)

test("DataLogic: newer, corrupt or invalid data is rejected and not changed", function()
	local newer = { version = 99, keep = "me" }
	local outcome = DataLogic.prepare(newer, ProfileData, Migrations, 500, Profile)
	assertEquals(outcome.status, "rejected")
	assertEquals(outcome.data, nil)
	assertTrue(outcome.reason ~= nil)
	assertEquals(newer.keep, "me")

	local notTable = DataLogic.prepare("junk" :: any, ProfileData, Migrations, 500, Profile)
	assertEquals(notTable.status, "rejected")

	local invalid = ProfileData.new(1)
	invalid.bestPoints = -5
	assertEquals(DataLogic.prepare(invalid, ProfileData, Migrations, 500, Profile).status, "rejected")
end)

test("DataLogic: replaceContents keeps the same table and copies deeply", function()
	local target: any = { old = 1, nested = { a = 1 } }
	local source: any = { fresh = 2, nested = { b = 3 } }
	DataLogic.replaceContents(target, source)
	assertEquals(target.old, nil)
	assertEquals(target.fresh, 2)
	assertEquals(target.nested.b, 3)
	source.nested.b = 99
	assertEquals(target.nested.b, 3, "deep copy")
end)
