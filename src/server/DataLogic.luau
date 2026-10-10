--!strict
-- Pure decisions of the DataService: profile keys and what to do with the data
-- ProfileStore returned. The profile module is passed in, so this file needs no
-- requires. No Roblox services, no logging; the DataService logs the outcome.

export type Status = "new" | "loaded" | "migrated" | "rejected"

-- `data` is set for every status except "rejected". A rejected profile must stay
-- untouched in the DataStore (never overwrite data we cannot read).
export type Outcome = {
	status: Status,
	data: any?,
	reason: string?,
}

-- What DataLogic needs from ProfileData (passed in).
export type Api = {
	VERSION: number,
	new: (now: number) -> any,
	validate: (data: any, limits: any) -> (boolean, string?),
	migrate: (raw: any, migrations: any, targetVersion: number) -> (any?, string?),
}

local KEY_PREFIX = "Player_"

local DataLogic = {}

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

local function rejected(reason: string?): Outcome
	return { status = "rejected", data = nil, reason = reason }
end

-- DataStore key for a player, or nil when the user id is not a positive integer.
function DataLogic.profileKey(userId: number): string?
	if type(userId) ~= "number" or userId ~= userId or userId < 1 or userId == math.huge or userId % 1 ~= 0 then
		return nil
	end
	return KEY_PREFIX .. string.format("%d", userId)
end

-- Decides what to do with the stored data of a player:
--   empty table -> "new" profile, current format
--   current or older valid profile -> "loaded" / "migrated"
--   anything else -> "rejected" with a reason (corrupt, newer version, failing migration)
-- The input is never modified.
function DataLogic.prepare(raw: any, api: Api, migrations: any, now: number, limits: any): Outcome
	if type(raw) ~= "table" then
		return rejected("stored data must be a table")
	end

	if next(raw) == nil then
		local profile = api.new(now)
		local ok, reason = api.validate(profile, limits)
		if not ok then
			return rejected("new profile is invalid: " .. tostring(reason))
		end
		return { status = "new", data = profile, reason = nil }
	end

	local migrated, migrateReason = api.migrate(raw, migrations, api.VERSION)
	if migrated == nil then
		return rejected(migrateReason)
	end

	local ok, reason = api.validate(migrated, limits)
	if not ok then
		return rejected(reason)
	end

	local status: Status = if raw.version == api.VERSION then "loaded" else "migrated"
	return { status = status, data = migrated, reason = nil }
end

-- Replaces everything in `target` with a copy of `source`, keeping the same table
-- (ProfileStore holds on to Profile.Data).
function DataLogic.replaceContents(target: { [any]: any }, source: { [any]: any })
	for key in target do
		target[key] = nil
	end
	for key, value in source do
		target[key] = deepCopy(value)
	end
end

return DataLogic
