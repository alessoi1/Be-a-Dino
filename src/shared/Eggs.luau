--!strict
-- Pure egg rules: what an egg gives, the chances as percentages and the price. The random numbers
-- are passed in, so everything is testable. No Roblox services, no logging.

export type Config = {
	price: number,
	weights: { [string]: number },
	duplicateRefundShare: number,
	cooldownSeconds: number,
}

-- What an egg gave: a variant of a dino, and whether the player already had it.
export type Result = { dinoId: string, variantId: string, duplicate: boolean }

local Eggs = {}

local function isFinite(value: any): boolean
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function unitRoll(roll: number): number
	if not isFinite(roll) or roll < 0 then
		return 0
	end
	return math.min(roll, 1 - 1e-12)
end

-- The chances in percent by variant id, with one decimal, adding up to exactly 100. Variants
-- without a weight get 0.
function Eggs.percentages(weights: { [string]: number }, order: { string }): { [string]: number }
	local total = 0
	for _, id in order do
		total += math.max(0, weights[id] or 0)
	end
	local result: { [string]: number } = {}
	if total <= 0 then
		for _, id in order do
			result[id] = 0
		end
		return result
	end

	-- Largest remainder method in tenths of a percent.
	local units: { [string]: number } = {}
	local remainders: { { id: string, remainder: number } } = {}
	local used = 0
	for _, id in order do
		local exact = math.max(0, weights[id] or 0) / total * 1000
		local whole = math.floor(exact + 1e-9)
		units[id] = whole
		used += whole
		table.insert(remainders, { id = id, remainder = exact - whole })
	end
	table.sort(remainders, function(a, b)
		if a.remainder ~= b.remainder then
			return a.remainder > b.remainder
		end
		return a.id < b.id
	end)
	local missing = 1000 - used
	for index = 1, missing do
		local entry = remainders[(index - 1) % #remainders + 1]
		units[entry.id] += 1
	end
	for _, id in order do
		result[id] = units[id] / 10
	end
	return result
end

-- The variant for a roll between 0 and 1 (by the weights, in the order of `order`). Variants
-- without a weight cannot be chosen. Returns nil when no variant has a weight.
function Eggs.pickVariant(weights: { [string]: number }, order: { string }, roll: number): string?
	local total = 0
	for _, id in order do
		total += math.max(0, weights[id] or 0)
	end
	if total <= 0 then
		return nil
	end
	local target = unitRoll(roll) * total
	local cumulative = 0
	local last: string? = nil
	for _, id in order do
		local weight = math.max(0, weights[id] or 0)
		if weight > 0 then
			cumulative += weight
			last = id
			if target < cumulative then
				return id
			end
		end
	end
	return last
end

-- Opens an egg: a variant by the chances, for a dino chosen evenly among those the player has
-- reached. `owns(dinoId, variantId)` says whether the player already has it. Returns nil when
-- there is nothing to give (no reached dino or no variant).
function Eggs.roll(
	config: Config,
	variantOrder: { string },
	reachedDinos: { string },
	owns: (dinoId: string, variantId: string) -> boolean,
	variantRoll: number,
	dinoRoll: number
): Result?
	if #reachedDinos == 0 then
		return nil
	end
	local variantId = Eggs.pickVariant(config.weights, variantOrder, variantRoll)
	if variantId == nil then
		return nil
	end
	local index = math.floor(unitRoll(dinoRoll) * #reachedDinos) + 1
	local dinoId = reachedDinos[math.min(index, #reachedDinos)]
	return { dinoId = dinoId, variantId = variantId, duplicate = owns(dinoId, variantId) }
end

-- The coins given back for a variant the player already had (whole coins, rounded down).
function Eggs.refund(price: number, share: number): number
	if not isFinite(price) or not isFinite(share) or price <= 0 or share <= 0 then
		return 0
	end
	return math.floor(price * math.min(share, 1))
end

-- Returns a list of problems (empty when the egg config is usable): a positive whole price, a
-- share between 0 and 1, a cooldown of 0 or more, and weights only for known variants with at
-- least one above 0.
function Eggs.validate(config: Config, variantIds: { [string]: boolean }): { string }
	local errors: { string } = {}
	if not isFinite(config.price) or config.price <= 0 or config.price % 1 ~= 0 then
		table.insert(errors, "price must be a whole number above 0")
	end
	if
		not isFinite(config.duplicateRefundShare)
		or config.duplicateRefundShare < 0
		or config.duplicateRefundShare > 1
	then
		table.insert(errors, "duplicateRefundShare must be between 0 and 1")
	end
	if not isFinite(config.cooldownSeconds) or config.cooldownSeconds < 0 then
		table.insert(errors, "cooldownSeconds must be 0 or more")
	end
	local sum = 0
	for id, weight in config.weights do
		if not variantIds[id] then
			table.insert(errors, "weight for unknown variant " .. tostring(id))
		elseif not isFinite(weight) or weight < 0 then
			table.insert(errors, "weight of " .. id .. " must be 0 or more")
		else
			sum += weight
		end
	end
	if sum <= 0 then
		table.insert(errors, "at least one variant needs a weight above 0")
	end
	return errors
end

return Eggs
