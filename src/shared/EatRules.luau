--!strict
-- Pure eating rules: who may eat whom. Whoever has more points may eat the other one (the
-- dino and the size do not matter); the reach depends on the sizes, so touching bodies count. The
-- server fills in the values from its own state, never from client input. No Roblox services,
-- no logging.

export type Config = {
	-- Largest distance between the middles per unit of the two scales added (the bodies touch).
	eatReachFactor: number,
}

export type Combatant = {
	id: number,
	scale: number,
	points: number,
	-- Server time (os.time) until which this player cannot be eaten.
	protectedUntil: number,
}

-- A player as the server sees them: position on the ground plane, scale and state.
export type Player = {
	id: number,
	x: number,
	z: number,
	scale: number,
	points: number,
	protectedUntil: number,
	alive: boolean,
}

export type Eat = { eaterId: number, victimId: number, distance: number }

export type Reason = "invalid" | "self" | "protected" | "fewer_points" | "too_far"

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
	if not isFinite(eater.points) or not isFinite(victim.points) then
		return false, "invalid"
	end
	if eater.id == victim.id then
		return false, "self"
	end
	if now < victim.protectedUntil then
		return false, "protected"
	end
	if eater.points <= victim.points then
		return false, "fewer_points"
	end
	if distance > (eater.scale + victim.scale) * config.eatReachFactor then
		return false, "too_far"
	end
	return true, nil
end

-- All eatings of one server tick. Players with more points act first (ties by id), so the result
-- does not depend on the order of the list. Every victim is eaten at most once, a player
-- who was eaten earlier in the tick eats nobody, and one eater may eat several victims
-- (nearest first).
function EatRules.findEats(config: Config, players: { Player }, now: number): { Eat }
	local order: { Player } = table.clone(players)
	table.sort(order, function(a: Player, b: Player): boolean
		if a.points ~= b.points then
			return a.points > b.points
		end
		return a.id < b.id
	end)

	local eaten: { [number]: boolean } = {}
	local eats: { Eat } = {}
	for _, eater in order do
		if not eater.alive or eaten[eater.id] then
			continue
		end
		local targets: { { victim: Player, distance: number } } = {}
		for _, victim in order do
			if victim.id == eater.id or not victim.alive or eaten[victim.id] then
				continue
			end
			local dx = victim.x - eater.x
			local dz = victim.z - eater.z
			local distance = math.sqrt(dx * dx + dz * dz)
			if EatRules.canEat(config, eater, victim, distance, now) then
				table.insert(targets, { victim = victim, distance = distance })
			end
		end
		table.sort(targets, function(a, b): boolean
			if a.distance ~= b.distance then
				return a.distance < b.distance
			end
			return a.victim.id < b.victim.id
		end)
		for _, target in targets do
			eaten[target.victim.id] = true
			table.insert(eats, { eaterId = eater.id, victimId = target.victim.id, distance = target.distance })
		end
	end
	return eats
end

-- Points the eater receives from a victim with `victimPoints`, rounded down.
function EatRules.pointsGained(share: number, victimPoints: number): number
	if victimPoints ~= victimPoints or victimPoints <= 0 then
		return 0
	end
	return math.floor(victimPoints * share)
end

return EatRules
