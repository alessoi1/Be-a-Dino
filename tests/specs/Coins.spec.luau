--!strict
local Coins = require("../../src/shared/Coins")
local Framework = require("../Framework")

local test = Framework.test
local assertEquals = Framework.assertEquals

test("Coins: a newly reached stage gives the factor times its number", function()
	assertEquals(Coins.forStage(2, 5), 10)
	assertEquals(Coins.forStage(10, 5), 50)
	assertEquals(Coins.forStage(50, 5), 250)
end)

test("Coins: the first stage and invalid input give nothing", function()
	assertEquals(Coins.forStage(1, 5), 0)
	assertEquals(Coins.forStage(0, 5), 0)
	assertEquals(Coins.forStage(-3, 5), 0)
	assertEquals(Coins.forStage(5, 0), 0)
	assertEquals(Coins.forStage(0 / 0, 5), 0)
	assertEquals(Coins.forStage(5, math.huge), 0)
end)

test("Coins: forStages adds every stage that was passed, skipped ones too", function()
	assertEquals(Coins.forStages(1, 2, 5), 10)
	assertEquals(Coins.forStages(1, 4, 5), 10 + 15 + 20)
	assertEquals(Coins.forStages(3, 5, 5), 20 + 25)
end)

test("Coins: forStages gives nothing without growth", function()
	assertEquals(Coins.forStages(3, 3, 5), 0)
	assertEquals(Coins.forStages(5, 2, 5), 0)
	assertEquals(Coins.forStages(0 / 0, 4, 5), 0)
end)

test("Coins: a full run through 50 stages", function()
	-- 5 * (2 + 3 + ... + 50) = 5 * 1274
	assertEquals(Coins.forStages(1, 50, 5), 6370)
end)

test("Coins: add never goes above the limit", function()
	assertEquals(Coins.add(10, 5, 1000), 15)
	assertEquals(Coins.add(990, 50, 1000), 1000)
	assertEquals(Coins.add(1000, 5, 1000), 1000)
end)

test("Coins: add ignores invalid amounts and repairs invalid balances", function()
	assertEquals(Coins.add(10, -5, 1000), 10)
	assertEquals(Coins.add(10, 0, 1000), 10)
	assertEquals(Coins.add(10, 0 / 0, 1000), 10)
	assertEquals(Coins.add(10, math.huge, 1000), 10)
	assertEquals(Coins.add(-4, 5, 1000), 0)
	assertEquals(Coins.add(0 / 0, 5, 1000), 0)
	assertEquals(Coins.add(10.7, 1.4, 1000), 12, "whole coins")
end)

test("Coins: eating a player gives the stage number times the factor", function()
	assertEquals(Coins.forKill(1, 1, 1), 1)
	assertEquals(Coins.forKill(30, 1, 1), 30)
	assertEquals(Coins.forKill(30, 2, 1), 60)
end)

test("Coins: a bounty multiplies the coins for eating", function()
	assertEquals(Coins.forKill(30, 1, 3), 90)
	assertEquals(Coins.forKill(7, 1, 3), 21)
end)

test("Coins: invalid input gives no coins for a kill", function()
	assertEquals(Coins.forKill(0, 1, 1), 0)
	assertEquals(Coins.forKill(-3, 1, 1), 0)
	assertEquals(Coins.forKill(5, 0, 1), 0)
	assertEquals(Coins.forKill(5, 1, 0), 0)
	assertEquals(Coins.forKill(0 / 0, 1, 1), 0)
	assertEquals(Coins.forKill(5, 1, math.huge), 0)
end)
