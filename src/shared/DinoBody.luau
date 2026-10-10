--!strict
-- Builds the placeholder look of a dino from a short plan (body shape, length, height, one
-- feature, two colors), so 50 dinos do not need 50 hand-written looks. The look is made for the
-- figure at scale 1: the feet stand on the floor (3 studs under the figure center), the front is
-- -Z, and it has at most 12 parts. Real models replace these placeholders later.
-- Pure: no Roblox services, no logging.

export type Color = { r: number, g: number, b: number }

export type Plan = {
	template: string,
	-- Stretches the body and the tail (1 = normal).
	length: number,
	-- Makes legs and body taller (1 = normal).
	height: number,
	-- What the shape adds (crest, ridge, plates, horns, neck), from 0 (little) to 1 (a lot).
	feature: number,
	body: Color,
	accent: Color,
}

export type PartSpec = {
	name: string,
	shape: "Block" | "Ball",
	size: { x: number, y: number, z: number },
	offset: { x: number, y: number, z: number },
	color: Color,
	role: "body" | "accent",
}

export type Look = { parts: { PartSpec } }

local DinoBody = {}

DinoBody.TEMPLATES = { "runner", "biped", "duckbill", "armored", "horned", "longneck" }

-- Height of the floor relative to the figure center (the same as DinoLook.FLOOR_OFFSET).
local FLOOR = -3
-- Body parts overlap their legs a little so nothing floats.
local OVERLAP = 0.1

local MIN_FACTOR = 0.6
local MAX_FACTOR = 1.6

local function isFinite(value: any): boolean
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function colorOk(color: any): boolean
	if type(color) ~= "table" then
		return false
	end
	for _, value in { color.r, color.g, color.b } do
		if not isFinite(value) or value < 0 or value > 255 then
			return false
		end
	end
	return true
end

-- Adds one block to the list.
local function add(
	parts: { PartSpec },
	plan: Plan,
	name: string,
	role: "body" | "accent",
	size: { number },
	offset: { number }
)
	table.insert(parts, {
		name = name,
		shape = "Block",
		size = { x = size[1], y = size[2], z = size[3] },
		offset = { x = offset[1], y = offset[2], z = offset[3] },
		color = if role == "accent" then plan.accent else plan.body,
		role = role,
	})
end

-- Center height of a leg of height `legHeight` that stands on the floor.
local function legY(legHeight: number): number
	return FLOOR + legHeight / 2
end

local function buildRunner(plan: Plan): { PartSpec }
	local parts: { PartSpec } = {}
	local length, height, feature = plan.length, plan.height, plan.feature
	local bodyLength, bodyHeight, bodyWidth = 2.4 * length, 1.1 * height, 0.9
	local legHeight = 1.4 * height
	local bodyY = FLOOR + legHeight + bodyHeight / 2 - OVERLAP
	local headY = bodyY + bodyHeight / 2 + 0.15
	local headZ = -(bodyLength / 2 + 0.4)
	local crestHeight = 0.3 + 0.6 * feature

	add(parts, plan, "LegLeft", "body", { 0.4, legHeight, 0.5 }, { -0.3, legY(legHeight), 0.3 })
	add(parts, plan, "LegRight", "body", { 0.4, legHeight, 0.5 }, { 0.3, legY(legHeight), 0.3 })
	add(parts, plan, "Body", "body", { bodyWidth, bodyHeight, bodyLength }, { 0, bodyY, 0 })
	add(parts, plan, "Head", "body", { 0.7, 0.7, 1.1 }, { 0, headY, headZ })
	add(parts, plan, "Tail", "body", { 0.45, 0.45, 2.0 * length }, { 0, bodyY, bodyLength / 2 + length })
	add(parts, plan, "ArmLeft", "accent", { 0.2, 0.2, 0.6 }, { -0.5, bodyY - 0.1, -bodyLength / 2 + 0.2 })
	add(parts, plan, "ArmRight", "accent", { 0.2, 0.2, 0.6 }, { 0.5, bodyY - 0.1, -bodyLength / 2 + 0.2 })
	add(parts, plan, "Crest", "accent", { 0.15, crestHeight, 0.7 }, { 0, headY + 0.35 + crestHeight / 2, headZ })
	return parts
end

