--!strict
local Framework = require("../Framework")
local OfferConfig = require("../../src/shared/Config/Offers")
local Offers = require("../../src/shared/Offers")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertNear = Framework.assertNear
local assertTrue = Framework.assertTrue

local config: Offers.Config = {
	products = { revive = 11, bounty = 12, growthPotion = 21, coinPotion = 22, speedPotion = 23, shieldPotion = 24 },
	potions = {
		growth = { product = "growthPotion", durationSeconds = 600, effect = "growth", factor = 2 },
		coin = { product = "coinPotion", durationSeconds = 600, effect = "coin", factor = 2 },
		speed = { product = "speedPotion", durationSeconds = 600, effect = "speed", factor = 1.15 },
		shield = { product = "shieldPotion", durationSeconds = 600, effect = "shield", bonusSeconds = 5 },
	},
	maxPotionSeconds = 1200,
	maxCredits = 2,
	receiptMemory = 3,
}

local function newState(): Offers.State
	return { potionSeconds = {}, credits = {}, receipts = {} }
end

test("Offers: the real config is valid", function()
	assertEquals(table.concat(Offers.validate(OfferConfig), "; "), "")
end)

test("Offers: validate reports broken configs", function()
	local function problems(change: (c: any) -> ()): number
		local copy: any = {
			products = { revive = 11, bounty = 12, growthPotion = 21 },
			potions = { growth = { product = "growthPotion", durationSeconds = 600, effect = "growth", factor = 2 } },
			maxPotionSeconds = 100,
			maxCredits = 1,
			receiptMemory = 1,
		}
		change(copy)
		return #Offers.validate(copy)
	end
	assertEquals(problems(function() end), 0)
	assertTrue(problems(function(c)
		c.products.revive = nil
	end) > 0, "missing revive")
	assertTrue(problems(function(c)
		c.products.bounty = 11
	end) > 0, "same id twice")
	assertTrue(problems(function(c)
		c.products.revive = 0
	end) > 0, "id 0")
	assertTrue(problems(function(c)
		c.potions.growth.factor = 1
	end) > 0, "factor must be above 1")
	assertTrue(problems(function(c)
		c.potions.growth.durationSeconds = 0
	end) > 0, "duration")
	assertTrue(problems(function(c)
		c.potions.growth.effect = "magic"
	end) > 0, "unknown effect")
	assertTrue(problems(function(c)
		c.potions.growth.product = "nothing"
	end) > 0, "unknown product")
	assertTrue(problems(function(c)
		c.potions.growth = { product = "growthPotion", durationSeconds = 5, effect = "shield" }
	end) > 0, "shield needs bonus")
end)

test("Offers: a product id is mapped to its offer", function()
	local revive = Offers.productFor(config, 11) :: Offers.Product
	assertEquals(revive.kind, "revive")
	assertEquals((Offers.productFor(config, 12) :: Offers.Product).kind, "bounty")
	local potion = Offers.productFor(config, 23) :: Offers.Product
	assertEquals(potion.kind, "potion")
	assertEquals(potion.potionId, "speed")
	assertEquals(Offers.productFor(config, 99), nil)
	assertEquals(Offers.productFor(config, 0), nil)
	assertEquals(Offers.productFor(config, 0 / 0), nil)
end)

test("Offers: a purchase gives a saved revive or bounty", function()
	local state = newState()
	local outcome = Offers.grant(state, config, 11, "p1")
	assertEquals(outcome, "granted")
	assertEquals(Offers.credits(state, "revive"), 1)
	assertEquals(Offers.grant(state, config, 12, "p2"), "granted")
	assertEquals(Offers.credits(state, "bounty"), 1)
end)

test("Offers: the same purchase id never grants twice", function()
	local state = newState()
	assertEquals(Offers.grant(state, config, 11, "p1"), "granted")
	assertEquals(Offers.grant(state, config, 11, "p1"), "duplicate")
	assertEquals(Offers.credits(state, "revive"), 1)
	assertEquals(Offers.grant(state, config, 21, "p3"), "granted")
	assertEquals(Offers.grant(state, config, 21, "p3"), "duplicate")
	assertEquals(Offers.potionSeconds(state, "growth"), 600)
end)

