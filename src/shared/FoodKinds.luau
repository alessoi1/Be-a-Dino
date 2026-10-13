--!strict
-- Pure helpers for the food kinds: weighted choice and config validation.
-- Randomness is passed in. No Roblox services, no logging.

export type Color = { r: number, g: number, b: number }
export type Vec = { x: number, y: number, z: number }

-- One look of a piece of food. All variants of a kind are worth the same; they only look different.
-- `shape` is the stand-in drawn from a simple form until `meshId` (a Roblox mesh, 0 = none yet)
-- is there. `scale` stretches the piece (times the size of the kind); `meshScale` is the scale of
-- the mesh itself.
export type Variant = {
	id: string,
	shape: string,
	meshId: number,
	meshScale: Vec,
	scale: Vec,
	color: Color,
	weight: number,
}

export type Kind = {
	id: string,
	value: number,
	weight: number,
	size: number,
	color: Color,
	variants: { Variant },
}

local SHAPES: { [string]: boolean } = { ball = true, block = true, cylinder = true, wedge = true }

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

-- Average value of a piece of food. Without `weights` the weights of the kinds count, with
-- `weights` (a zone) those per kind id.
function FoodKinds.averageValue(kinds: { Kind }, weights: { [string]: number }?): number
	local total = 0
	local sum = 0
	for _, kind in kinds do
		local weight = if weights ~= nil then math.max(0, weights[kind.id] or 0) else kind.weight
		total += weight
		sum += weight * kind.value
	end
	if total <= 0 then
		return 0
	end
	return sum / total
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

-- Index of the look of a piece of this kind for `roll` in [0, 1) (by the weights of the variants).
-- A kind without a usable variant gives 0; invalid rolls are clamped.
function FoodKinds.pickVariant(kind: Kind, roll: number): number
	if roll ~= roll or roll < 0 then
		roll = 0
	end
	local total = 0
	for _, variant in kind.variants do
		total += math.max(0, variant.weight)
	end
	if total <= 0 then
		return 0
	end
	local target = roll * total
	local cumulative = 0
	local last = 0
	for index, variant in kind.variants do
		local weight = math.max(0, variant.weight)
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

local function positiveVec(vec: Vec): boolean
	return vec.x > 0 and vec.y > 0 and vec.z > 0
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
		if #kind.variants == 0 then
			table.insert(errors, "no variants for " .. kind.id)
		end
		local variantIds: { [string]: boolean } = {}
		local variantWeight = 0
		for _, variant in kind.variants do
			local where = kind.id .. "/" .. variant.id
			if variantIds[variant.id] then
				table.insert(errors, "duplicate variant " .. where)
			end
			variantIds[variant.id] = true
			if not SHAPES[variant.shape] then
				table.insert(errors, "unknown shape for " .. where)
			end
			if variant.weight < 0 then
				table.insert(errors, "variant weight must not be negative for " .. where)
			end
			variantWeight += math.max(0, variant.weight)
			if not positiveVec(variant.scale) or not positiveVec(variant.meshScale) then
				table.insert(errors, "scale must be positive for " .. where)
			end
			if variant.meshId < 0 or variant.meshId % 1 ~= 0 then
				table.insert(errors, "meshId must be 0 or a whole number for " .. where)
			end
		end
		if #kind.variants > 0 and variantWeight <= 0 then
			table.insert(errors, "no variant has a weight for " .. kind.id)
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
	arenaRadius: number,
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
		elseif zone.radius + margin > arenaRadius then
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