local function buildBiped(plan: Plan): { PartSpec }
	local parts: { PartSpec } = {}
	local length, height, feature = plan.length, plan.height, plan.feature
	local bodyLength, bodyHeight, bodyWidth = 3.0 * length, 1.7 * height, 1.5
	local legHeight = 1.6 * height
	local bodyY = FLOOR + legHeight + bodyHeight / 2 - OVERLAP
	local headY = bodyY + bodyHeight * 0.35
	local headZ = -(bodyLength / 2 + 0.7)
	local ridgeHeight = 0.3 + 0.7 * feature

	add(parts, plan, "LegLeft", "body", { 0.7, legHeight, 0.9 }, { -0.55, legY(legHeight), 0.3 })
	add(parts, plan, "LegRight", "body", { 0.7, legHeight, 0.9 }, { 0.55, legY(legHeight), 0.3 })
	add(parts, plan, "Body", "body", { bodyWidth, bodyHeight, bodyLength }, { 0, bodyY, 0 })
	add(parts, plan, "Head", "body", { 1.1, 1.0, 1.7 }, { 0, headY, headZ })
	add(parts, plan, "Jaw", "accent", { 0.9, 0.35, 1.4 }, { 0, headY - 0.55, headZ + 0.1 })
	add(parts, plan, "Tail", "body", { 0.9, 0.9, 3.0 * length }, { 0, bodyY - 0.1, bodyLength / 2 + 1.5 * length })
	add(parts, plan, "ArmLeft", "accent", { 0.25, 0.25, 0.7 }, { -0.8, bodyY - 0.2, -bodyLength / 2 + 0.4 })
	add(parts, plan, "ArmRight", "accent", { 0.25, 0.25, 0.7 }, { 0.8, bodyY - 0.2, -bodyLength / 2 + 0.4 })
	add(
		parts,
		plan,
		"Ridge",
		"accent",
		{ 0.2, ridgeHeight, 1.2 * length },
		{ 0, bodyY + bodyHeight / 2 + ridgeHeight / 2, 0 }
	)
	return parts
end

local function buildDuckbill(plan: Plan): { PartSpec }
	local parts: { PartSpec } = {}
	local length, height, feature = plan.length, plan.height, plan.feature
	local bodyLength, bodyHeight, bodyWidth = 3.0 * length, 1.5 * height, 1.3
	local legHeight = 1.5 * height
	local bodyY = FLOOR + legHeight + bodyHeight / 2 - OVERLAP
	local headY = bodyY + bodyHeight / 2 + 0.2
	local headZ = -(bodyLength / 2 + 0.5)
	local crestHeight = 0.3 + 0.9 * feature
	local crestLength = 0.25 + 0.9 * feature

	add(parts, plan, "LegBackLeft", "body", { 0.6, legHeight, 0.8 }, { -0.5, legY(legHeight), 0.5 })
	add(parts, plan, "LegBackRight", "body", { 0.6, legHeight, 0.8 }, { 0.5, legY(legHeight), 0.5 })
	add(parts, plan, "LegFrontLeft", "body", { 0.4, legHeight, 0.5 }, { -0.5, legY(legHeight), -bodyLength / 2 + 0.6 })
	add(parts, plan, "LegFrontRight", "body", { 0.4, legHeight, 0.5 }, { 0.5, legY(legHeight), -bodyLength / 2 + 0.6 })
	add(parts, plan, "Body", "body", { bodyWidth, bodyHeight, bodyLength }, { 0, bodyY, 0 })
	add(parts, plan, "Head", "body", { 0.8, 0.9, 1.0 }, { 0, headY, headZ })
	add(parts, plan, "Beak", "accent", { 0.7, 0.3, 1.0 }, { 0, headY - 0.15, headZ - 0.9 })
	add(
		parts,
		plan,
		"Crest",
		"accent",
		{ 0.2, crestHeight, crestLength },
		{ 0, headY + 0.45 + crestHeight / 2, headZ + 0.3 }
	)
	add(parts, plan, "Tail", "body", { 0.7, 0.7, 2.4 * length }, { 0, bodyY, bodyLength / 2 + 1.2 * length })
	return parts
end

