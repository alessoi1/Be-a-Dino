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

test("ProfileData: a new profile has empty variant lists", function()
	local data = ProfileData.new(1)
	assertEquals(next(data.variants), nil)
	assertEquals(next(data.equippedVariants), nil)
end)

test("ProfileData: validate rejects broken variant fields", function()
	local function rejects(change: (data: any) -> (), label: string)
		local data: any = ProfileData.new(1000)
		change(data)
		assertTrue(not ProfileData.validate(data, Profile), label)
	end
	rejects(function(data)
		data.variants = "none"
	end, "variants type")
	rejects(function(data)
		data.variants = { compy = "gold" }
	end, "variants of a dino must be a table")
	rejects(function(data)
		data.variants = { compy = { gold = "yes" } }
	end, "variant value")
	rejects(function(data)
		data.variants = { [1] = { gold = true } }
	end, "variants key")
	rejects(function(data)
		data.equippedVariants = { compy = 5 }
	end, "equippedVariants value")
	rejects(function(data)
		data.equippedVariants = { [1] = "gold" }
	end, "equippedVariants key")
	rejects(function(data)
		local owned = {}
		for index = 1, Profile.maxVariantsPerDino + 1 do
			owned["variant" .. index] = true
		end
		data.variants = { compy = owned }
	end, "too many variants for one dino")
	rejects(function(data)
		for index = 1, Profile.maxVariantDinos + 1 do
			data.variants["dino" .. index] = { gold = true }
		end
	end, "variants for too many dinos")
	rejects(function(data)
		for index = 1, Profile.maxVariantDinos + 1 do
			data.equippedVariants["dino" .. index] = "gold"
		end
	end, "too many equipped variants")
	local ok: any = ProfileData.new(1000)
	ok.variants = { compy = { gold = true, rainbow = true } }
	ok.equippedVariants = { compy = "gold" }
	assertTrue((ProfileData.validate(ok, Profile)))
end)

test("ProfileData: a version 1 profile is migrated to the current version", function()
	local raw: any = { version = 1, createdAt = 50, reachedStages = { compy = true, raptor = true }, bestPoints = 7 }
	local migrated = ProfileData.migrate(raw, Migrations, ProfileData.VERSION)
	assertTrue(migrated ~= nil)
	local data: any = migrated
	assertEquals(data.version, ProfileData.VERSION)
	assertEquals(data.bestPoints, 7)
	assertTrue(data.reachedStages.raptor)
	assertTrue(data.variants ~= nil and data.equippedVariants ~= nil)
	assertTrue((ProfileData.validate(data, Profile)))
	assertEquals(raw.version, 1, "input stays untouched")
	assertEquals(raw.variants, nil)
end)

test("ProfileData: a new profile has no coins and invalid coins are rejected", function()
	assertEquals(ProfileData.new(1).coins, 0)
	local function rejects(value: any)
		local data: any = ProfileData.new(1)
		data.coins = value
		assertTrue(not ProfileData.validate(data, Profile), tostring(value))
	end
	rejects(-1)
	rejects(0 / 0)
	rejects(1.5)
	rejects("5")
	rejects(Profile.maxCoins + 1)
	local data: any = ProfileData.new(1)
	data.coins = Profile.maxCoins
	assertTrue((ProfileData.validate(data, Profile)))
end)

test("ProfileData: a version 2 profile is migrated and keeps everything", function()
	local raw: any = {
		version = 2,
		createdAt = 9,
		reachedStages = { compy = true },
		bestPoints = 12,
		ownedSkins = { compy_berry = true },
		equippedSkins = { compy = "compy_berry" },
	}
	local migrated: any = ProfileData.migrate(raw, Migrations, ProfileData.VERSION)
	assertTrue(migrated ~= nil)
	assertEquals(migrated.version, ProfileData.VERSION)
	assertEquals(migrated.coins, 0)
	assertEquals(migrated.bestPoints, 12)
	assertEquals(migrated.ownedSkins, nil, "the old skin fields are gone")
	assertEquals(migrated.equippedSkins, nil)
	assertTrue(migrated.variants ~= nil and migrated.equippedVariants ~= nil)
	assertEquals(raw.version, 2, "input stays untouched")
	assertEquals(raw.coins, nil)
	assertTrue((ProfileData.validate(migrated, Profile)))
end)

