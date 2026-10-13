--!strict
-- Pure food regrowth logic. Randomness is passed in so tests are deterministic.
-- No Roblox services, no logging.

export type Pending = { id: number, readyAt: number }

local FoodSpawn = {}

-- How many new pieces may be placed so that existing plus pending stay at the target.
function FoodSpawn.missingCount(current: number, pending: number, target: number): number
	return math.max(0, target - current - pending)
end

function FoodSpawn.schedule(id: number, now: number, delaySeconds: number): Pending
	return { id = id, readyAt = now + delaySeconds }
end

-- Splits the queue into ids that are due at `now` and the entries still waiting.
function FoodSpawn.takeDue(queue: { Pending }, now: number): ({ number }, { Pending })
	local due: { number } = {}
	local remaining: { Pending } = {}
	for _, entry in queue do
		if now >= entry.readyAt then
			table.insert(due, entry.id)
		else
			table.insert(remaining, entry)
		end
	end
	return due, remaining
end

-- Random position evenly spread over the disc around (centerX, centerZ). Taking the square
-- root of the radius roll keeps the pieces from piling up in the middle.
function FoodSpawn.pickPositionInDisc(
	centerX: number,
	centerZ: number,
	radius: number,
	rng: () -> number
): (number, number)
	local angle = rng() * 2 * math.pi
	local distance = radius * math.sqrt(rng())
	return centerX + distance * math.cos(angle), centerZ + distance * math.sin(angle)
end

-- Random position in the round arena (centered at 0), `margin` studs away from the wall, evenly
-- spread over the area. `rng` returns a number in [0, 1].
function FoodSpawn.pickPosition(arenaRadius: number, margin: number, rng: () -> number): (number, number)
	return FoodSpawn.pickPositionInDisc(0, 0, math.max(0, arenaRadius - margin), rng)
end

-- Like pickPosition, but not inside the given disc. After `maxTries` it returns the last
-- position anyway, so a bad config cannot hang the server.
function FoodSpawn.pickPositionOutsideDisc(
	arenaRadius: number,
	margin: number,
	centerX: number,
	centerZ: number,
	radius: number,
	rng: () -> number,
	maxTries: number
): (number, number)
	local x, z = FoodSpawn.pickPosition(arenaRadius, margin, rng)
	for _ = 2, maxTries do
		local dx = x - centerX
		local dz = z - centerZ
		if dx * dx + dz * dz > radius * radius then
			break
		end
		x, z = FoodSpawn.pickPosition(arenaRadius, margin, rng)
	end
	return x, z
end

return FoodSpawn
