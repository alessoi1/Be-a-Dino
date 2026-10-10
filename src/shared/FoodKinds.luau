--!strict
-- Pure helpers for the food kinds: weighted choice and config validation.
-- Randomness is passed in. No Roblox services, no logging.

export type Kind = {
	id: string,
	value: number,
	weight: number,
	size: number,
	color: { r: number, g: number, b: number },
}

local FoodKinds = {}

-- Index of the kind for `roll` in [0, 1). Out of range or invalid rolls are clamped.
function FoodKinds.pick(kinds: { Kind }, roll: number): number
	if roll ~= roll or roll < 0 then
		roll = 0
	end
	local total = 0
	for _, kind in kinds do
		total += kind.weight
	end
	local target = roll * total
	local cumulative = 0
	for index, kind in kinds do
		cumulative += kind.weight
		if target < cumulative then
			return index
		end
	end
	return #kinds
end

-- Like pick, but with its own weights per kind id (a zone of the arena). Kinds without an
-- entry have no chance. Without any usable weight the normal weights are used.
function FoodKinds.pickWeighted(kinds: { Kind }, weights: { [string]: number }, roll: number): number
	if roll ~= roll or roll < 0 then
		roll = 0
	end
	local total = 0
	for _, kind in kinds do
		total += math.max(0, weights[kind.id] or 0)
	end
	if total <= 0 then
		return FoodKinds.pick(kinds, roll)
	end
	local target = roll * total
	local cumulative = 0
	local last = 1
	for index, kind in kinds do
		local weight = math.max(0, weights[kind.id] or 0)
		if weight > 0 then
			cumulative += weight
			last = index
			if target < cumulative then
				return index
			end
		end
	end
	return last
end

-- Returns a list of problems (empty when the config is usable).
function FoodKinds.validate(kinds: { Kind }): { string }
	local errors: { string } = {}
	if #kinds == 0 then
		table.insert(errors, "no food kinds")
	end
	local seen: { [string]: boolean } = {}
	for _, kind in kinds do
		if seen[kind.id] then
			table.insert(errors, "duplicate id " .. kind.id)
		end
		seen[kind.id] = true
		if kind.weight <= 0 then
			table.insert(errors, "weight must be positive for " .. kind.id)
		end
		if kind.value <= 0 then
			table.insert(errors, "value must be positive for " .. kind.id)
		end
		if kind.size <= 0 then
			table.insert(errors, "size must be positive for " .. kind.id)
		end
	end
	return errors
end

export type Zone = {
	radius: number,
	count: number,
	spawnClearance: number,
	weights: { [string]: number },
}

local function isFinite(value: any): boolean
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

-- Checks the round zones (disc around the arena center): they must fit into the arena, hold
-- only known kinds with usable weights, and not need more pieces than there are.
function FoodKinds.validateZones(
	kinds: { Kind },
	zones: { [string]: Zone },
	arenaSize: number,
	totalCount: number,
	margin: number
): { string }
	local errors: { string } = {}
	local known: { [string]: boolean } = {}
	for _, kind in kinds do
		known[kind.id] = true
	end

	local used = 0
	for name, zone in zones do
		local where = "zone " .. name
		if not isFinite(zone.radius) or zone.radius <= 0 then
			table.insert(errors, where .. ": radius must be above 0")
		elseif zone.radius + margin > arenaSize / 2 then
			table.insert(errors, where .. ": the disc does not fit into the arena")
		end
		if not isFinite(zone.count) or zone.count < 0 or zone.count % 1 ~= 0 then
			table.insert(errors, where .. ": count must be a whole number of 0 or more")
		else
			used += zone.count
		end
		if not isFinite(zone.spawnClearance) or zone.spawnClearance < 0 then
			table.insert(errors, where .. ": spawnClearance must be 0 or more")
		end

		local weightSum = 0
		for id, weight in zone.weights do
			if not known[id] then
				table.insert(errors, where .. ": weight for unknown kind " .. tostring(id))
			elseif not isFinite(weight) or weight < 0 then
				table.insert(errors, where .. ": weight of " .. id .. " must be 0 or more")
			else
				weightSum += weight
			end
		end
		if weightSum <= 0 then
			table.insert(errors, where .. ": needs at least one kind with a weight above 0")
		end
	end
	if used > totalCount then
		table.insert(errors, "zones need more pieces than the food count")
	end
	return errors
end

return FoodKinds
