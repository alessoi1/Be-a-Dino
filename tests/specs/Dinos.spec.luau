--!strict
local DinoBody = require("../../src/shared/DinoBody")
local DinoLooks = require("../../src/shared/Config/DinoLooks")
local Dinos = require("../../src/shared/Config/Dinos")
local FoodConfig = require("../../src/shared/Config/Food")
local FoodKinds = require("../../src/shared/FoodKinds")
local Framework = require("../Framework")
local Progress = require("../../src/shared/Config/Progress")
local Progression = require("../../src/shared/Progression")
local Strings = require("../../src/shared/Strings")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertTrue = Framework.assertTrue

test("Dinos: there are 35 dinos and the four old ids keep their names", function()
	assertEquals(#Dinos, 35)
	local ids: { [string]: number } = {}
	for index, stage in Dinos do
		ids[stage.id] = index
	end
	assertTrue(ids.compy == 1 and ids.raptor ~= nil and ids.stego ~= nil and ids.trex ~= nil, "old ids exist")
	assertTrue(ids.compy < ids.raptor and ids.raptor < ids.stego and ids.stego < ids.trex, "old order is kept")
end)

test("Dinos: the stage list passes the balance check of the progression", function()
	local average = FoodKinds.averageValue(FoodConfig.kinds)
	local errors = Progression.validate(Dinos, average, Progress.minPiecesPerStage, Progress.maxPiecesPerStage)
	assertEquals(table.concat(errors, "; "), "")
end)

test("Dinos: the sizes run from 1K to 1T and the figure from 1 to 8", function()
	assertEquals(Dinos[1].minPoints, 0)
	assertEquals(Dinos[2].minPoints, 1000)
	assertEquals(Dinos[#Dinos].minPoints, 1000000000000)
	assertEquals(Dinos[1].scale, 1)
	assertEquals(Dinos[#Dinos].scale, 8)
end)

test("Dinos: every dino has a name and ids are safe to send as text", function()
	for _, stage in Dinos do
		assertTrue(Strings.dinos[stage.id] ~= nil, "name for " .. stage.id)
		assertTrue(string.match(stage.id, "^[a-z0-9_]+$") ~= nil, "id " .. stage.id)
		assertTrue(#Strings.dinos[stage.id] <= 12, "short name for " .. stage.id)
	end
	local names = 0
	for _ in Strings.dinos do
		names += 1
	end
	assertEquals(names, #Dinos, "no names for unknown dinos")
end)

test("Dinos: every dino has exactly one look, hand-written or planned", function()
	for _, stage in Dinos do
		local hasLook = DinoLooks.looks[stage.id] ~= nil
		local hasPlan = DinoLooks.plans[stage.id] ~= nil
		assertTrue(hasLook or hasPlan, "look for " .. stage.id)
		assertTrue(not (hasLook and hasPlan), "only one of look and plan for " .. stage.id)
	end
	local known: { [string]: boolean } = {}
	for _, stage in Dinos do
		known[stage.id] = true
	end
	for id in DinoLooks.plans do
		assertTrue(known[id], "plan for unknown dino " .. id)
	end
	for id in DinoLooks.looks do
		assertTrue(known[id], "look for unknown dino " .. id)
	end
end)

test("Dinos: all plans are valid", function()
	for id, plan in DinoLooks.plans do
		local errors = DinoBody.validatePlan(plan)
		assertEquals(table.concat(errors, "; "), "", "plan of " .. id)
	end
end)

test("Dinos: lookFor prefers a hand-written look and builds the others", function()
	assertTrue(DinoBody.lookFor(DinoLooks.looks, DinoLooks.plans, "compy") == DinoLooks.looks.compy)
	local built = DinoBody.lookFor(DinoLooks.looks, DinoLooks.plans, "diplo")
	assertTrue(built ~= nil and #built.parts > 0)
	assertEquals(DinoBody.lookFor(DinoLooks.looks, DinoLooks.plans, "unknown"), nil)
end)

test("Dinos: neighbours differ, so the dinodex is not 35 copies", function()
	-- Every dino differs from the one before in shape, size or color.
	local previous: string? = nil
	for _, stage in Dinos do
		local plan = DinoLooks.plans[stage.id]
		if plan ~= nil and previous ~= nil then
			local before = DinoLooks.plans[previous]
			if before ~= nil then
				local same = before.template == plan.template
					and before.length == plan.length
					and before.height == plan.height
					and before.body.r == plan.body.r
				assertTrue(not same, stage.id .. " looks like " .. previous)
			end
		end
		previous = stage.id
	end
end)
