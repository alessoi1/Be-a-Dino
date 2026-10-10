--!strict
-- Pure collection rules: which dinos a player has reached, and the best round.
-- The functions change the profile table they are given (it is the live profile
-- of ProfileStore). No Roblox services, no logging.

export type Profile = {
	reachedStages: { [string]: boolean },
	bestPoints: number,
}

type Stage = { id: string }

local Collection = {}

-- Returns true when the stage was not reached before.
function Collection.markReached(profile: Profile, stageId: string): boolean
	if type(stageId) ~= "string" or stageId == "" then
		return false
	end
	if profile.reachedStages[stageId] then
		return false
	end
	profile.reachedStages[stageId] = true
	return true
end

function Collection.isReached(profile: Profile, stageId: string): boolean
	return profile.reachedStages[stageId] == true
end

-- Marks every stage up to and including `stageIndex` (a player who grew past a stage
-- has been that dino). Returns how many were new.
function Collection.markUpTo(profile: Profile, stages: { Stage }, stageIndex: number): number
	local added = 0
	for index = 1, math.min(stageIndex, #stages) do
		if Collection.markReached(profile, stages[index].id) then
			added += 1
		end
	end
	return added
end

-- Takes `points` (rounded down) as the best round when it is larger. Returns true on a new best.
function Collection.updateBest(profile: Profile, points: number): boolean
	if type(points) ~= "number" or points ~= points or points == math.huge or points < 0 then
		return false
	end
	local rounded = math.floor(points)
	if rounded <= profile.bestPoints then
		return false
	end
	profile.bestPoints = rounded
	return true
end

-- How many of the known stages the player has reached.
function Collection.reachedCount(profile: Profile, stages: { Stage }): number
	local count = 0
	for _, stage in stages do
		if profile.reachedStages[stage.id] then
			count += 1
		end
	end
	return count
end

return Collection
