--!strict
-- Pure spawn choice: of several candidate spots, take the one farthest from the
-- nearest other player, so nobody spawns next to a bigger dino.
-- No Roblox services, no logging.

export type Point = { x: number, z: number }

local SpawnPick = {}

-- Returns the best candidate, or nil when there are none. Without other players the
-- first candidate wins, and so does the earlier one on a tie.
function SpawnPick.best(candidates: { Point }, others: { Point }): Point?
	local best: Point? = nil
	local bestDistance = -1
	for _, candidate in candidates do
		local nearest = math.huge
		for _, other in others do
			local dx = other.x - candidate.x
			local dz = other.z - candidate.z
			nearest = math.min(nearest, math.sqrt(dx * dx + dz * dz))
		end
		if nearest > bestDistance then
			best = candidate
			bestDistance = nearest
		end
	end
	return best
end

return SpawnPick
