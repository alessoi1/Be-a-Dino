--!strict
-- Pure eating rules: who may eat whom. The server fills in the values from its
-- own state, never from client input. No Roblox services, no logging.

export type Config = {
	eatRatio: number,
	eatDistanceFactor: number,
}

export type Combatant = {
	id: number,
	scale: number,
	-- Server time (os.time) until which this player cannot be eaten.
	protectedUntil: number,
}

export type Reason = "invalid" | "self" | "protected" | "too_small" | "too_far"

local EatRules = {}

local function isFinite(value: number): boolean
	return value == value and value ~= math.huge and value ~= -math.huge
end

-- Returns true, or false with the reason for the rejection.
function EatRules.canEat(
	config: Config,
	eater: Combatant,
	victim: Combatant,
	distance: number,
	now: number
): (boolean, Reason?)
	if not isFinite(distance) or distance < 0 or not isFinite(now) then
		return false, "invalid"
	end
	if eater.id == victim.id then
		return false, "self"
	end
	if now < victim.protectedUntil then
		return false, "protected"
	end
	if eater.scale < victim.scale * config.eatRatio then
		return false, "too_small"
	end
	if distance > eater.scale * config.eatDistanceFactor then
		return false, "too_far"
	end
	return true, nil
end

-- Points the eater receives from a victim with `victimPoints`, rounded down.
function EatRules.pointsGained(share: number, victimPoints: number): number
	if victimPoints ~= victimPoints or victimPoints <= 0 then
		return 0
	end
	return math.floor(victimPoints * share)
end

return EatRules
