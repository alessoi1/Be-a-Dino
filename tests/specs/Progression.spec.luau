--!strict
local Dinos = require("../../src/shared/Config/Dinos")
local FoodConfig = require("../../src/shared/Config/Food")
local FoodKinds = require("../../src/shared/FoodKinds")
local Framework = require("../Framework")
local Progress = require("../../src/shared/Config/Progress")
local Progression = require("../../src/shared/Progression")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertNear = Framework.assertNear
local assertTrue = Framework.assertTrue

local function contains(errors: { string }, text: string): boolean
	for _, message in errors do
		if string.find(message, text, 1, true) ~= nil then
			return true
		end
	end
	return false
end

local function stage(id: string, minPoints: number, scale: number, foodUnit: number): Progression.Stage
	return { id = id, minPoints = minPoints, scale = scale, speed = 20, foodUnit = foodUnit }
end

test("Progression: foodGain is the unit times the value, whole and at least 1", function()
	assertEquals(Progression.foodGain(17, 1), 17)
	assertEquals(Progression.foodGain(17, 3), 51)
	assertEquals(Progression.foodGain(16540, 10), 165400)
	assertEquals(Progression.foodGain(1, 0.5), 1, "never below 1")
	assertEquals(Progression.foodGain(2.5, 3), 7, "cut off")
end)

test("Progression: foodGain refuses invalid numbers", function()
	assertEquals(Progression.foodGain(0, 3), 0)
	assertEquals(Progression.foodGain(-5, 3), 0)
	assertEquals(Progression.foodGain(5, 0 / 0), 0)
	assertEquals(Progression.foodGain(math.huge, 3), 0)
end)

test("Progression: the real stage list is valid", function()
	local average = FoodKinds.averageValue(FoodConfig.kinds)
	local errors = Progression.validate(Dinos, average, Progress.minPiecesPerStage, Progress.maxPiecesPerStage)
	assertEquals(table.concat(errors, "; "), "")
end)

test("Progression: the average food value of the real kinds", function()
	assertNear(FoodKinds.averageValue(FoodConfig.kinds), 1.51, 1e-9)
	assertNear(FoodKinds.averageValue(FoodConfig.kinds, FoodConfig.zones.center.weights), 3.6, 1e-9)
	assertEquals(FoodKinds.averageValue({}), 0)
end)

test("Progression: piecesToNext", function()
	local stages = { stage("a", 0, 1, 10), stage("b", 1000, 2, 100) }
	assertNear(Progression.piecesToNext(stages, 1, 2) :: number, 50, 1e-9)
	assertEquals(Progression.piecesToNext(stages, 2, 2), nil, "last stage")
	assertEquals(Progression.piecesToNext(stages, 5, 2), nil, "unknown stage")
end)

test("Progression: validate reports broken stage lists", function()
	local ok = { stage("a", 0, 1, 10), stage("b", 1000, 2, 100) }
	assertEquals(#Progression.validate(ok, 1, 20, 200), 0)
	assertTrue(contains(Progression.validate({}, 1, 20, 200), "no stages"))
	assertTrue(contains(Progression.validate({ stage("a", 5, 1, 10) }, 1, 20, 200), "start at 0"))
	assertTrue(
		contains(Progression.validate({ stage("a", 0, 1, 10), stage("a", 1000, 2, 100) }, 1, 20, 200), "duplicate")
	)
	assertTrue(
		contains(
			Progression.validate({ stage("a", 0, 1, 10), stage("b", 0, 2, 10) }, 1, 20, 200),
			"minPoints must grow"
		)
	)
	assertTrue(
		contains(
			Progression.validate({ stage("a", 0, 2, 10), stage("b", 1000, 1, 100) }, 1, 20, 200),
			"scale must not shrink"
		)
	)
	assertTrue(
		contains(Progression.validate({ stage("a", 0, 1, 0), stage("b", 1000, 2, 100) }, 1, 20, 200), "foodUnit")
	)
end)

test("Progression: a stage that takes too few or too many pieces is reported", function()
	-- 1000 / (10 * 1) = 100 pieces
	local stages = { stage("a", 0, 1, 10), stage("b", 1000, 2, 100) }
	assertTrue(contains(Progression.validate(stages, 1, 20, 80), "food pieces"))
	assertTrue(contains(Progression.validate(stages, 1, 150, 300), "food pieces"))
	assertEquals(#Progression.validate(stages, 1, 50, 150), 0)
end)

test("Progression: pointsForFraction is a share of the current stage", function()
	local stages = { stage("a", 0, 1, 10), stage("b", 1000, 2, 100), stage("c", 5000, 3, 1000) }
	assertEquals(Progression.pointsForFraction(stages, { points = 0, stageIndex = 1 }, 0.25), 250)
	assertEquals(Progression.pointsForFraction(stages, { points = 1000, stageIndex = 2 }, 0.5), 2000)
	assertEquals(Progression.pointsForFraction(stages, { points = 5000, stageIndex = 3 }, 0.25), 1250, "last stage")
end)

test("Progression: pointsForFraction handles invalid input", function()
	local stages = { stage("a", 0, 1, 10), stage("b", 1000, 2, 100) }
	assertEquals(Progression.pointsForFraction(stages, { points = 0, stageIndex = 1 }, 0), 0)
	assertEquals(Progression.pointsForFraction(stages, { points = 0, stageIndex = 1 }, -1), 0)
	assertEquals(Progression.pointsForFraction(stages, { points = 0, stageIndex = 1 }, 0 / 0), 0)
	assertEquals(Progression.pointsForFraction(stages, { points = 0, stageIndex = 9 }, 0.25), 0)
	assertEquals(Progression.pointsForFraction(stages, { points = 0, stageIndex = 1 }, 0.00001), 1, "at least 1")
end)