test("Offers: unknown products and bad purchase ids are refused", function()
	local state = newState()
	assertEquals((Offers.grant(state, config, 99, "p1")), "unknown_product")
	assertEquals((Offers.grant(state, config, 11, "")), "unknown_product")
	assertEquals(#state.receipts, 0)
end)

test("Offers: only the newest purchase ids are remembered", function()
	local state = newState()
	for index = 1, 5 do
		Offers.grant(state, config, 21, "p" .. index)
	end
	assertEquals(#state.receipts, 3)
	assertTrue(not Offers.hasReceipt(state, "p1"))
	assertTrue(Offers.hasReceipt(state, "p5"))
end)

test("Offers: saved credits stop at the limit and can be used", function()
	local state = newState()
	assertTrue(Offers.addCredit(state, "revive", 2))
	assertTrue(Offers.addCredit(state, "revive", 2))
	assertTrue(not Offers.addCredit(state, "revive", 2), "limit")
	assertTrue(not Offers.addCredit(state, "coins", 2), "unknown kind")
	assertTrue(Offers.takeCredit(state, "revive"))
	assertEquals(Offers.credits(state, "revive"), 1)
	assertTrue(Offers.takeCredit(state, "revive"))
	assertTrue(not Offers.takeCredit(state, "revive"), "none left")
	assertEquals(state.credits.revive, nil)
end)

test("Offers: potion time adds up to the limit", function()
	local state = newState()
	assertEquals(Offers.addPotion(state, "growth", 600, 1200), 600)
	assertEquals(Offers.addPotion(state, "growth", 600, 1200), 1200)
	assertEquals(Offers.addPotion(state, "growth", 600, 1200), 1200)
	assertEquals(Offers.addPotion(state, "coin", -5, 1200), 0)
	assertEquals(Offers.addPotion(state, "coin", 0 / 0, 1200), 0)
end)

test("Offers: potions count down and end", function()
	local state = newState()
	Offers.addPotion(state, "growth", 10, 100)
	Offers.addPotion(state, "coin", 3, 100)
	assertEquals(#Offers.tickPotions(state, 2), 0)
	assertNear(Offers.potionSeconds(state, "growth"), 8, 1e-9)
	local ended = Offers.tickPotions(state, 2)
	assertEquals(table.concat(ended, ","), "coin")
	assertTrue(not Offers.potionActive(state, "coin"))
	assertTrue(Offers.potionActive(state, "growth"))
	assertEquals(#Offers.tickPotions(state, -1), 0, "negative time changes nothing")
	assertEquals(#Offers.tickPotions(state, 0 / 0), 0)
	assertNear(Offers.potionSeconds(state, "growth"), 6, 1e-9)
end)

test("Offers: a running potion gives its factor, otherwise 1", function()
	local state = newState()
	assertEquals(Offers.factor(state, config, "growth"), 1)
	Offers.addPotion(state, "growth", 5, 100)
	assertEquals(Offers.factor(state, config, "growth"), 2)
	assertEquals(Offers.factor(state, config, "coin"), 1)
	Offers.addPotion(state, "speed", 5, 100)
	assertEquals(Offers.factor(state, config, "speed"), 1.15)
end)

test("Offers: the shield potion adds protection seconds only while it runs", function()
	local state = newState()
	assertEquals(Offers.shieldBonus(state, config), 0)
	Offers.addPotion(state, "shield", 5, 100)
	assertEquals(Offers.shieldBonus(state, config), 5)
	Offers.tickPotions(state, 10)
	assertEquals(Offers.shieldBonus(state, config), 0)
end)

test("Offers: the potion seconds are written and read back", function()
	local state = newState()
	Offers.addPotion(state, "coin", 119.2, 1200)
	Offers.addPotion(state, "growth", 540, 1200)
	local text = Offers.encodePotions(state, { "growth", "coin", "speed", "shield" })
	assertEquals(text, "growth=540,coin=120")
	local decoded = Offers.decodePotions(text)
	assertEquals(decoded.growth, 540)
	assertEquals(decoded.coin, 120)
	assertEquals(decoded.speed, nil)
	assertEquals(Offers.encodePotions(newState(), { "growth" }), "")
end)

test("Offers: reading junk potion text gives nothing wrong", function()
	assertEquals(next(Offers.decodePotions("")), nil)
	assertEquals(next(Offers.decodePotions("growth=abc,=5,coin=0")), nil)
	assertEquals(Offers.decodePotions("growth=5;;coin=7").coin, 7)
end)
