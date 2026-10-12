--!strict
-- Pure helpers for the player statistics (kills, time in the arena): counting whole seconds from
-- uneven time steps and adding to a number with an upper limit. No Roblox services.

local Stats = {}

local function isFinite(value: any): boolean
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

-- Turns a time step into whole seconds. `rest` is the fraction carried over from before. A
-- step longer than `maxStep` (a hitch of the server) counts as `maxStep`, so a lag spike does not
-- hand out minutes. Returns the whole seconds to add and the new rest.
function Stats.tick(rest: number, dt: number, maxStep: number): (number, number)
	local carried = if isFinite(rest) and rest >= 0 and rest < 1 then rest else 0
	if not isFinite(dt) or dt <= 0 then
		return 0, carried
	end
	local total = carried + math.min(dt, maxStep)
	local whole = math.floor(total)
	return whole, total - whole
end

-- `value` plus `amount` (whole numbers only), never above `max`. An invalid amount changes
-- nothing, an invalid value is repaired to 0.
function Stats.add(value: number, amount: number, max: number): number
	local base = if isFinite(value) and value >= 0 then math.min(math.floor(value), max) else 0
	if not isFinite(amount) or amount <= 0 then
		return base
	end
	return math.min(max, base + math.floor(amount))
end

return Stats
