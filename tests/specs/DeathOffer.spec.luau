--!strict
local DeathOffer = require("../../src/shared/DeathOffer")
local Framework = require("../Framework")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertTrue = Framework.assertTrue

local available = { lobby = true }

test("DeathOffer: an offer lasts for the given seconds", function()
	local offer = DeathOffer.open(100, 15, 42, "Anna")
	assertEquals(offer.killerId, 42)
	assertEquals(offer.killerName, "Anna")
	assertEquals(DeathOffer.remaining(offer, 100), 15)
	assertEquals(DeathOffer.remaining(offer, 110), 5)
	assertEquals(DeathOffer.remaining(offer, 115), 0)
	assertEquals(DeathOffer.remaining(offer, 500), 0)
	assertTrue(DeathOffer.isOpen(offer, 114.9))
	assertTrue(not DeathOffer.isOpen(offer, 115))
end)

test("DeathOffer: no offer is never open", function()
	assertEquals(DeathOffer.remaining(nil, 100), 0)
	assertTrue(not DeathOffer.isOpen(nil, 100))
end)

test("DeathOffer: back to lobby is allowed while the offer is open", function()
	local offer = DeathOffer.open(100, 15, 42, "Anna")
	local ok, reason = DeathOffer.check(offer, "lobby", 105, available)
	assertTrue(ok)
	assertEquals(reason, nil)
end)

test("DeathOffer: the paid choices are not available yet", function()
	local offer = DeathOffer.open(100, 15, 42, "Anna")
	local ok, reason = DeathOffer.check(offer, "revive", 105, available)
	assertTrue(not ok)
	assertEquals(reason, "unavailable")
	assertEquals(select(2, DeathOffer.check(offer, "bounty", 105, available)), "unavailable")
	assertTrue((DeathOffer.check(offer, "bounty", 105, { lobby = true, bounty = true })), "once available")
end)

test("DeathOffer: unknown or invalid choices are refused", function()
	local offer = DeathOffer.open(100, 15, 42, "Anna")
	assertEquals(select(2, DeathOffer.check(offer, "teleport", 105, available)), "bad_choice")
	assertEquals(select(2, DeathOffer.check(offer, 5, 105, available)), "bad_choice")
	assertEquals(select(2, DeathOffer.check(offer, nil, 105, available)), "bad_choice")
	assertEquals(select(2, DeathOffer.check(offer, "", 105, available)), "bad_choice")
end)

test("DeathOffer: without an offer or after the time nothing can be chosen", function()
	assertEquals(select(2, DeathOffer.check(nil, "lobby", 105, available)), "no_offer")
	local offer = DeathOffer.open(100, 15, 42, "Anna")
	assertEquals(select(2, DeathOffer.check(offer, "lobby", 115, available)), "expired")
	assertEquals(select(2, DeathOffer.check(offer, "lobby", 999, available)), "expired")
end)

test("DeathOffer: an offer can be used only once", function()
	local offer = DeathOffer.open(100, 15, 42, "Anna")
	local used = DeathOffer.use(offer)
	assertTrue(used.used)
	assertTrue(not offer.used, "the old offer is not changed")
	assertEquals(select(2, DeathOffer.check(used, "lobby", 105, available)), "used")
	assertEquals(DeathOffer.remaining(used, 105), 0)
end)
