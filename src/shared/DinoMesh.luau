--!strict
-- Pure rules for the real dino shapes (Config/DinoMeshes): which dino uses which shape, which
-- color a part gets and whether the config is usable. No Roblox services, no logging; the
-- AppearanceService builds the parts and logs the problems.

-- Structural copies of the config types (no require, so this module loads the same way in
-- Roblox and Lune).
export type Color = { r: number, g: number, b: number }
type Spec = {
	name: string,
	meshId: number,
	role: string,
	size: { x: number, y: number, z: number },
	offset: { x: number, y: number, z: number },
}
type Template = { parts: { Spec } }
export type Entry = { template: string, body: Color, accent: Color }
type Plan = { template: string, body: Color, accent: Color }

local ROLES: { [string]: boolean } = { body = true, accent = true, eyes = true, dark = true }

local DinoMesh = {}

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

-- The shape and colors of a dino, or nil when its shape has no mesh template yet (it keeps its
-- placeholder). A hand-written entry wins over the plan.
function DinoMesh.resolve(
	id: string,
	plans: { [string]: Plan },
	entries: { [string]: Entry },
	templates: { [string]: Template }
): Entry?
	local entry = entries[id]
	if entry ~= nil and templates[entry.template] ~= nil then
		return entry
	end
	local plan = plans[id]
	if plan ~= nil and templates[plan.template] ~= nil then
		return { template = plan.template, body = plan.body, accent = plan.accent }
	end
	return nil
end

-- Whether the colors of a part follow the dino and the variants ("body", "accent") or are fixed.
function DinoMesh.isVaried(role: string): boolean
	return role == "body" or role == "accent"
end

-- The color of a part for a dino: the body or accent color of the dino, or the fixed color.
function DinoMesh.colorFor(role: string, entry: Entry, fixed: { eyes: Color, dark: Color }): Color
	if role == "body" then
		return entry.body
	elseif role == "accent" then
		return entry.accent
	elseif role == "eyes" then
		return fixed.eyes
	end
	return fixed.dark
end

-- Returns a list of problems (empty when the config is usable): every template has between 1
-- and `maxParts` parts with unique names, valid roles, a body part, positive sizes, finite
-- offsets and a mesh id; every hand-written dino names a known template.
function DinoMesh.validate(
	templates: { [string]: Template },
	entries: { [string]: Entry },
	fixed: { eyes: Color, dark: Color },
	maxParts: number
): { string }
	local errors: { string } = {}
	for name, template in templates do
		local count = #template.parts
		if count == 0 or count > maxParts then
			table.insert(errors, name .. ": needs 1 to " .. maxParts .. " parts, has " .. count)
		end
		local names: { [string]: boolean } = {}
		local hasBody = false
		for _, spec in template.parts do
			local where = name .. "/" .. spec.name
			if names[spec.name] then
				table.insert(errors, where .. ": duplicate part name")
			end
			names[spec.name] = true
			if ROLES[spec.role] ~= true then
				table.insert(errors, where .. ": unknown role " .. tostring(spec.role))
			end
			if spec.role == "body" then
				hasBody = true
			end
			if not isFinite(spec.meshId) or spec.meshId <= 0 then
				table.insert(errors, where .. ": mesh id must be a positive number")
			end
			for _, value in { spec.size.x, spec.size.y, spec.size.z } do
				if not isFinite(value) or value <= 0 then
					table.insert(errors, where .. ": size must be positive and finite")
					break
				end
			end
			for _, value in { spec.offset.x, spec.offset.y, spec.offset.z } do
				if not isFinite(value) then
					table.insert(errors, where .. ": offset must be finite")
					break
				end
			end
		end
		if not hasBody then
			table.insert(errors, name .. ": no body part to color")
		end
	end
	for id, entry in entries do
		if templates[entry.template] == nil then
			table.insert(errors, id .. ": unknown template " .. tostring(entry.template))
		end
		if not colorOk(entry.body) or not colorOk(entry.accent) then
			table.insert(errors, id .. ": colors must be between 0 and 255")
		end
	end
	if not colorOk(fixed.eyes) or not colorOk(fixed.dark) then
		table.insert(errors, "fixed colors must be between 0 and 255")
	end
	return errors
end

return DinoMesh
