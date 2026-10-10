--!strict
local Collection = require("../../src/shared/Collection")
local Dinos = require("../../src/shared/Config/Dinos")
local Framework = require("../Framework")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertTrue = Framework.assertTrue

local function profile(): Collection.Profile
	return { reachedStages = {}, bestPoints = 0 }
end

test("Collection: markReached reports only the first time", function()
	local p = profile()
	assertTrue(Collection.markReached(p, "raptor"))
	assertTrue(not Collection.markReached(p, "raptor"))
	assertTrue(Collection.isReached(p, "raptor"))
	assertTrue(not Collection.isReached(p, "trex"))
end)

test("Collection: invalid stage ids are ignored", function()
	local p = profile()
	assertTrue(not Collection.markReached(p, ""))
	assertTrue(not Collection.markReached(p, 5 :: any))
	assertEquals(next(p.reachedStages), nil)
end)

test("Collection: markUpTo marks every stage up to the index", function()
	local p = profile()
	local added = Collection.markUpTo(p, Dinos, 3)
	assertEquals(added, 3)
	assertTrue(Collection.isReached(p, "compy"))
	assertTrue(Collection.isReached(p, "raptor"))
	assertTrue(Collection.isReached(p, "stego"))
	assertTrue(not Collection.isReached(p, "trex"))
	assertEquals(Collection.markUpTo(p, Dinos, 3), 0, "nothing new")
	assertEquals(Collection.markUpTo(p, Dinos, 99), 1, "index is limited to the stages")
end)

test("Collection: updateBest only takes larger valid values", function()
	local p = profile()
	assertTrue(Collection.updateBest(p, 10.9))
	assertEquals(p.bestPoints, 10)
	assertTrue(not Collection.updateBest(p, 5))
	assertTrue(not Collection.updateBest(p, 10))
	assertTrue(not Collection.updateBest(p, 0 / 0))
	assertTrue(not Collection.updateBest(p, -4))
	assertTrue(not Collection.updateBest(p, math.huge))
	assertEquals(p.bestPoints, 10)
end)

test("Collection: reachedCount counts only known stages", function()
	local p = profile()
	Collection.markReached(p, "compy")
	Collection.markReached(p, "trex")
	Collection.markReached(p, "removed_dino")
	assertEquals(Collection.reachedCount(p, Dinos), 2)
end)
