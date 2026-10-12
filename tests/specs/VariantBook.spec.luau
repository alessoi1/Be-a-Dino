--!strict
local Framework = require("../Framework")
local VariantBook = require("../../src/shared/VariantBook")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertTrue = Framework.assertTrue

local dinoIds = { compy = true, raptor = true, trex = true }
local variantIds = { glowing = true, gold = true, shadow = true, rainbow = true }
local dinoOrder = { "compy", "raptor", "trex" }
local variantOrder = { "glowing", "gold", "shadow", "rainbow" }

local function newState(): VariantBook.State
	return { variants = {}, equippedVariants = {} }
end

test("VariantBook: granting adds a variant once", function()
	local state = newState()
	assertEquals(VariantBook.grant(state, "compy", "gold", dinoIds, variantIds), "granted")
	assertTrue(VariantBook.owns(state, "compy", "gold"))
	assertTrue(not VariantBook.owns(state, "compy", "glowing"))
	assertTrue(not VariantBook.owns(state, "raptor", "gold"), "per dino")
	assertEquals(VariantBook.grant(state, "compy", "gold", dinoIds, variantIds), "duplicate")
	assertEquals(VariantBook.count(state), 1)
end)

test("VariantBook: unknown dinos and variants are refused", function()
	local state = newState()
	assertEquals(VariantBook.grant(state, "pterodactyl", "gold", dinoIds, variantIds), "unknown")
	assertEquals(VariantBook.grant(state, "compy", "chrome", dinoIds, variantIds), "unknown")
	assertEquals(VariantBook.count(state), 0)
	assertEquals(next(state.variants), nil)
end)

test("VariantBook: count adds up over all dinos", function()
	local state = newState()
	VariantBook.grant(state, "compy", "gold", dinoIds, variantIds)
	VariantBook.grant(state, "compy", "rainbow", dinoIds, variantIds)
	VariantBook.grant(state, "trex", "shadow", dinoIds, variantIds)
	assertEquals(VariantBook.count(state), 3)
end)

test("VariantBook: only an owned variant can be shown, the normal look always", function()
	local state = newState()
	local ok, reason = VariantBook.canEquip(state, "compy", "gold", "normal", dinoIds, variantIds)
	assertTrue(not ok)
	assertEquals(reason, "not_owned")
	VariantBook.grant(state, "compy", "gold", dinoIds, variantIds)
	assertTrue((VariantBook.canEquip(state, "compy", "gold", "normal", dinoIds, variantIds)))
	assertTrue((VariantBook.canEquip(state, "compy", "normal", "normal", dinoIds, variantIds)))
end)

test("VariantBook: canEquip names the other reasons", function()
	local state = newState()
	assertEquals(
		select(2, VariantBook.canEquip(state, "pterodactyl", "gold", "normal", dinoIds, variantIds)),
		"unknown_dino"
	)
	assertEquals(
		select(2, VariantBook.canEquip(state, "compy", "chrome", "normal", dinoIds, variantIds)),
		"unknown_variant"
	)
	assertEquals(
		select(2, VariantBook.canEquip(state, 5 :: any, "gold", "normal", dinoIds, variantIds)),
		"unknown_dino"
	)
	assertEquals(
		select(2, VariantBook.canEquip(state, "compy", 5 :: any, "normal", dinoIds, variantIds)),
		"unknown_variant"
	)
end)

test("VariantBook: equip shows the variant and the normal look removes the choice", function()
	local state = newState()
	VariantBook.grant(state, "compy", "gold", dinoIds, variantIds)
	VariantBook.equip(state, "compy", "gold", "normal")
	assertEquals(VariantBook.resolve(state, "compy"), "gold")
	assertEquals(VariantBook.resolve(state, "raptor"), nil)
	VariantBook.equip(state, "compy", "normal", "normal")
	assertEquals(VariantBook.resolve(state, "compy"), nil)
	assertEquals(next(state.equippedVariants), nil)
end)

test("VariantBook: a chosen variant that is not owned any more is not shown", function()
	local state = newState()
	state.equippedVariants.compy = "gold"
	assertEquals(VariantBook.resolve(state, "compy"), nil)
end)

test("VariantBook: rows list the normal look first, then every variant", function()
	local rows = VariantBook.rows(variantOrder, "normal", { gold = true, rainbow = true }, "gold")
	assertEquals(#rows, 5)
	assertEquals(rows[1].id, "normal")
	assertEquals(rows[1].status, "available")
	assertEquals(rows[2].id, "glowing")
	assertEquals(rows[2].status, "locked")
	assertEquals(rows[3].status, "equipped")
	assertEquals(rows[4].status, "locked")
	assertEquals(rows[5].status, "available")
end)

test("VariantBook: without a choice the normal look is shown", function()
	local rows = VariantBook.rows(variantOrder, "normal", { gold = true }, nil)
	assertEquals(rows[1].status, "equipped")
	assertEquals(rows[3].status, "available")
end)

test("VariantBook: owned variants are written in a fixed order and read back", function()
	local state = newState()
	VariantBook.grant(state, "trex", "rainbow", dinoIds, variantIds)
	VariantBook.grant(state, "compy", "gold", dinoIds, variantIds)
	VariantBook.grant(state, "compy", "glowing", dinoIds, variantIds)
	local text = VariantBook.encodeOwned(state, dinoOrder, variantOrder)
	assertEquals(text, "compy:glowing+gold,trex:rainbow")
	local decoded = VariantBook.decodeOwned(text)
	assertTrue(decoded.compy.glowing and decoded.compy.gold and decoded.trex.rainbow)
	assertTrue(decoded.raptor == nil)
	assertEquals(VariantBook.encodeOwned(newState(), dinoOrder, variantOrder), "")
end)

test("VariantBook: decodeOwned ignores broken parts and limits the entries", function()
	local decoded = VariantBook.decodeOwned("compy:gold,,bad id:gold,raptor:,trex:rain bow,x:y+z")
	assertTrue(decoded.compy ~= nil and decoded.compy.gold)
	assertTrue(decoded.raptor == nil)
	assertTrue(decoded["bad id"] == nil)
	assertEquals(next(VariantBook.decodeOwned("")), nil)
	local parts = {}
	for index = 1, 200 do
		table.insert(parts, "dino" .. index .. ":gold")
	end
	local count = 0
	for _ in VariantBook.decodeOwned(table.concat(parts, ",")) do
		count += 1
	end
	assertTrue(count <= VariantBook.MAX_DINOS)
end)

test("VariantBook: the shown variants are written sorted and read back", function()
	local text = VariantBook.encodeEquipped({ trex = "rainbow", compy = "gold" })
	assertEquals(text, "compy=gold,trex=rainbow")
	local decoded = VariantBook.decodeEquipped(text)
	assertEquals(decoded.compy, "gold")
	assertEquals(decoded.trex, "rainbow")
	assertEquals(VariantBook.encodeEquipped({}), "")
	local junk = VariantBook.decodeEquipped("compy=gold,x=,=y,trex=Rain bow,a=b=c")
	assertEquals(junk.compy, "gold")
	assertEquals(junk.x, nil)
	assertEquals(junk.trex, nil)
end)
