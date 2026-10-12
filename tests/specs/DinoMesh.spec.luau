--!strict
local DinoLooks = require("../../src/shared/Config/DinoLooks")
local DinoMesh = require("../../src/shared/DinoMesh")
local DinoMeshes = require("../../src/shared/Config/DinoMeshes")
local Dinos = require("../../src/shared/Config/Dinos")
local Framework = require("../Framework")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertTrue = Framework.assertTrue

local color = { r = 10, g = 20, b = 30 }
local other = { r = 200, g = 100, b = 50 }
local fixed = { eyes = { r = 240, g = 160, b = 20 }, dark = { r = 5, g = 5, b = 5 } }

local function spec(name: string, role: string): any
	return {
		name = name,
		meshId = 1234,
		role = role,
		size = { x = 1, y = 1, z = 1 },
		offset = { x = 0, y = 0, z = 0 },
	}
end

local function templates(): any
	return {
		runner = { root = "Body", parts = { spec("Body", "body"), spec("Accent", "accent"), spec("Eyes", "eyes") } },
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

test("DinoMesh: the real config is valid", function()
	local errors = DinoMesh.validate(DinoMeshes.templates, DinoMeshes.dinos, DinoMeshes.fixed, DinoLooks.maxParts)
	assertEquals(#errors, 0, table.concat(errors, "; "))
end)

test("DinoMesh: every hand-written entry belongs to a dino with a hand-written look", function()
	for id in DinoMeshes.dinos do
		assertTrue(DinoLooks.looks[id] ~= nil, id .. " has no hand-written look")
	end
	local known: { [string]: boolean } = {}
	for _, stage in Dinos do
		known[stage.id] = true
	end
	for id in DinoMeshes.dinos do
		assertTrue(known[id], id .. " is not a dino")
	end
end)

test("DinoMesh: a dino with a plan for a known shape uses the colors of its plan", function()
	local plans = { dromaeo = { template = "runner", body = color, accent = other } }
	local entry = DinoMesh.resolve("dromaeo", plans, {}, templates())
	assertTrue(entry ~= nil)
	assertEquals(entry and entry.template, "runner")
	assertEquals(entry and entry.body, color)
	assertEquals(entry and entry.accent, other)
end)

test("DinoMesh: a dino whose shape has no template keeps its placeholder", function()
	local plans = { trike = { template = "horned", body = color, accent = other } }
	assertEquals(DinoMesh.resolve("trike", plans, {}, templates()), nil)
	assertEquals(DinoMesh.resolve("unknown", plans, {}, templates()), nil)
end)

test("DinoMesh: a hand-written entry wins over the plan", function()
	local plans = { raptor = { template = "runner", body = color, accent = color } }
	local entries = { raptor = { template = "runner", body = other, accent = other } }
	local entry = DinoMesh.resolve("raptor", plans, entries, templates())
	assertEquals(entry and entry.body, other)
end)

test("DinoMesh: an entry for an unknown template is ignored when resolving and reported", function()
	local entries = { raptor = { template = "nothing", body = color, accent = color } }
	assertEquals(DinoMesh.resolve("raptor", {}, entries, templates()), nil)
	assertTrue(contains(DinoMesh.validate(templates(), entries, fixed, 12), "unknown template"))
end)

test("DinoMesh: body and accent follow the dino, eyes and dark stay fixed", function()
	local entry = { template = "runner", body = color, accent = other }
	assertEquals(DinoMesh.colorFor("body", entry, fixed), color)
	assertEquals(DinoMesh.colorFor("accent", entry, fixed), other)
	assertEquals(DinoMesh.colorFor("eyes", entry, fixed), fixed.eyes)
	assertEquals(DinoMesh.colorFor("dark", entry, fixed), fixed.dark)
	assertTrue(DinoMesh.isVaried("body") and DinoMesh.isVaried("accent"))
	assertTrue(not DinoMesh.isVaried("eyes") and not DinoMesh.isVaried("dark"))
end)

test("DinoMesh: a valid template has no errors", function()
	assertEquals(#DinoMesh.validate(templates(), {}, fixed, 12), 0)
end)

test("DinoMesh: the part count must stay in the budget", function()
	assertTrue(
		contains(DinoMesh.validate({ runner = { root = "Body", parts = {} } }, {}, fixed, 12), "needs 1 to 12 parts")
	)
	assertTrue(contains(DinoMesh.validate(templates(), {}, fixed, 2), "needs 1 to 2 parts"))
end)

test("DinoMesh: bad parts are reported", function()
	local bad = templates()
	bad.runner.parts[2].name = "Body"
	bad.runner.parts[1].meshId = 0
	bad.runner.parts[3].role = "tail"
	bad.runner.parts[3].size.x = -1
	bad.runner.parts[3].offset.y = 0 / 0
	local errors = DinoMesh.validate(bad, {}, fixed, 12)
	assertTrue(contains(errors, "duplicate part name"))
	assertTrue(contains(errors, "mesh id must be a positive number"))
	assertTrue(contains(errors, "unknown role"))
	assertTrue(contains(errors, "size must be positive"))
	assertTrue(contains(errors, "offset must be finite"))
end)

test("DinoMesh: a template needs a body part to color", function()
	local noBody: any = { runner = { root = "Eyes", parts = { spec("Eyes", "eyes") } } }
	assertTrue(contains(DinoMesh.validate(noBody, {}, fixed, 12), "no body part"))
end)

test("DinoMesh: colors outside 0 to 255 are reported", function()
	local entries = { raptor = { template = "runner", body = { r = 300, g = 0, b = 0 }, accent = color } }
	assertTrue(contains(DinoMesh.validate(templates(), entries, fixed, 12), "colors must be between 0 and 255"))
	local brokenFixed = { eyes = { r = 0, g = -1, b = 0 }, dark = fixed.dark }
	assertTrue(contains(DinoMesh.validate(templates(), {}, brokenFixed, 12), "fixed colors"))
end)

local function withLimbs(): any
	local template = templates()
	template.runner.parts[2].limb = "legLeft"
	template.runner.parts[2].joint = { x = 0, y = 0, z = 0 }
	return template
end

test("DinoMesh: a moving part with a joint is valid", function()
	assertEquals(#DinoMesh.validate(withLimbs(), {}, fixed, 12), 0)
end)

test("DinoMesh: a moving part needs a known limb, a joint and a root to hang on", function()
	local noJoint = withLimbs()
	noJoint.runner.parts[2].joint = nil
	assertTrue(contains(DinoMesh.validate(noJoint, {}, fixed, 12), "needs a joint"))

	local unknown = withLimbs()
	unknown.runner.parts[2].limb = "wing"
	assertTrue(contains(DinoMesh.validate(unknown, {}, fixed, 12), "unknown limb"))

	local badJoint = withLimbs()
	badJoint.runner.parts[2].joint = { x = 0, y = 0 / 0, z = 0 }
	assertTrue(contains(DinoMesh.validate(badJoint, {}, fixed, 12), "joint must be finite"))

	local lonely = templates()
	lonely.runner.parts[2].joint = { x = 0, y = 0, z = 0 }
	assertTrue(contains(DinoMesh.validate(lonely, {}, fixed, 12), "joint needs a limb"))
end)

test("DinoMesh: a limb is used once and the root part does not move", function()
	local twice = withLimbs()
	twice.runner.parts[3].limb = "legLeft"
	twice.runner.parts[3].joint = { x = 0, y = 0, z = 0 }
	assertTrue(contains(DinoMesh.validate(twice, {}, fixed, 12), "used twice"))

	local moving = withLimbs()
	moving.runner.root = "Accent"
	moving.runner.parts[3].limb = "tail"
	moving.runner.parts[3].joint = { x = 0, y = 0, z = 0 }
	assertTrue(contains(DinoMesh.validate(moving, {}, fixed, 12), "root part cannot be a moving part"))

	local missing = templates()
	missing.runner.root = "Nothing"
	assertTrue(contains(DinoMesh.validate(missing, {}, fixed, 12), "does not exist"))
end)

test("DinoMesh: the real runner moves its legs and its tail", function()
	local limbs: { [string]: boolean } = {}
	for _, part in DinoMeshes.templates.runner.parts do
		if part.limb ~= nil then
			limbs[part.limb] = true
		end
	end
	assertTrue(limbs.legLeft and limbs.legRight and limbs.tail)
end)