test("ProfileData: a new profile has no kills and no play time", function()
	local data = ProfileData.new(1)
	assertEquals(data.kills, 0)
	assertEquals(data.playSeconds, 0)
end)

test("ProfileData: invalid statistics are rejected", function()
	for _, field in { "kills", "playSeconds" } do
		for _, value in { -1, 0 / 0, 1.5, "5", Profile.maxStat + 1 } do
			local data: any = ProfileData.new(1)
			data[field] = value
			assertTrue(not ProfileData.validate(data, Profile), field .. " " .. tostring(value))
		end
		local ok: any = ProfileData.new(1)
		ok[field] = Profile.maxStat
		assertTrue((ProfileData.validate(ok, Profile)), field .. " at the limit")
	end
end)

test("ProfileData: a version 3 profile is migrated and keeps everything", function()
	local raw: any = {
		version = 3,
		createdAt = 9,
		reachedStages = { compy = true },
		bestPoints = 12,
		ownedSkins = {},
		equippedSkins = {},
		coins = 77,
	}
	local migrated: any = ProfileData.migrate(raw, Migrations, ProfileData.VERSION)
	assertTrue(migrated ~= nil)
	assertEquals(migrated.version, ProfileData.VERSION)
	assertEquals(migrated.coins, 77)
	assertEquals(migrated.kills, 0)
	assertEquals(migrated.playSeconds, 0)
	assertEquals(raw.kills, nil, "input stays untouched")
	assertTrue((ProfileData.validate(migrated, Profile)))
end)

test("ProfileData: a version 4 profile is migrated, the skin fields are dropped", function()
	local raw: any = {
		version = 4,
		createdAt = 9,
		reachedStages = { compy = true },
		bestPoints = 12,
		ownedSkins = { compy_berry = true },
		equippedSkins = { compy = "compy_berry" },
		coins = 40,
		kills = 3,
		playSeconds = 600,
	}
	local migrated: any = ProfileData.migrate(raw, Migrations, ProfileData.VERSION)
	assertTrue(migrated ~= nil)
	assertEquals(migrated.version, ProfileData.VERSION)
	assertEquals(migrated.coins, 40)
	assertEquals(migrated.kills, 3)
	assertEquals(migrated.ownedSkins, nil)
	assertEquals(next(migrated.variants), nil)
	assertEquals(raw.ownedSkins.compy_berry, true, "input stays untouched")
	assertTrue((ProfileData.validate(migrated, Profile)))
end)

