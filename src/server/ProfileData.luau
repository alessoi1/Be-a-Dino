--!strict
-- The format of the saved player profile: new profile, validation and migration.
-- Pure: no Roblox services, no logging (the DataService logs the outcome).
-- Every change of the format raises VERSION, adds a migration (Migrations.luau) and a test.

export type Data = {
	version: number,
	-- Server time (os.time) when the profile was created.
	createdAt: number,
	-- Stage ids of the dinos the player has reached once (the collection).
	reachedStages: { [string]: boolean },
	-- Most points of a single round.
	bestPoints: number,
	-- Ids of the bought skins (free and earned skins are derived, not stored).
	ownedSkins: { [string]: boolean },
	-- The chosen skin id per dino id.
	equippedSkins: { [string]: string },
	-- Coins earned by growing (never bought with Robux).
	coins: number,
}

export type Limits = {
	maxReachedStages: number,
	maxOwnedSkins: number,
	maxEquippedSkins: number,
	maxCoins: number,
}

-- Turns data of version n into data of version n + 1 (and sets `version`).
-- Gets a copy it may change.
export type Migration = (data: any) -> any

local ProfileData = {}

ProfileData.VERSION = 3

local function isFiniteNumber(value: any): boolean
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function deepCopy(value: any): any
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for key, inner in value do
		copy[key] = deepCopy(inner)
	end
	return copy
end

function ProfileData.new(now: number): Data
	return {
		version = ProfileData.VERSION,
		createdAt = now,
		reachedStages = {},
		bestPoints = 0,
		ownedSkins = {},
		equippedSkins = {},
		coins = 0,
	}
end

-- Returns true, or false with the reason.
function ProfileData.validate(data: any, limits: Limits): (boolean, string?)
	if type(data) ~= "table" then
		return false, "profile must be a table"
	end
	if data.version ~= ProfileData.VERSION then
		return false, "wrong version"
	end
	if not isFiniteNumber(data.createdAt) or data.createdAt < 0 then
		return false, "createdAt must be a number"
	end
	if not isFiniteNumber(data.bestPoints) or data.bestPoints < 0 then
		return false, "bestPoints must be a number of at least 0"
	end
	if type(data.reachedStages) ~= "table" then
		return false, "reachedStages must be a table"
	end
	local count = 0
	for key, value in data.reachedStages do
		if type(key) ~= "string" or value ~= true then
			return false, "reachedStages holds only stage ids set to true"
		end
		count += 1
	end
	if count > limits.maxReachedStages then
		return false, "too many reached stages"
	end

	if type(data.ownedSkins) ~= "table" then
		return false, "ownedSkins must be a table"
	end
	local owned = 0
	for key, value in data.ownedSkins do
		if type(key) ~= "string" or value ~= true then
			return false, "ownedSkins holds only skin ids set to true"
		end
		owned += 1
	end
	if owned > limits.maxOwnedSkins then
		return false, "too many owned skins"
	end

	if type(data.equippedSkins) ~= "table" then
		return false, "equippedSkins must be a table"
	end
	local equipped = 0
	for key, value in data.equippedSkins do
		if type(key) ~= "string" or type(value) ~= "string" then
			return false, "equippedSkins holds only dino ids with skin ids"
		end
		equipped += 1
	end
	if equipped > limits.maxEquippedSkins then
		return false, "too many equipped skins"
	end

	if not isFiniteNumber(data.coins) or data.coins < 0 or data.coins % 1 ~= 0 or data.coins > limits.maxCoins then
		return false, "coins must be a whole number between 0 and the limit"
	end
	return true, nil
end

-- Brings stored data to `targetVersion`. The input is not changed. Returns nil with a
-- reason for a newer or invalid version and for a failing or missing migration.
function ProfileData.migrate(raw: any, migrations: { Migration }, targetVersion: number): (any?, string?)
	if type(raw) ~= "table" then
		return nil, "profile must be a table"
	end
	local version = raw.version
	if not isFiniteNumber(version) or version < 1 or version % 1 ~= 0 then
		return nil, "invalid version"
	end
	if version > targetVersion then
		return nil, "profile is newer than this server"
	end

	local data = deepCopy(raw)
	while data.version < targetVersion do
		local from = data.version
		local step = migrations[from]
		if step == nil then
			return nil, "no migration from version " .. from
		end
		local ok, result = pcall(step, data)
		if not ok then
			return nil, "migration from version " .. from .. " failed: " .. tostring(result)
		end
		if type(result) ~= "table" or result.version ~= from + 1 then
			return nil, "migration from version " .. from .. " did not produce version " .. (from + 1)
		end
		data = result
	end
	return data, nil
end

return ProfileData
