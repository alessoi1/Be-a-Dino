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

-- Random position in the square arena (centered at 0), `margin` studs away from the wall.
-- `rng` returns a number in [0, 1].
function FoodSpawn.pickPosition(arenaSize: number, margin: number, rng: () -> number): (number, number)
	local half = arenaSize / 2 - margin
	local x = (rng() * 2 - 1) * half
	local z = (rng() * 2 - 1) * half
	return x, z
end

return FoodSpawn
