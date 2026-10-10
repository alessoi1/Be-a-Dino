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

return FoodKinds
