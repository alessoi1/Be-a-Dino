--!strict
local DinoBody = require("../../src/shared/DinoBody")
local DinoLook = require("../../src/shared/DinoLook")
local DinoLooks = require("../../src/shared/Config/DinoLooks")
local Framework = require("../Framework")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertTrue = Framework.assertTrue

local function plan(template: string, length: number, height: number, feature: number): DinoBody.Plan
	return {
		template = template,
		length = length,
		height = height,
		feature = feature,
		body = { r = 100, g = 150, b = 80 },
		accent = { r = 240, g = 200, b = 90 },
	}
end

local function eachCase(check: (template: string, p: DinoBody.Plan, label: string) -> ())
	for _, template in DinoBody.TEMPLATES do
		for _, length in { 0.6, 1, 1.6 } do
			for _, height in { 0.6, 1, 1.6 } do
				for _, feature in { 0, 0.5, 1 } do
					local label = string.format("%s L%s H%s F%s", template, length, height, feature)
					check(template, plan(template, length, height, feature), label)
				end
			end
		end
	end
end

test("DinoBody: every shape builds a valid look for the whole range of the plan", function()
	eachCase(function(_, p, label)
		local look = DinoBody.build(p)
		assertTrue(#look.parts >= 1 and #look.parts <= DinoLooks.maxParts, label .. ": " .. #look.parts .. " parts")
		local names: { [string]: boolean } = {}
		for _, part in look.parts do
			assertTrue(not names[part.name], label .. ": duplicate name " .. part.name)
			names[part.name] = true
			assertTrue(part.size.x > 0 and part.size.y > 0 and part.size.z > 0, label .. ": size of " .. part.name)
		end
	end)
end)

test("DinoBody: the feet stand on the floor and nothing is below it", function()
	eachCase(function(_, p, label)
		local lowest = DinoLook.lowestPoint(DinoBody.build(p))
		assertTrue(math.abs(lowest - DinoLook.FLOOR_OFFSET) < 0.05, label .. ": lowest point " .. lowest)
	end)
end)

test("DinoBody: every look has a body part and an accent part to recolor", function()
	eachCase(function(_, p, label)
		local roles: { [string]: boolean } = {}
		for _, part in DinoBody.build(p).parts do
			roles[part.role] = true
		end
		assertTrue(roles.body and roles.accent, label)
	end)
end)

test("DinoBody: the colors of the plan end up in the parts by role", function()
	local look = DinoBody.build(plan("biped", 1, 1, 0.5))
	for _, part in look.parts do
		if part.role == "accent" then
			assertEquals(part.color.r, 240)
		else
			assertEquals(part.color.r, 100)
		end
	end
end)

test("DinoBody: the same plan always gives the same look", function()
	local a = DinoBody.build(plan("armored", 1.2, 0.8, 0.3))
	local b = DinoBody.build(plan("armored", 1.2, 0.8, 0.3))
	assertEquals(#a.parts, #b.parts)
	for index, part in a.parts do
		assertEquals(part.offset.z, b.parts[index].offset.z)
		assertEquals(part.size.y, b.parts[index].size.y)
	end
end)

test("DinoBody: a longer plan makes a longer body", function()
	local short = DinoBody.build(plan("biped", 0.6, 1, 0.5))
	local long = DinoBody.build(plan("biped", 1.6, 1, 0.5))
	local function bodyLength(look: DinoBody.Look): number
		for _, part in look.parts do
			if part.name == "Body" then
				return part.size.z
			end
		end
		return 0
	end
	assertTrue(bodyLength(long) > bodyLength(short))
end)

test("DinoBody: a bigger feature adds plates, horns or a taller crest", function()
	local function count(template: string, feature: number): number
		return #DinoBody.build(plan(template, 1, 1, feature)).parts
	end
	assertTrue(count("armored", 1) > count("armored", 0), "plates")
	local function crestHeight(feature: number): number
		for _, part in DinoBody.build(plan("duckbill", 1, 1, feature)).parts do
			if part.name == "Crest" then
				return part.size.y
			end
		end
		return 0
	end
	assertTrue(crestHeight(1) > crestHeight(0))
end)

test("DinoBody: validatePlan accepts a good plan and reports the broken ones", function()
	assertEquals(#DinoBody.validatePlan(plan("biped", 1, 1, 0.5)), 0)
	assertTrue(#DinoBody.validatePlan(plan("flying", 1, 1, 0.5)) > 0, "unknown shape")
	assertTrue(#DinoBody.validatePlan(plan("biped", 0.1, 1, 0.5)) > 0, "too short")
	assertTrue(#DinoBody.validatePlan(plan("biped", 1, 5, 0.5)) > 0, "too tall")
	assertTrue(#DinoBody.validatePlan(plan("biped", 1, 1, 2)) > 0, "feature out of range")
	assertTrue(#DinoBody.validatePlan(plan("biped", 0 / 0, 1, 0.5)) > 0, "nan")
	local bad = plan("biped", 1, 1, 0.5)
	bad.body = { r = 300, g = 0, b = 0 }
	assertTrue(#DinoBody.validatePlan(bad) > 0, "color")
end)

test("DinoBody: an invalid plan gives an empty look", function()
	assertEquals(#DinoBody.build(plan("flying", 1, 1, 0.5)).parts, 0)
	assertEquals(#DinoBody.build(plan("biped", 9, 1, 0.5)).parts, 0)
end)
