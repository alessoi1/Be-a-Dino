--!strict
-- Pure bot logic: how many bots there are, which one leaves, where a bot starts and what it does
-- next (flee, hunt, eat or wander). No Roblox services, no logging; the BotService calls it with
-- values from its own state and logs the results.

export type Actor = { id: number, x: number, z: number, scale: number, points: number, protectedUntil: number }
export type Food = { id: number, x: number, z: number, value: number }
export type Goal = { kind: "flee" | "hunt" | "food" | "wander", x: number, z: number, targetId: number? }
export type Point = { x: number, z: number }

export type Config = {
	fleeRange: number,
	huntRange: number,
	fleeStep: number,
	foodDistanceBias: number,
}

export type BotInfo = { id: number, points: number }
export type Stage = { minPoints: number }

local BotBrain = {}

local function isFinite(value: number): boolean
	return value == value and value ~= math.huge and value ~= -math.huge
end

-- How many bots there should be: the arena is filled up to `fillTo` dinos in total.
function BotBrain.targetCount(fillTo: number, playersInArena: number): number
	if not isFinite(fillTo) or not isFinite(playersInArena) then
		return 0
	end
	return math.max(0, math.floor(fillTo) - math.max(0, math.floor(playersInArena)))
end

-- The bot that leaves first: the smallest one (fewest points), the lower id on a tie. Nil when
-- there are no bots.
function BotBrain.pickLeaver(bots: { BotInfo }): number?
	local best: BotInfo? = nil
	for _, bot in bots do
		if best == nil or bot.points < best.points or (bot.points == best.points and bot.id < best.id) then
			best = bot
		end
	end
	return if best ~= nil then best.id else nil
end

-- Points a new bot starts with: a random size within the first `maxStage` stages, from `roll`
-- between 0 and 1.
function BotBrain.startPoints(stages: { Stage }, maxStage: number, roll: number): number
	if not isFinite(roll) or roll <= 0 then
		return 0
	end
	local limit = stages[math.min(maxStage, #stages) + 1] or stages[#stages]
	return math.floor(math.min(roll, 0.999999) * limit.minPoints)
end

-- Whether a bot on this stage may still grow (bots stop at `maxStageIndex`).
function BotBrain.mayGrow(stageIndex: number, maxStageIndex: number): boolean
	return stageIndex < maxStageIndex
end

-- Keeps a point inside the round arena, at most `limit` studs from the middle. A point outside
-- is moved straight toward the middle; a point that is not a number goes to the middle.
function BotBrain.clampToArena(x: number, z: number, limit: number): Point
	if not isFinite(x) or not isFinite(z) then
		return { x = 0, z = 0 }
	end
	local distance = math.sqrt(x * x + z * z)
	if distance <= limit then
		return { x = x, z = z }
	end
	local factor = math.max(0, limit) / distance
	return { x = x * factor, z = z * factor }
end

local function distanceBetween(a: Point, b: Point): number
	local dx = a.x - b.x
	local dz = a.z - b.z
	return math.sqrt(dx * dx + dz * dz)
end

-- The point `step` studs from `from` away from (or toward) `other`, kept inside the arena.
local function stepFrom(from: Point, other: Point, step: number, away: boolean, limit: number): Point
	local dx = other.x - from.x
	local dz = other.z - from.z
	local length = math.sqrt(dx * dx + dz * dz)
	if length < 1e-6 then
		return { x = from.x + step, z = from.z }
	end
	local sign = if away then -1 else 1
	return BotBrain.clampToArena(from.x + sign * dx / length * step, from.z + sign * dz / length * step, limit)
end

-- The next goal of a bot. Flee from the nearest dino that can eat it, otherwise hunt the nearest
-- one it can eat (not while that one is protected), otherwise go for the best piece of food, and
-- otherwise walk to `wander`. `others` and `food` are everything the bot may see.
function BotBrain.choose(
	config: Config,
	limit: number,
	bot: Actor,
	others: { Actor },
	food: { Food },
	now: number,
	wander: Point
): Goal
	local here: Point = { x = bot.x, z = bot.z }

	local threat: Actor? = nil
	local threatDistance = config.fleeRange
	local prey: Actor? = nil
	local preyDistance = config.huntRange
	for _, other in others do
		if other.id == bot.id then
			continue
		end
		local distance = distanceBetween(here, { x = other.x, z = other.z })
		if other.points > bot.points then
			if distance <= threatDistance then
				threat = other
				threatDistance = distance
			end
		elseif bot.points > other.points and now >= other.protectedUntil then
			if distance <= preyDistance then
				prey = other
				preyDistance = distance
			end
		end
	end

	if threat ~= nil then
		local point = stepFrom(here, { x = threat.x, z = threat.z }, config.fleeStep, true, limit)
		return { kind = "flee", x = point.x, z = point.z, targetId = threat.id }
	end
	if prey ~= nil then
		return { kind = "hunt", x = prey.x, z = prey.z, targetId = prey.id }
	end

	local bestFood: Food? = nil
	local bestScore = -math.huge
	for _, piece in food do
		local score = piece.value / (distanceBetween(here, { x = piece.x, z = piece.z }) + config.foodDistanceBias)
		if score > bestScore then
			bestScore = score
			bestFood = piece
		end
	end
	if bestFood ~= nil then
		return { kind = "food", x = bestFood.x, z = bestFood.z, targetId = bestFood.id }
	end

	return { kind = "wander", x = wander.x, z = wander.z }
end

return BotBrain
