--!strict
local CollectionView = require("../../src/shared/CollectionView")
local Dinos = require("../../src/shared/Config/Dinos")
local Framework = require("../Framework")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertTrue = Framework.assertTrue

test("CollectionView: encodeReached lists known stages in stage order", function()
	local text = CollectionView.encodeReached({ trex = true, compy = true, raptor = true }, Dinos)
	assertEquals(text, "compy,raptor,trex")
end)

test("CollectionView: encodeReached ignores unknown stages and false entries", function()
	local text = CollectionView.encodeReached({ compy = true, removed = true, stego = false }, Dinos)
	assertEquals(text, "compy")
	assertEquals(CollectionView.encodeReached({}, Dinos), "")
end)

test("CollectionView: decodeReached reads what encodeReached wrote", function()
	local set = CollectionView.decodeReached("compy,raptor,trex")
	assertTrue(set.compy and set.raptor and set.trex)
	assertTrue(set.stego == nil)
	local again = CollectionView.encodeReached(set, Dinos)
	assertEquals(again, "compy,raptor,trex")
end)

test("CollectionView: decodeReached ignores empty and invalid parts", function()
	local set = CollectionView.decodeReached(",compy,,Bad Id,raptor;x,a-b, stego")
	assertTrue(set.compy)
	assertTrue(set.stego == nil, "spaces are not valid")
	assertTrue(set["Bad Id"] == nil)
	assertTrue(set["raptor;x"] == nil)
	assertEquals(CollectionView.encodeReached(set, Dinos), "compy")
end)

test("CollectionView: decodeReached handles empty and huge input", function()
	assertEquals(next(CollectionView.decodeReached("")), nil)
	local parts = {}
	for index = 1, 500 do
		table.insert(parts, "dino" .. index)
	end
	local set = CollectionView.decodeReached(table.concat(parts, ","))
	local count = 0
	for _ in set do
		count += 1
	end
	assertTrue(count <= CollectionView.MAX_ENTRIES, "limited to " .. count)
end)

test("CollectionView: cards follow the stage order with state and threshold", function()
	local cards = CollectionView.cards(Dinos, { compy = true, stego = true })
	assertEquals(#cards, 4)
	assertEquals(cards[1].id, "compy")
	assertTrue(cards[1].reached)
	assertTrue(not cards[2].reached)
	assertEquals(cards[2].minPoints, 50)
	assertTrue(cards[3].reached)
	assertEquals(cards[4].index, 4)
end)

test("CollectionView: an unknown id in the set does not matter", function()
	local cards = CollectionView.cards(Dinos, { removed = true })
	local reached, total = CollectionView.summary(cards)
	assertEquals(reached, 0)
	assertEquals(total, 4)
end)

test("CollectionView: summary counts the reached cards", function()
	local reached, total = CollectionView.summary(CollectionView.cards(Dinos, { compy = true, raptor = true }))
	assertEquals(reached, 2)
	assertEquals(total, 4)
end)
