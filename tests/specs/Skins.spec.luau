--!strict
local Dinos = require("../../src/shared/Config/Dinos")
local Framework = require("../Framework")
local SkinConfig = require("../../src/shared/Config/Skins")
local Skins = require("../../src/shared/Skins")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertTrue = Framework.assertTrue

local skins = SkinConfig.skins

local function state(): Skins.State
	return {
		reachedStages = { compy = true },
		bestPoints = 0,
		ownedSkins = {},
		equippedSkins = {},
	}
end

local function contains(errors: { string }, text: string): boolean
	for _, message in errors do
		if string.find(message, text, 1, true) ~= nil then
			return true
		end
	end
	return false
end

test("Skins: the real config is valid", function()
	local errors = Skins.validate(skins, Dinos, SkinConfig.maxIdLength)
	assertEquals(table.concat(errors, "; "), "")
end)

test("Skins: free skins are always unlocked", function()
	local skin = Skins.find(skins, "compy_default")
	assertTrue(skin ~= nil and Skins.isUnlocked(skin, state()))
end)

test("Skins: a reach skin needs the stage", function()
	local skin = Skins.find(skins, "compy_mint") :: Skins.Skin
	local s = state()
	assertTrue(not Skins.isUnlocked(skin, s))
	s.reachedStages.raptor = true
	assertTrue(Skins.isUnlocked(skin, s))
end)

test("Skins: a best skin needs the best round", function()
	local skin = Skins.find(skins, "trex_gold") :: Skins.Skin
	local s = state()
	s.bestPoints = 999
	assertTrue(not Skins.isUnlocked(skin, s))
	s.bestPoints = 1000
	assertTrue(Skins.isUnlocked(skin, s))
end)

test("Skins: a product skin needs to be owned", function()
	local skin = Skins.find(skins, "compy_berry") :: Skins.Skin
	local s = state()
	assertTrue(not Skins.isUnlocked(skin, s))
	s.ownedSkins.compy_berry = true
	assertTrue(Skins.isUnlocked(skin, s))
end)

test("Skins: unlockedIds lists the available skins in config order", function()
	local s = state()
	s.reachedStages.raptor = true
	s.reachedStages.stego = true
	local ids = Skins.unlockedIds(skins, s)
	assertEquals(
		table.concat(ids, ","),
		"compy_default,compy_mint,raptor_default,raptor_sunset,stego_default,trex_default"
	)
end)

test("Skins: canEquip gives the reason for a refusal", function()
	local s = state()
	local ok, reason = Skins.canEquip(skins, s, "does_not_exist")
	assertTrue(not ok)
	assertEquals(reason, "unknown_skin")

	local notReached = Skins.canEquip(skins, s, "raptor_default")
	assertTrue(not notReached, "dino not reached yet")
	local _, reasonDino = Skins.canEquip(skins, s, "raptor_default")
	assertEquals(reasonDino, "not_reached")

	s.reachedStages.raptor = true
	local _, reasonLocked = Skins.canEquip(skins, s, "raptor_sunset")
	assertEquals(reasonLocked, "locked")

	assertTrue((Skins.canEquip(skins, s, "raptor_default")))
	s.reachedStages.stego = true
	assertTrue((Skins.canEquip(skins, s, "raptor_sunset")))
end)

test("Skins: resolve gives the chosen skin or falls back to the default", function()
	local s = state()
	s.reachedStages.raptor = true
	assertEquals((Skins.resolve(skins, s, "compy") :: Skins.Skin).id, "compy_default")
	s.equippedSkins.compy = "compy_mint"
	assertEquals((Skins.resolve(skins, s, "compy") :: Skins.Skin).id, "compy_mint")
	s.equippedSkins.compy = "raptor_default"
	assertEquals((Skins.resolve(skins, s, "compy") :: Skins.Skin).id, "compy_default", "skin of another dino")
	s.equippedSkins.compy = "compy_berry"
	assertEquals((Skins.resolve(skins, s, "compy") :: Skins.Skin).id, "compy_default", "locked skin")
	s.equippedSkins.compy = "gone"
	assertEquals((Skins.resolve(skins, s, "compy") :: Skins.Skin).id, "compy_default", "unknown skin")
end)

