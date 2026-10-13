--!strict
-- Pure autofarm logic: which food the dino walks to, when it runs away, and how long a session
-- may last. The inputs are plain positions; the client fills them in. No Roblox services.

export type Me = { x: number, z: number, scale: number }
export type Food = { x: number, z: number, value: number }
export type Other = { x: number, z: number, scale: number }

export type Config = {
	dangerMargin: number,
	fleeDistance: number,
	valueBias: number,
	arenaMargin: number,
}

-- The eating rules (Config/Arena): who could eat me.
export type Rules = { eatRatio: number, eatReachFactor: number }

-- "food": walk to the point. "flee": run to the point, away from a danger. "idle": stay.
export type Target = { kind: "food" | "flee" | "idle", x: number, z: number }

local AutoFarm = {}

local function isFinite(value: any): boolean
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function distanceBetween(ax: number, az: number, bx: number, bz: number): number
	local dx = ax - bx
	local dz = az - bz
	return math.sqrt(dx * dx + dz * dz)
end

-- Reach of the danger around a player who could eat me (the bodies must touch: both scales count).
local function dangerRadius(other: Other, myScale: number, config: Config, rules: Rules): number
	return (other.scale + myScale) * rules.eatReachFactor + config.dangerMargin
end

-- The players who could eat me (by the eating rule), with valid numbers only.
local function threatsOf(me: Me, others: { Other }, rules: Rules): { Other }
	local threats: { Other } = {}
	for _, other in others do
		if
			isFinite(other.x)
			and isFinite(other.z)
			and isFinite(other.scale)
			and other.scale >= me.scale * rules.eatRatio
		then
			table.insert(threats, other)
		end
	end
	return threats
end

-- Keeps a point inside the round arena (at most `limit` studs from the middle).
local function clampToDisc(x: number, z: number, limit: number): (number, number)
	local distance = math.sqrt(x * x + z * z)
	if distance <= limit then
		return x, z
	end
	local factor = math.max(0, limit) / distance
	return x * factor, z * factor
end

-- Chooses what to do now. A danger close by wins: run in the opposite direction (inside the
-- arena). Otherwise walk to the food with the best value for its distance that is not in the
-- reach of a danger. Without a safe piece the dino stays.
function AutoFarm.pickTarget(
	config: Config,
	rules: Rules,
	me: Me,
	foods: { Food },
	others: { Other },
	arenaRadius: number
): Target
	local idle: Target = { kind = "idle", x = me.x, z = me.z }
	if not isFinite(me.x) or not isFinite(me.z) or not isFinite(me.scale) then
		return idle
	end
	local limit = arenaRadius - config.arenaMargin
	local threats = threatsOf(me, others, rules)

	-- Run away from the danger I am in (the one I am deepest in).
	local worst: Other? = nil
	local worstDepth = 0
	for _, threat in threats do
		local depth = dangerRadius(threat, me.scale, config, rules) - distanceBetween(me.x, me.z, threat.x, threat.z)
		if depth > worstDepth then
			worst = threat
			worstDepth = depth
		end
	end
	if worst ~= nil then
		local dx = me.x - worst.x
		local dz = me.z - worst.z
		local length = math.sqrt(dx * dx + dz * dz)
		if length < 1e-6 then
			dx, dz, length = 1, 0, 1
		end
		local x, z =
			clampToDisc(me.x + dx / length * config.fleeDistance, me.z + dz / length * config.fleeDistance, limit)
		return { kind = "flee", x = x, z = z }
	end

	local best: Food? = nil
	local bestScore = -math.huge
	local bestDistance = math.huge
	for _, food in foods do
		if isFinite(food.x) and isFinite(food.z) and isFinite(food.value) and food.value > 0 then
			local safe = true
			for _, threat in threats do
				if
					distanceBetween(food.x, food.z, threat.x, threat.z) <= dangerRadius(threat, me.scale, config, rules)
				then
					safe = false
					break
				end
			end
			if safe then
				local distance = distanceBetween(me.x, me.z, food.x, food.z)
				local score = food.value / (distance + config.valueBias)
				local better = score > bestScore
					or (score == bestScore and (distance < bestDistance))
					or (
						score == bestScore
						and distance == bestDistance
						and best ~= nil
						and (food.x < best.x or (food.x == best.x and food.z < best.z))
					)
				if better then
					best = food
					bestScore = score
					bestDistance = distance
				end
			end
		end
	end
	if best == nil then
		return idle
	end
	return { kind = "food", x = best.x, z = best.z }
end

-- Whether a session that started at `startedAt` is still running at `now`.
function AutoFarm.sessionActive(startedAt: number, now: number, maxSeconds: number): boolean
	if not isFinite(startedAt) or not isFinite(now) or not isFinite(maxSeconds) or maxSeconds <= 0 then
		return false
	end
	return now >= startedAt and now - startedAt < maxSeconds
end

return AutoFarm
