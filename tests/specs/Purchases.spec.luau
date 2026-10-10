--!strict
local Framework = require("../Framework")
local Purchases = require("../../src/shared/Purchases")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertTrue = Framework.assertTrue

local skins: { Purchases.Skin } = {
	{ id = "a_default", dinoId = "a", unlock = { kind = "free" } },
	{ id = "a_earned", dinoId = "a", unlock = { kind = "reach", stageId = "b" } },
	{ id = "a_paid", dinoId = "a", unlock = { kind = "product", productId = 111 } },
	{ id = "b_paid", dinoId = "b", unlock = { kind = "product", productId = 222 } },
	{ id = "b_unlisted", dinoId = "b", unlock = { kind = "product", productId = 0 } },
}

test("Purchases: a product id finds its skin", function()
	local skin = Purchases.skinForProduct(skins, 222)
	assertEquals(skin and skin.id, "b_paid")
end)

test("Purchases: unknown, zero and invalid product ids find nothing", function()
	assertEquals(Purchases.skinForProduct(skins, 999), nil)
	assertEquals(Purchases.skinForProduct(skins, 0), nil, "0 means not for sale")
	assertEquals(Purchases.skinForProduct(skins, -5), nil)
	assertEquals(Purchases.skinForProduct(skins, 0 / 0), nil)
	assertEquals(Purchases.skinForProduct(skins, "111" :: any), nil)
end)

test("Purchases: apply grants the skin once", function()
	local owned: { [string]: boolean } = {}
	local outcome, skin = Purchases.apply(skins, owned, 111)
	assertEquals(outcome, "granted")
	assertEquals(skin and skin.id, "a_paid")
	assertTrue(owned.a_paid)
end)

test("Purchases: the same receipt twice gives the skin only once", function()
	local owned: { [string]: boolean } = {}
	Purchases.apply(skins, owned, 111)
	local outcome = Purchases.apply(skins, owned, 111)
	assertEquals(outcome, "duplicate")
	local count = 0
	for _ in owned do
		count += 1
	end
	assertEquals(count, 1)
end)

test("Purchases: an unknown product grants nothing", function()
	local owned: { [string]: boolean } = {}
	local outcome, skin = Purchases.apply(skins, owned, 999)
	assertEquals(outcome, "unknown_product")
	assertEquals(skin, nil)
	assertEquals(next(owned), nil)
end)

test("Purchases: a product that is not for sale (id 0) grants nothing", function()
	local owned: { [string]: boolean } = {}
	assertEquals((Purchases.apply(skins, owned, 0)), "unknown_product")
	assertEquals(next(owned), nil)
end)

test("Purchases: grant refuses skins that are not products", function()
	local owned: { [string]: boolean } = {}
	assertEquals(Purchases.grant(owned, skins[1]), "not_a_product")
	assertEquals(Purchases.grant(owned, skins[2]), "not_a_product")
	assertEquals(next(owned), nil)
end)
