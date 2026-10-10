--!strict
-- Pure growth balance helpers: what a piece of food is worth on a stage, how many pieces a
-- stage takes, and a check of the stage list. No Roblox services, no logging.

export type Stage = {
	id: string,
	minPoints: number,
	scale: number,
	speed: number,
	foodUnit: number,
}

-- Same shape as Growth.State (no require, so this module loads the same way everywhere).
type State = { points: number, stageIndex: number }

local Progression = {}

local function isFinite(value: any): boolean
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

-- Points a piece of food gives: the unit of the stage times the value of the piece, cut off to
-- a whole number and never below 1.
function Progression.foodGain(unit: number, kindValue: number): number
	if not isFinite(unit) or not isFinite(kindValue) or unit <= 0 or kindValue <= 0 then
		return 0
	end
	return math.max(1, math.floor(unit * kindValue))
end

-- How many pieces of average value `averageKindValue` it takes to get from the start of the
-- stage to the next one. Nil on the last stage.
function Progression.piecesToNext(stages: { Stage }, index: number, averageKindValue: number): number?
	local stage = stages[index]
	local nextStage = stages[index + 1]
	if stage == nil or nextStage == nil then
		return nil
	end
	return (nextStage.minPoints - stage.minPoints) / (stage.foodUnit * averageKindValue)
end

-- Returns a list of problems (empty when the stage list is usable): ids are unique, the first
-- stage starts at 0, thresholds and sizes grow, units are positive, and every stage takes a
-- number of food pieces within [minPieces, maxPieces].
function Progression.validate(
	stages: { Stage },
	averageKindValue: number,
	minPieces: number,
	maxPieces: number
): { string }
	local errors: { string } = {}
	if #stages == 0 then
		table.insert(errors, "no stages")
		return errors
	end
	if stages[1].minPoints ~= 0 then
		table.insert(errors, "the first stage must start at 0")
	end
	local seen: { [string]: boolean } = {}
	for index, stage in stages do
		local where = "stage " .. stage.id
		if seen[stage.id] then
			table.insert(errors, where .. ": duplicate id")
		end
		seen[stage.id] = true
		if not isFinite(stage.foodUnit) or stage.foodUnit <= 0 then
			table.insert(errors, where .. ": foodUnit must be above 0")
		end
		if not isFinite(stage.scale) or stage.scale <= 0 or not isFinite(stage.speed) or stage.speed <= 0 then
			table.insert(errors, where .. ": scale and speed must be above 0")
		end
		local previous = stages[index - 1]
		if previous ~= nil then
			if stage.minPoints <= previous.minPoints then
				table.insert(errors, where .. ": minPoints must grow")
			end
			if stage.scale < previous.scale then
				table.insert(errors, where .. ": scale must not shrink")
			end
		end
		local pieces = Progression.piecesToNext(stages, index, averageKindValue)
		if pieces ~= nil and isFinite(stage.foodUnit) and stage.foodUnit > 0 then
			if pieces < minPieces or pieces > maxPieces then
				table.insert(
					errors,
					where
						.. ": needs "
						.. string.format("%.1f", pieces)
						.. " food pieces, allowed "
						.. minPieces
						.. " to "
						.. maxPieces
				)
			end
		end
	end
	return errors
end

-- Points that are `fraction` of the way from the start to the end of the current stage (for the
-- Studio debug key). On the last stage the start of the stage is the base.
function Progression.pointsForFraction(stages: { Stage }, state: State, fraction: number): number
	if not isFinite(fraction) or fraction <= 0 then
		return 0
	end
	local stage = stages[state.stageIndex]
	if stage == nil then
		return 0
	end
	local nextStage = stages[state.stageIndex + 1]
	local span = if nextStage ~= nil
		then nextStage.minPoints - stage.minPoints
		else math.max(stage.minPoints, stage.foodUnit)
	return math.max(1, math.floor(span * fraction))
end

return Progression