local function buildArmored(plan: Plan): { PartSpec }
	local parts: { PartSpec } = {}
	local length, height, feature = plan.length, plan.height, plan.feature
	local bodyLength, bodyHeight, bodyWidth = 3.0 * length, 1.5 * height, 2.3
	local legHeight = 0.9 * height
	local bodyY = FLOOR + legHeight + bodyHeight / 2 - OVERLAP
	local legZ = bodyLength / 2 - 0.6
	local plates = 2 + math.floor(3 * feature + 0.5)
	local plateHeight = 0.6 + 0.4 * feature

	add(parts, plan, "LegFrontLeft", "body", { 0.7, legHeight, 0.8 }, { -0.8, legY(legHeight), -legZ })
	add(parts, plan, "LegFrontRight", "body", { 0.7, legHeight, 0.8 }, { 0.8, legY(legHeight), -legZ })
	add(parts, plan, "LegBackLeft", "body", { 0.7, legHeight, 0.8 }, { -0.8, legY(legHeight), legZ })
	add(parts, plan, "LegBackRight", "body", { 0.7, legHeight, 0.8 }, { 0.8, legY(legHeight), legZ })
	add(parts, plan, "Body", "body", { bodyWidth, bodyHeight, bodyLength }, { 0, bodyY, 0 })
	add(parts, plan, "Head", "body", { 0.9, 0.8, 1.0 }, { 0, bodyY, -(bodyLength / 2 + 0.4) })
	add(parts, plan, "Tail", "body", { 0.9, 0.7, 2.4 * length }, { 0, bodyY - 0.1, bodyLength / 2 + 1.1 * length })
	local first = -bodyLength / 2 + 0.8
	local last = bodyLength / 2 - 0.8
	for index = 1, plates do
		local along = if plates == 1 then 0.5 else (index - 1) / (plates - 1)
		add(
			parts,
			plan,
			"Plate" .. index,
			"accent",
			{ 0.35, plateHeight, 0.8 },
			{ 0, bodyY + bodyHeight / 2 + plateHeight / 2 - 0.1, first + (last - first) * along }
		)
	end
	return parts
end

local function buildHorned(plan: Plan): { PartSpec }
	local parts: { PartSpec } = {}
	local length, height, feature = plan.length, plan.height, plan.feature
	local bodyLength, bodyHeight, bodyWidth = 3.0 * length, 1.6 * height, 2.0
	local legHeight = 1.1 * height
	local bodyY = FLOOR + legHeight + bodyHeight / 2 - OVERLAP
	local legZ = bodyLength / 2 - 0.6
	local headY = bodyY + 0.1
	local headZ = -(bodyLength / 2 + 0.7)
	local hornLength = 0.5 + 1.0 * feature

	add(parts, plan, "LegFrontLeft", "body", { 0.7, legHeight, 0.8 }, { -0.7, legY(legHeight), -legZ })
	add(parts, plan, "LegFrontRight", "body", { 0.7, legHeight, 0.8 }, { 0.7, legY(legHeight), -legZ })
	add(parts, plan, "LegBackLeft", "body", { 0.7, legHeight, 0.8 }, { -0.7, legY(legHeight), legZ })
	add(parts, plan, "LegBackRight", "body", { 0.7, legHeight, 0.8 }, { 0.7, legY(legHeight), legZ })
	add(parts, plan, "Body", "body", { bodyWidth, bodyHeight, bodyLength }, { 0, bodyY, 0 })
	add(parts, plan, "Head", "body", { 1.2, 1.1, 1.4 }, { 0, headY, headZ })
	add(parts, plan, "Frill", "accent", { 1.8, 1.5, 0.25 }, { 0, headY + 0.6, headZ + 0.75 })
	add(
		parts,
		plan,
		"HornLeft",
		"accent",
		{ 0.22, 0.22, hornLength },
		{ -0.4, headY + 0.3, headZ - 0.7 - hornLength / 2 }
	)
	add(
		parts,
		plan,
		"HornRight",
		"accent",
		{ 0.22, 0.22, hornLength },
		{ 0.4, headY + 0.3, headZ - 0.7 - hornLength / 2 }
	)
	add(parts, plan, "Tail", "body", { 0.7, 0.7, 2.0 * length }, { 0, bodyY, bodyLength / 2 + length })
	return parts
end

