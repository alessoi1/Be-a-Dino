--!strict
local Framework = require("../Framework")
local SkinConfig = require("../../src/shared/Config/Skins")
local SkinView = require("../../src/shared/SkinView")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertTrue = Framework.assertTrue

local skins = SkinConfig.skins

test("SkinView: encodeEquipped writes dino=skin pairs", function()
	local text = SkinView.encodeEquipped({ raptor = "raptor_default", compy = "compy_mint" })
	assertEquals(text, "compy=compy_mint,raptor=raptor_default")
	assertEquals(SkinView.encodeEquipped({}), "")
end)

test("SkinView: decodeEquipped reads it back", function()
	local equipped = SkinView.decodeEquipped("compy=compy_mint,raptor=raptor_default")
	assertEquals(equipped.compy, "compy_mint")
	assertEquals(equipped.raptor, "raptor_default")
end)

test("SkinView: decodeEquipped ignores broken parts", function()
	local equipped = SkinView.decodeEquipped("compy=compy_mint,,=x,stego=,trex=Bad Id,raptor,a=b=c,ok=fine_one")
	assertEquals(equipped.compy, "compy_mint")
	assertEquals(equipped.ok, "fine_one")
	assertEquals(equipped.stego, nil)
	assertEquals(equipped.trex, nil)
	assertEquals(equipped.raptor, nil)
	assertEquals(equipped.a, nil)
end)

test("SkinView: decodeEquipped handles empty input and limits the entries", function()
	assertEquals(next(SkinView.decodeEquipped("")), nil)
	local parts = {}
	for index = 1, 200 do
		table.insert(parts, "dino" .. index .. "=skin" .. index)
	end
	local equipped = SkinView.decodeEquipped(table.concat(parts, ","))
	local count = 0
	for _ in equipped do
		count += 1
	end
	assertTrue(count <= SkinView.MAX_ENTRIES)
end)

test("SkinView: encodeUnlocked lists the ids in config order", function()
	assertEquals(SkinView.encodeUnlocked({ "compy_default", "compy_mint" }), "compy_default,compy_mint")
end)

test("SkinView: rows mark equipped, available and locked skins", function()
	local unlocked = { compy_default = true, compy_mint = true }
	local rows = SkinView.rows(skins, "compy", unlocked, "compy_mint")
	assertEquals(#rows, 2, "the product skin without a product id is hidden")
	assertEquals(rows[1].skin.id, "compy_default")
	assertEquals(rows[1].status, "available")
	assertEquals(rows[2].skin.id, "compy_mint")
	assertEquals(rows[2].status, "equipped")
end)

test("SkinView: a locked skin is shown as locked", function()
	local rows = SkinView.rows(skins, "raptor", { raptor_default = true }, nil)
	assertEquals(rows[1].status, "equipped", "the default is shown while nothing else is chosen")
	assertEquals(rows[2].skin.id, "raptor_sunset")
	assertEquals(rows[2].status, "locked")
end)

test("SkinView: without a choice the default is equipped", function()
	local rows = SkinView.rows(skins, "trex", { trex_default = true }, nil)
	assertEquals(rows[1].status, "equipped")
end)

test("SkinView: a product skin with a product id is shown", function()
	local withProduct: { SkinView.Skin } = {
		{ id = "x_default", dinoId = "x", unlock = { kind = "free" } },
		{ id = "x_paid", dinoId = "x", unlock = { kind = "product", productId = 123 } },
	}
	local rows = SkinView.rows(withProduct, "x", { x_default = true }, nil)
	assertEquals(#rows, 2)
	assertEquals(rows[2].status, "locked")
end)