test("Skins: resolve for an unknown dino is nil", function()
	assertEquals(Skins.resolve(skins, state(), "pterodactyl"), nil)
end)

test("Skins: validate reports broken configs", function()
	local function skin(id: string, dinoId: string, unlock: any, colors: any?): Skins.Skin
		return { id = id, dinoId = dinoId, unlock = unlock, colors = colors }
	end
	local full = {
		skin("a_default", "compy", { kind = "free" }),
		skin("b_default", "raptor", { kind = "free" }),
		skin("c_default", "stego", { kind = "free" }),
		skin("d_default", "trex", { kind = "free" }),
	}
	assertEquals(#Skins.validate(full, Dinos, 32), 0)

	local noDefault = { skin("a_default", "compy", { kind = "free" }) }
	assertTrue(contains(Skins.validate(noDefault, Dinos, 32), "default skin"))

	local twoDefaults = table.clone(full)
	table.insert(twoDefaults, skin("a_other", "compy", { kind = "free" }))
	assertTrue(contains(Skins.validate(twoDefaults, Dinos, 32), "default skin"))

	local duplicate = table.clone(full)
	table.insert(duplicate, skin("a_default", "compy", { kind = "reach", stageId = "raptor" }))
	assertTrue(contains(Skins.validate(duplicate, Dinos, 32), "duplicate"))

	local unknownDino = table.clone(full)
	table.insert(unknownDino, skin("x", "pterodactyl", { kind = "free" }))
	assertTrue(contains(Skins.validate(unknownDino, Dinos, 32), "unknown dino"))

	local badId = table.clone(full)
	table.insert(badId, skin("Bad Id", "compy", { kind = "reach", stageId = "raptor" }))
	assertTrue(contains(Skins.validate(badId, Dinos, 32), "id"))

	local badReach = table.clone(full)
	table.insert(badReach, skin("r1", "compy", { kind = "reach", stageId = "pterodactyl" }))
	assertTrue(contains(Skins.validate(badReach, Dinos, 32), "reach"))

	local badBest = table.clone(full)
	table.insert(badBest, skin("b1", "compy", { kind = "best", points = 0 }))
	assertTrue(contains(Skins.validate(badBest, Dinos, 32), "best"))

	local badProduct = table.clone(full)
	table.insert(badProduct, skin("p1", "compy", { kind = "product", productId = -1 }))
	assertTrue(contains(Skins.validate(badProduct, Dinos, 32), "product"))

	local sameProduct = table.clone(full)
	table.insert(sameProduct, skin("p2", "compy", { kind = "product", productId = 55 }))
	table.insert(sameProduct, skin("p3", "raptor", { kind = "product", productId = 55 }))
	assertTrue(contains(Skins.validate(sameProduct, Dinos, 32), "product id"))

	local unlisted = table.clone(full)
	table.insert(unlisted, skin("p4", "compy", { kind = "product", productId = 0 }))
	table.insert(unlisted, skin("p5", "raptor", { kind = "product", productId = 0 }))
	assertEquals(#Skins.validate(unlisted, Dinos, 32), 0, "several skins may wait with id 0")

	local badKind = table.clone(full)
	table.insert(badKind, skin("k1", "compy", { kind = "magic" }))
	assertTrue(contains(Skins.validate(badKind, Dinos, 32), "unlock kind"))

	local badColor = table.clone(full)
	table.insert(
		badColor,
		skin(
			"c1",
			"compy",
			{ kind = "reach", stageId = "raptor" },
			{ body = { r = 300, g = 0, b = 0 }, accent = { r = 0, g = 0, b = 0 } }
		)
	)
	assertTrue(contains(Skins.validate(badColor, Dinos, 32), "color"))
end)