test("ProfileData: a new profile has empty offer fields", function()
	local data = ProfileData.new(1)
	assertEquals(next(data.potionSeconds), nil)
	assertEquals(next(data.credits), nil)
	assertEquals(#data.receipts, 0)
end)

test("ProfileData: validate rejects broken offer fields", function()
	local function rejects(change: (data: any) -> (), label: string)
		local data: any = ProfileData.new(1000)
		change(data)
		assertTrue(not ProfileData.validate(data, Profile), label)
	end
	rejects(function(data)
		data.potionSeconds = "none"
	end, "potionSeconds type")
	rejects(function(data)
		data.potionSeconds = { growth = 0 }
	end, "potion seconds must be above 0")
	rejects(function(data)
		data.potionSeconds = { growth = Profile.maxPotionSeconds + 1 }
	end, "potion seconds above the limit")
	rejects(function(data)
		data.potionSeconds = { growth = 0 / 0 }
	end, "potion seconds nan")
	rejects(function(data)
		data.potionSeconds = { [1] = 5 }
	end, "potion key")
	rejects(function(data)
		data.credits = { revive = 1.5 }
	end, "credit count whole")
	rejects(function(data)
		data.credits = { revive = 0 }
	end, "credit count at least 1")
	rejects(function(data)
		data.credits = { revive = Profile.maxCredits + 1 }
	end, "credit above the limit")
	rejects(function(data)
		data.receipts = { 5 }
	end, "receipt must be text")
	rejects(function(data)
		data.receipts = "none"
	end, "receipts type")
	rejects(function(data)
		local list = {}
		for index = 1, Profile.maxReceipts + 1 do
			list[index] = "p" .. index
		end
		data.receipts = list
	end, "too many receipts")
	rejects(function(data)
		data.receipts = { string.rep("x", Profile.maxReceiptLength + 1) }
	end, "receipt too long")
	rejects(function(data)
		data.receipts = { [1] = "a", [3] = "b" }
	end, "receipts with a gap")
	local ok: any = ProfileData.new(1000)
	ok.potionSeconds = { growth = 300 }
	ok.credits = { revive = 2 }
	ok.receipts = { "a", "b" }
	assertTrue((ProfileData.validate(ok, Profile)))
end)

test("ProfileData: a version 5 profile is migrated and keeps everything", function()
	local raw: any = {
		version = 5,
		createdAt = 9,
		reachedStages = { compy = true },
		bestPoints = 12,
		variants = { compy = { gold = true } },
		equippedVariants = { compy = "gold" },
		coins = 40,
		kills = 3,
		playSeconds = 600,
	}
	local migrated: any = ProfileData.migrate(raw, Migrations, ProfileData.VERSION)
	assertTrue(migrated ~= nil)
	assertEquals(migrated.version, ProfileData.VERSION)
	assertEquals(migrated.coins, 40)
	assertEquals(migrated.variants.compy.gold, true)
	assertEquals(next(migrated.potionSeconds), nil)
	assertEquals(#migrated.receipts, 0)
	assertEquals(raw.potionSeconds, nil, "input stays untouched")
	assertTrue((ProfileData.validate(migrated, Profile)))
end)

test("ProfileData: a version 6 profile is migrated and gets the daily reward fields", function()
	local raw: any = {
		version = 6,
		createdAt = 9,
		reachedStages = { compy = true },
		bestPoints = 12,
		variants = {},
		equippedVariants = {},
		coins = 40,
		kills = 3,
		playSeconds = 600,
		potionSeconds = {},
		credits = {},
		receipts = {},
	}
	local migrated: any = ProfileData.migrate(raw, Migrations, ProfileData.VERSION)
	assertTrue(migrated ~= nil)
	assertEquals(migrated.version, ProfileData.VERSION)
	assertEquals(migrated.coins, 40)
	assertEquals(migrated.dailyClaimDay, 0)
	assertEquals(migrated.dailyStreak, 0)
	assertEquals(raw.dailyClaimDay, nil, "input stays untouched")
	assertTrue((ProfileData.validate(migrated, Profile)))
	migrated.dailyStreak = -1
	assertTrue(not (ProfileData.validate(migrated, Profile)), "a negative streak is invalid")
end)

test("ProfileData: a version 7 profile is migrated and gets empty daily quests", function()
	local raw: any = {
		version = 7,
		createdAt = 9,
		reachedStages = {},
		bestPoints = 0,
		variants = {},
		equippedVariants = {},
		coins = 5,
		kills = 0,
		playSeconds = 0,
		potionSeconds = {},
		credits = {},
		receipts = {},
		dailyClaimDay = 20000,
		dailyStreak = 3,
	}
	local migrated: any = ProfileData.migrate(raw, Migrations, ProfileData.VERSION)
	assertTrue(migrated ~= nil)
	assertEquals(migrated.version, ProfileData.VERSION)
	assertEquals(migrated.dailyStreak, 3)
	assertEquals(migrated.quests.day, 0)
	assertEquals(next(migrated.quests.progress), nil)
	assertEquals(raw.quests, nil, "input stays untouched")
	assertTrue((ProfileData.validate(migrated, Profile)))
	migrated.quests.progress = { a = 1.5 }
	assertTrue(not (ProfileData.validate(migrated, Profile)), "a fractional progress is invalid")
	migrated.quests.progress = {}
	migrated.quests.claimed = { a = false }
	assertTrue(not (ProfileData.validate(migrated, Profile)), "claimed holds only true")
	migrated.quests.claimed = {}
	migrated.quests.day = -1
	assertTrue(not (ProfileData.validate(migrated, Profile)), "a negative day is invalid")
end)
