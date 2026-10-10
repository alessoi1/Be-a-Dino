--!strict
local DinoLook = require("../../src/shared/DinoLook")
local DinoLooks = require("../../src/shared/Config/DinoLooks")
local Dinos = require("../../src/shared/Config/Dinos")
local Framework = require("../Framework")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertTrue = Framework.assertTrue

local function part(name: string): DinoLooks.PartSpec
	return {
		name = name,
		shape = "Block",
		size = { x = 1, y = 1, z = 1 },
		offset = { x = 0, y = 0, z = 0 },
		color = { r = 10, g = 20, b = 30 },
		role = "body",
	}
end

local stages = { { id = "a", minPoints = 0, scale = 1, speed = 1 } }

local function contains(errors: { string }, text: string): boolean
	for _, message in errors do
		if string.find(message, text, 1, true) ~= nil then
			return true
		end
	end
	return false
end

test("DinoLook: the real config is valid", function()
	local errors = DinoLook.validate(Dinos, DinoLooks.looks, DinoLooks.maxParts)
	assertEquals(table.concat(errors, "; "), "")
end)

test("DinoLook: a valid look has no errors", function()
	local looks = { a = { parts = { part("Body"), part("Head") } } }
	assertEquals(#DinoLook.validate(stages, looks, 12), 0)
end)

test("DinoLook: a stage without a look is reported", function()
	assertTrue(contains(DinoLook.validate(stages, {}, 12), "missing look for a"))
end)

test("DinoLook: a look for an unknown stage is reported", function()
	local looks = { a = { parts = { part("Body") } }, b = { parts = { part("Body") } } }
	assertTrue(contains(DinoLook.validate(stages, looks, 12), "unknown stage b"))
end)

test("DinoLook: part count must be between 1 and the budget", function()
	assertTrue(contains(DinoLook.validate(stages, { a = { parts = {} } }, 12), "no parts"))
	local many = { a = { parts = { part("A"), part("B"), part("C") } } }
	assertTrue(contains(DinoLook.validate(stages, many, 2), "too many parts"))
	assertEquals(#DinoLook.validate(stages, many, 3), 0)
end)

test("DinoLook: part names must be unique", function()
	local looks = { a = { parts = { part("Body"), part("Body") } } }
	assertTrue(contains(DinoLook.validate(stages, looks, 12), "duplicate part name"))
end)

test("DinoLook: sizes must be positive and finite", function()
	local zero = part("Body")
	zero.size.y = 0
	assertTrue(contains(DinoLook.validate(stages, { a = { parts = { zero } } }, 12), "size"))
	local nan = part("Body")
	nan.size.x = 0 / 0
	assertTrue(contains(DinoLook.validate(stages, { a = { parts = { nan } } }, 12), "size"))
end)

test("DinoLook: offsets must be finite", function()
	local far = part("Body")
	far.offset.z = math.huge
	assertTrue(contains(DinoLook.validate(stages, { a = { parts = { far } } }, 12), "offset"))
end)

test("DinoLook: colors must be between 0 and 255", function()
	local bad = part("Body")
	bad.color.g = 300
	assertTrue(contains(DinoLook.validate(stages, { a = { parts = { bad } } }, 12), "color"))
end)

test("DinoLook: the lowest point of a look stays near the floor", function()
	for id, look in DinoLooks.looks do
		local lowest = DinoLook.lowestPoint(look)
		assertTrue(math.abs(lowest - DinoLook.FLOOR_OFFSET) < 0.2, id .. " lowest point " .. lowest)
	end
end)

test("DinoLook: a part needs a known role", function()
	local bad: any = part("Body")
	bad.role = "shiny"
	assertTrue(contains(DinoLook.validate(stages, { a = { parts = { bad } } }, 12), "role"))
	local accent = part("Claw")
	accent.role = "accent"
	assertEquals(#DinoLook.validate(stages, { a = { parts = { part("Body"), accent } } }, 12), 0)
end)

test("DinoLook: every real look has a body part and an accent part to recolor", function()
	for id, look in DinoLooks.looks do
		local roles: { [string]: boolean } = {}
		for _, spec in look.parts do
			roles[spec.role] = true
		end
		assertTrue(roles.body and roles.accent, id .. " needs both roles")
	end
end)