local function buildLongneck(plan: Plan): { PartSpec }
	local parts: { PartSpec } = {}
	local length, height, feature = plan.length, plan.height, plan.feature
	local bodyLength, bodyHeight, bodyWidth = 3.0 * length, 1.7 * height, 1.8
	local legHeight = 2.0 * height
	local bodyY = FLOOR + legHeight + bodyHeight / 2 - OVERLAP
	local legZ = bodyLength / 2 - 0.7
	local step = 0.9 + 1.1 * feature
	local neckTop = bodyY + bodyHeight / 2

	add(parts, plan, "LegFrontLeft", "body", { 0.8, legHeight, 0.9 }, { -0.7, legY(legHeight), -legZ })
	add(parts, plan, "LegFrontRight", "body", { 0.8, legHeight, 0.9 }, { 0.7, legY(legHeight), -legZ })
	add(parts, plan, "LegBackLeft", "body", { 0.8, legHeight, 0.9 }, { -0.7, legY(legHeight), legZ })
	add(parts, plan, "LegBackRight", "body", { 0.8, legHeight, 0.9 }, { 0.7, legY(legHeight), legZ })
	add(parts, plan, "Body", "body", { bodyWidth, bodyHeight, bodyLength }, { 0, bodyY, 0 })
	for index = 1, 3 do
		add(
			parts,
			plan,
			"Neck" .. index,
			"body",
			{ 0.7, step + 0.2, 0.7 },
			{ 0, neckTop + step * (index - 0.5), -(bodyLength / 2) - 0.3 * index }
		)
	end
	add(parts, plan, "Head", "body", { 0.7, 0.6, 1.0 }, { 0, neckTop + step * 3 + 0.2, -(bodyLength / 2) - 1.2 })
	add(parts, plan, "Tail", "body", { 0.8, 0.8, 3.2 * length }, { 0, bodyY, bodyLength / 2 + 1.6 * length })
	add(parts, plan, "TailTip", "accent", { 0.5, 0.5, 1.2 }, { 0, bodyY, bodyLength / 2 + 3.2 * length + 0.5 })
	return parts
end

local builders: { [string]: (Plan) -> { PartSpec } } = {
	runner = buildRunner,
	biped = buildBiped,
	duckbill = buildDuckbill,
	armored = buildArmored,
	horned = buildHorned,
	longneck = buildLongneck,
}

-- Returns a list of problems with a plan (empty when it is usable).
function DinoBody.validatePlan(plan: Plan): { string }
	local errors: { string } = {}
	if builders[plan.template] == nil then
		table.insert(errors, "unknown template " .. tostring(plan.template))
	end
	for _, field in { "length", "height" } do
		local value = (plan :: any)[field]
		if not isFinite(value) or value < MIN_FACTOR or value > MAX_FACTOR then
			table.insert(errors, field .. " must be between " .. MIN_FACTOR .. " and " .. MAX_FACTOR)
		end
	end
	if not isFinite(plan.feature) or plan.feature < 0 or plan.feature > 1 then
		table.insert(errors, "feature must be between 0 and 1")
	end
	if not colorOk(plan.body) or not colorOk(plan.accent) then
		table.insert(errors, "colors must be between 0 and 255")
	end
	return errors
end

-- The look for a plan. An invalid plan gives an empty look (validate it first).
function DinoBody.build(plan: Plan): Look
	local builder = builders[plan.template]
	if builder == nil or #DinoBody.validatePlan(plan) > 0 then
		return { parts = {} }
	end
	return { parts = builder(plan) }
end

-- The look of one dino: the hand-written look if there is one, otherwise the one built from its
-- plan. Nil when the dino has neither.
function DinoBody.lookFor(looks: { [string]: Look }, plans: { [string]: Plan }, id: string): Look?
	local explicit = looks[id]
	if explicit ~= nil then
		return explicit
	end
	local planned = plans[id]
	if planned ~= nil then
		return DinoBody.build(planned)
	end
	return nil
end

-- All looks by dino id (hand-written ones win over plans).
function DinoBody.resolveAll(looks: { [string]: Look }, plans: { [string]: Plan }): { [string]: Look }
	local all: { [string]: Look } = table.clone(looks)
	for id, planned in plans do
		if all[id] == nil then
			all[id] = DinoBody.build(planned)
		end
	end
	return all
end

return DinoBody
