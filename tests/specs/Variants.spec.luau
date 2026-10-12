--!strict
local Framework = require("../Framework")
local VariantConfig = require("../../src/shared/Config/Variants")
local Variants = require("../../src/shared/Variants")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertTrue = Framework.assertTrue

local variants = VariantConfig.variants

local function contains(errors: { string }, text: string): boolean
	for _, message in errors do
		if string.find(message, text, 1, true) ~= nil then
			return true
		end
	end
	return false
end

local green: Variants.Color = { r = 100, g = 170, b = 90 }

test("Variants: the real config is valid and has the four variants", function()
	assertEquals(table.concat(Variants.validate(variants, VariantConfig.normalId), "; "), "")
	local ids: { string } = {}
	for _, variant in variants do
		table.insert(ids, variant.id)
	end
	assertEquals(table.concat(ids, ","), "glowing,gold,shadow,rainbow")
end)

test("Variants: lighten and darken move a color toward white or black", function()
	local lighter = Variants.lighten({ r = 100, g = 0, b = 255 }, 0.5)
	assertEquals(lighter.r, 178)
	assertEquals(lighter.g, 128)
	assertEquals(lighter.b, 255)
	local darker = Variants.darken({ r = 100, g = 200, b = 50 }, 0.5)
	assertEquals(darker.r, 50)
	assertEquals(darker.g, 100)
	assertEquals(darker.b, 25)
	assertEquals(Variants.lighten(green, 0).r, green.r)
	assertEquals(Variants.darken(green, 1).g, 0)
	assertEquals(Variants.lighten(green, 5).r, 255, "amounts are kept in range")
end)

test("Variants: hsv gives the pure colors at the sector borders", function()
	local red = Variants.fromHsv(0, 1, 1)
	assertEquals(red.r, 255)
	assertEquals(red.g, 0)
	assertEquals(red.b, 0)
	local greenPure = Variants.fromHsv(1 / 3, 1, 1)
	assertEquals(greenPure.g, 255)
	assertEquals(greenPure.r, 0)
	local blue = Variants.fromHsv(2 / 3, 1, 1)
	assertEquals(blue.b, 255)
	assertEquals(blue.r, 0)
	local white = Variants.fromHsv(0.5, 0, 1)
	assertTrue(white.r == 255 and white.g == 255 and white.b == 255, "no saturation is white")
	local black = Variants.fromHsv(0.5, 1, 0)
	assertTrue(black.r == 0 and black.g == 0 and black.b == 0, "no brightness is black")
end)

test("Variants: the hue wraps around", function()
	local a = Variants.fromHsv(0.25, 0.8, 0.9)
	local b = Variants.fromHsv(1.25, 0.8, 0.9)
	local c = Variants.fromHsv(-0.75, 0.8, 0.9)
	assertTrue(a.r == b.r and a.g == b.g and a.b == b.b)
	assertTrue(a.r == c.r and a.g == c.g and a.b == c.b)
end)

test("Variants: rainbow spreads the parts over the circle and the offset turns it", function()
	local first = Variants.rainbowColor(1, 4, 0, 1, 1)
	local third = Variants.rainbowColor(3, 4, 0, 1, 1)
	assertTrue(first.r ~= third.r or first.g ~= third.g or first.b ~= third.b, "different colors")
	local turned = Variants.rainbowColor(1, 4, 0.5, 1, 1)
	assertTrue(
		third.r == turned.r and third.g == turned.g and third.b == turned.b,
		"half a turn moves part 1 onto part 3"
	)
	local one = Variants.rainbowColor(1, 1, 0, 1, 1)
	assertEquals(one.r, 255)
end)

test("Variants: glowing makes every part lighter and neon", function()
	local glowing = Variants.find(variants, "glowing") :: Variants.Variant
	local look = Variants.appearance(glowing, green, "body", 1, 5, 0.75, 1)
	assertEquals(look.material, "Neon")
	assertTrue(look.color.r > green.r and look.color.g > green.g and look.color.b > green.b)
	local accent = Variants.appearance(glowing, { r = 10, g = 10, b = 10 }, "accent", 2, 5, 0.75, 1)
	assertTrue(accent.color.r > 10)
end)

test("Variants: gold replaces the colors by role and uses metal", function()
	local gold = Variants.find(variants, "gold") :: Variants.Variant
	local body = Variants.appearance(gold, green, "body", 1, 5, 0.75, 1)
	local accent = Variants.appearance(gold, green, "accent", 2, 5, 0.75, 1)
	assertEquals(body.material, "Metal")
	assertEquals(body.color.r, 255)
	assertEquals(body.color.g, 200)
	assertEquals(accent.color.g, 235)
end)

test("Variants: shadow darkens the body and gives the accent its own color", function()
	local shadow = Variants.find(variants, "shadow") :: Variants.Variant
	local body = Variants.appearance(shadow, { r = 100, g = 100, b = 100 }, "body", 1, 5, 0.75, 1)
	assertEquals(body.color.r, 20)
	local accent = Variants.appearance(shadow, { r = 100, g = 100, b = 100 }, "accent", 2, 5, 0.75, 1)
	assertEquals(accent.color.r, 150)
	assertEquals(accent.color.b, 230)
end)

test("Variants: rainbow starts from the circle colors with neon", function()
	local rainbow = Variants.find(variants, "rainbow") :: Variants.Variant
	local look = Variants.appearance(rainbow, green, "body", 1, 4, 1, 1)
	assertEquals(look.material, "Neon")
	assertEquals(look.color.r, 255)
	assertTrue(rainbow.animated == true)
end)

test("Variants: no variant ever makes a part see-through", function()
	for _, variant in variants do
		assertEquals(Variants.appearance(variant, green, "body", 1, 3, 0.75, 1).transparency, 0)
	end
end)

test("Variants: validate reports broken variants", function()
	local function variant(id: string, material: string): Variants.Variant
		return { id = id, material = material }
	end
	assertTrue(contains(Variants.validate({}, "normal"), "no variants"))
	assertTrue(contains(Variants.validate({ variant("a", "Neon"), variant("a", "Metal") }, "normal"), "duplicate"))
	assertTrue(
		contains(Variants.validate({ variant("normal", "Neon") }, "normal"), "duplicate"),
		"the normal id is taken"
	)
	assertTrue(contains(Variants.validate({ variant("Bad Id", "Neon") }, "normal"), "id"))
	assertTrue(contains(Variants.validate({ variant("a", "Lava") }, "normal"), "material"))
	local tooLight = variant("a", "Neon")
	tooLight.lighten = 2
	assertTrue(contains(Variants.validate({ tooLight }, "normal"), "lighten"))
	local badColor = variant("b", "Neon")
	badColor.body = { r = 300, g = 0, b = 0 }
	assertTrue(contains(Variants.validate({ badColor }, "normal"), "color"))
end)
