--!strict
-- Pure growth logic: points to stage, scale and speed. No Roblox services,
-- no logging; the calling service logs results.

local Dinos = require("./Config/Dinos")

export type State = {
	points: number,
	stageIndex: number,
	highestStageIndex: number,
}

local Growth = {}

function Growth.newState(): State
	return { points = 0, stageIndex = 1, highestStageIndex = 1 }
end

function Growth.stageIndexForPoints(stages: { Dinos.DinoStage }, points: number): number
	local index = 1
	for i, stage in stages do
		if points >= stage.minPoints then
			index = i
		else
			break
		end
	end
	return index
end

-- Returns the new state (the old one is not changed) and whether the stage changed.
-- Invalid or non-positive amounts leave the state as it is.
function Growth.addPoints(stages: { Dinos.DinoStage }, state: State, amount: number): (State, boolean)
	if amount ~= amount or amount <= 0 or amount == math.huge then
		return state, false
	end
	local points = state.points + amount
	local stageIndex = Growth.stageIndexForPoints(stages, points)
	local newState: State = {
		points = points,
		stageIndex = stageIndex,
		highestStageIndex = math.max(state.highestStageIndex, stageIndex),
	}
	return newState, stageIndex ~= state.stageIndex
end

-- Progress within the current stage toward the next one, between 0 and 1.
-- On the last stage it is 1.
function Growth.progress(stages: { Dinos.DinoStage }, state: State): number
	local current = stages[state.stageIndex]
	local nextStage = stages[state.stageIndex + 1]
	if nextStage == nil then
		return 1
	end
	local span = nextStage.minPoints - current.minPoints
	return math.clamp((state.points - current.minPoints) / span, 0, 1)
end

function Growth.scaleFor(stages: { Dinos.DinoStage }, state: State): number
	return stages[state.stageIndex].scale
end

function Growth.speedFor(stages: { Dinos.DinoStage }, state: State): number
	return stages[state.stageIndex].speed
end

return Growth
