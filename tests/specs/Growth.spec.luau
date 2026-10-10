--!strict
local Framework = require("../Framework")
local Growth = require("../../src/shared/Growth")
local Dinos = require("../../src/shared/Config/Dinos")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertNear = Framework.assertNear
local assertTrue = Framework.assertTrue

test("Growth: new state is the smallest dino with no points", function()
	local state = Growth.newState()
	assertEquals(state.points, 0)
	assertEquals(state.stageIndex, 1)
	assertEquals(state.highestStageIndex, 1)
end)

test("Growth: stage changes exactly at the threshold", function()
	assertEquals(Growth.stageIndexForPoints(Dinos, 49), 1)
	assertEquals(Growth.stageIndexForPoints(Dinos, 50), 2)
	assertEquals(Growth.stageIndexForPoints(Dinos, 199), 2)
	assertEquals(Growth.stageIndexForPoints(Dinos, 200), 3)
	assertEquals(Growth.stageIndexForPoints(Dinos, 600), 4)
end)

test("Growth: addPoints reports a stage change", function()
	local state = Growth.newState()
	local after, changed = Growth.addPoints(Dinos, state, 49)
	assertEquals(after.points, 49)
	assertTrue(not changed, "no change below threshold")
	local after2, changed2 = Growth.addPoints(Dinos, after, 1)
	assertEquals(after2.stageIndex, 2)
	assertTrue(changed2, "change at threshold")
end)

test("Growth: addPoints does not mutate the old state", function()
	local state = Growth.newState()
	Growth.addPoints(Dinos, state, 100)
	assertEquals(state.points, 0)
end)

test("Growth: a big jump skips stages", function()
	local after, changed = Growth.addPoints(Dinos, Growth.newState(), 700)
	assertEquals(after.stageIndex, 4)
	assertTrue(changed)
end)

test("Growth: points keep counting on the last stage", function()
	local after = Growth.addPoints(Dinos, Growth.newState(), 600)
	local after2, changed2 = Growth.addPoints(Dinos, after, 1000)
	assertEquals(after2.points, 1600)
	assertEquals(after2.stageIndex, 4)
	assertTrue(not changed2)
end)

test("Growth: invalid amounts are rejected", function()
	local state = Growth.newState()
	for _, amount in { -5, 0, 0 / 0, math.huge, -math.huge } do
		local after, changed = Growth.addPoints(Dinos, state, amount)
		assertEquals(after.points, 0, "amount " .. tostring(amount))
		assertTrue(not changed)
	end
end)

test("Growth: scale and speed come from the current stage", function()
	local after = Growth.addPoints(Dinos, Growth.newState(), 200)
	assertEquals(Growth.scaleFor(Dinos, after), 3)
	assertEquals(Growth.speedFor(Dinos, after), 18)
end)

test("Growth: progress goes from 0 to 1 within a stage", function()
	assertEquals(Growth.progress(Dinos, Growth.newState()), 0)
	local half = Growth.addPoints(Dinos, Growth.newState(), 25)
	assertEquals(Growth.progress(Dinos, half), 0.5)
	local start = Growth.addPoints(Dinos, Growth.newState(), 50)
	assertEquals(Growth.progress(Dinos, start), 0, "start of the next stage")
end)

test("Growth: progress is 1 on the last stage", function()
	local last = Growth.addPoints(Dinos, Growth.newState(), 5000)
	assertEquals(Growth.progress(Dinos, last), 1)
end)

test("Growth: scale grows between the stage values with the progress", function()
	local half = Growth.addPoints(Dinos, Growth.newState(), 25)
	assertNear(Growth.scaleFor(Dinos, half), 1.4, 1e-9)
	local late = Growth.addPoints(Dinos, Growth.newState(), 49)
	assertNear(Growth.scaleFor(Dinos, late), 1 + 0.8 * 49 / 50, 1e-9)
end)

test("Growth: scale is continuous at a stage change", function()
	local before = Growth.addPoints(Dinos, Growth.newState(), 49.999)
	local after = Growth.addPoints(Dinos, Growth.newState(), 50)
	assertNear(Growth.scaleFor(Dinos, before), Growth.scaleFor(Dinos, after), 0.001)
end)

test("Growth: scale never shrinks with more points and stays on the last stage", function()
	local state = Growth.newState()
	local previous = Growth.scaleFor(Dinos, state)
	for _ = 1, 800 do
		state = Growth.addPoints(Dinos, state, 1)
		local scale = Growth.scaleFor(Dinos, state)
		assertTrue(scale >= previous, "no shrinking at " .. state.points)
		previous = scale
	end
	assertEquals(previous, 5)
end)

test("Growth: highest stage is remembered, reset after eaten", function()
	local state = Growth.addPoints(Dinos, Growth.newState(), 200)
	assertEquals(state.highestStageIndex, 3)
	local fresh = Growth.newState()
	assertEquals(fresh.stageIndex, 1)
	assertEquals(fresh.points, 0)
end)
