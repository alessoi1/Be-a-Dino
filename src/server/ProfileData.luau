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
	-- Owned variants of the dinos: dino id -> variant id -> true (found in eggs).
	variants: { [string]: { [string]: boolean } },
	-- The variant shown on a dino: dino id -> variant id (no entry means the normal look).
	equippedVariants: { [string]: string },
	-- Coins earned by growing (never bought with Robux).
	coins: number,
	-- Players eaten in total.
	kills: number,
	-- Seconds in the arena in total (autofarm counts).
	playSeconds: number,
}

export type Limits = {
	maxReachedStages: number,
	maxVariantDinos: number,
	maxVariantsPerDino: number,
	maxCoins: number,
	maxStat: number,
}

-- Turns data of version n into data of version n + 1 (and sets `version`).
-- Gets a copy it may change.
export type Migration = (data: any) -> any

local ProfileData = {}

ProfileData.VERSION = 5

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
		variants = {},
		equippedVariants = {},
		coins = 0,
		kills = 0,
		playSeconds = 0,
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

	if type(data.variants) ~= "table" then
		return false, "variants must be a table"
	end
	local variantDinos = 0
	for dinoId, owned in data.variants do
		if type(dinoId) ~= "string" or type(owned) ~= "table" then
			return false, "variants holds only dino ids with a table"
		end
		local perDino = 0
		for variantId, has in owned do
			if type(variantId) ~= "string" or has ~= true then
				return false, "variants of a dino hold only variant ids set to true"
			end
			perDino += 1
		end
		if perDino > limits.maxVariantsPerDino then
			return false, "too many variants for one dino"
		end
		variantDinos += 1
	end
	if variantDinos > limits.maxVariantDinos then
		return false, "variants for too many dinos"
	end

	if type(data.equippedVariants) ~= "table" then
		return false, "equippedVariants must be a table"
	end
	local equipped = 0
	for dinoId, variantId in data.equippedVariants do
		if type(dinoId) ~= "string" or type(variantId) ~= "string" then
			return false, "equippedVariants holds only dino ids with variant ids"
		end
		equipped += 1
	end
	if equipped > limits.maxVariantDinos then
		return false, "too many equipped variants"
	end

	if not isFiniteNumber(data.coins) or data.coins < 0 or data.coins % 1 ~= 0 or data.coins > limits.maxCoins then
		return false, "coins must be a whole number between 0 and the limit"
	end

	for _, field in { "kills", "playSeconds" } do
		local value = data[field]
		if not isFiniteNumber(value) or value < 0 or value % 1 ~= 0 or value > limits.maxStat then
			return false, field .. " must be a whole number between 0 and the limit"
		end
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
