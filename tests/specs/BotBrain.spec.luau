--!strict
local Framework = require("../Framework")
local BotBrain = require("../../src/shared/BotBrain")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertNear = Framework.assertNear
local assertTrue = Framework.assertTrue

local config: BotBrain.Config = {
	eatRatio = 1.2,
	fleeRange = 45,
	huntRange = 35,
	fleeStep = 40,
	foodDistanceBias = 5,
}
local LIMIT = 200

local function actor(id: number, x: number, z: number, scale: number, protectedUntil: number?): BotBrain.Actor
	return { id = id, x = x, z = z, scale = scale, protectedUntil = protectedUntil or 0 }
end

local wander: BotBrain.Point = { x = 10, z = -10 }

test("BotBrain: bots fill the arena up to the target", function()
	assertEquals(BotBrain.targetCount(8, 0), 8)
	assertEquals(BotBrain.targetCount(8, 3), 5)
	assertEquals(BotBrain.targetCount(8, 8), 0)
	assertEquals(BotBrain.targetCount(8, 20), 0)
end)

test("BotBrain: invalid numbers give no bots", function()
	assertEquals(BotBrain.targetCount(0 / 0, 2), 0)
	assertEquals(BotBrain.targetCount(8, 0 / 0), 0)
	assertEquals(BotBrain.targetCount(8, -3), 8)
end)

test("BotBrain: the smallest bot leaves first, the lower id on a tie", function()
	assertEquals(
		BotBrain.pickLeaver({ { id = -1, points = 50 }, { id = -2, points = 10 }, { id = -3, points = 30 } }),
		-2
	)
	assertEquals(BotBrain.pickLeaver({ { id = -2, points = 10 }, { id = -3, points = 10 } }), -3)
	assertEquals(BotBrain.pickLeaver({}), nil)
end)

test("BotBrain: start points stay inside the first stages", function()
	local stages = { { minPoints = 0 }, { minPoints = 100 }, { minPoints = 300 }, { minPoints = 900 } }
	assertEquals(BotBrain.startPoints(stages, 2, 0), 0)
	assertEquals(BotBrain.startPoints(stages, 2, 0.5), 150)
	assertTrue(BotBrain.startPoints(stages, 2, 1) < 300)
	assertEquals(BotBrain.startPoints(stages, 2, 0 / 0), 0)
	-- Beyond the last stage the last threshold is the limit.
	assertTrue(BotBrain.startPoints(stages, 10, 1) < 900)
end)

test("BotBrain: bots stop growing at the maximum stage", function()
	assertTrue(BotBrain.mayGrow(5, 6))
	assertTrue(not BotBrain.mayGrow(6, 6))
	assertTrue(not BotBrain.mayGrow(9, 6))
end)

test("BotBrain: points are kept inside the arena", function()
	local point = BotBrain.clampToArena(500, -500, LIMIT)
	assertEquals(point.x, LIMIT)
	assertEquals(point.z, -LIMIT)
	local random = BotBrain.randomPoint(LIMIT, 0, 1)
	assertEquals(random.x, -LIMIT)
	assertEquals(random.z, LIMIT)
end)

test("BotBrain: a bot flees from a dino that can eat it", function()
	local bot = actor(-1, 0, 0, 1)
	local goal = BotBrain.choose(config, LIMIT, bot, { actor(2, 20, 0, 1.5) }, {}, 100, wander)
	assertEquals(goal.kind, "flee")
	assertEquals(goal.targetId, 2)
	assertNear(goal.x, -40, 0.001)
	assertNear(goal.z, 0, 0.001)
end)

test("BotBrain: fleeing stays inside the arena", function()
	local bot = actor(-1, -190, 0, 1)
	local goal = BotBrain.choose(config, LIMIT, bot, { actor(2, -170, 0, 1.5) }, {}, 100, wander)
	assertEquals(goal.kind, "flee")
	assertEquals(goal.x, -LIMIT)
end)

test("BotBrain: a far away bigger dino does not scare a bot", function()
	local bot = actor(-1, 0, 0, 1)
	local goal = BotBrain.choose(config, LIMIT, bot, { actor(2, 100, 0, 1.5) }, {}, 100, wander)
	assertEquals(goal.kind, "wander")
end)

test("BotBrain: a bot hunts a smaller dino in range", function()
	local bot = actor(-1, 0, 0, 1.5)
	local goal = BotBrain.choose(config, LIMIT, bot, { actor(2, 20, 0, 1) }, {}, 100, wander)
	assertEquals(goal.kind, "hunt")
	assertEquals(goal.targetId, 2)
	assertEquals(goal.x, 20)
end)

test("BotBrain: a protected dino is not hunted", function()
	local bot = actor(-1, 0, 0, 1.5)
	local goal = BotBrain.choose(config, LIMIT, bot, { actor(2, 20, 0, 1, 110) }, {}, 100, wander)
	assertEquals(goal.kind, "wander")
	local later = BotBrain.choose(config, LIMIT, bot, { actor(2, 20, 0, 1, 110) }, {}, 110, wander)
	assertEquals(later.kind, "hunt")
end)

test("BotBrain: a dino of similar size is neither feared nor hunted", function()
	local bot = actor(-1, 0, 0, 1)
	local goal = BotBrain.choose(config, LIMIT, bot, { actor(2, 10, 0, 1.1) }, {}, 100, wander)
	assertEquals(goal.kind, "wander")
end)

test("BotBrain: fleeing comes before hunting", function()
	local bot = actor(-1, 0, 0, 1.5)
	local others = { actor(2, 10, 0, 1), actor(3, -10, 0, 2) }
	local goal = BotBrain.choose(config, LIMIT, bot, others, {}, 100, wander)
	assertEquals(goal.kind, "flee")
	assertEquals(goal.targetId, 3)
end)

test("BotBrain: the nearest threat decides where to flee", function()
	local bot = actor(-1, 0, 0, 1)
	local others = { actor(2, 40, 0, 1.5), actor(3, 0, 10, 1.5) }
	local goal = BotBrain.choose(config, LIMIT, bot, others, {}, 100, wander)
	assertEquals(goal.targetId, 3)
end)

test("BotBrain: without dinos nearby the bot goes for valuable and near food", function()
	local bot = actor(-1, 0, 0, 1)
	local food: { BotBrain.Food } = {
		{ id = 1, x = 10, z = 0, value = 1 },
		{ id = 2, x = 30, z = 0, value = 10 },
		{ id = 3, x = 5, z = 5, value = 1 },
	}
	local goal = BotBrain.choose(config, LIMIT, bot, {}, food, 100, wander)
	assertEquals(goal.kind, "food")
	assertEquals(goal.targetId, 2)
end)

test("BotBrain: without anything to do the bot wanders", function()
	local bot = actor(-1, 0, 0, 1)
	local goal = BotBrain.choose(config, LIMIT, bot, {}, {}, 100, wander)
	assertEquals(goal.kind, "wander")
	assertEquals(goal.x, 10)
	assertEquals(goal.z, -10)
end)

test("BotBrain: a bot ignores itself", function()
	local bot = actor(-1, 0, 0, 1)
	local goal = BotBrain.choose(config, LIMIT, bot, { bot }, {}, 100, wander)
	assertEquals(goal.kind, "wander")
end)
