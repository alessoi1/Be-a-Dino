--!strict
-- Pure checks for the placeholder dino looks (Config/DinoLooks). No Roblox
-- services, no logging; the calling service logs the problems.

-- Structural copies of the config types (no require, so this module loads the same
-- way in Roblox and Lune).
type PartSpec = {
	name: string,
	shape: string,
	size: { x: number, y: number, z: number },
	offset: { x: number, y: number, z: number },
	color: { r: number, g: number, b: number },
	role: string,
}
type Look = { parts: { PartSpec } }
type Stage = { id: string }

local DinoLook = {}

-- Height of the figure floor relative to the figure center at scale 1 (studs).
DinoLook.FLOOR_OFFSET = -3

local function isFinite(value: number): boolean
	return value == value and value ~= math.huge and value ~= -math.huge
end

local function checkPart(stageId: string, spec: PartSpec, errors: { string })
	local where = stageId .. "/" .. spec.name
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
	if spec.role ~= "body" and spec.role ~= "accent" then
		table.insert(errors, where .. ": role must be body or accent")
	end
	for _, value in { spec.color.r, spec.color.g, spec.color.b } do
		if not isFinite(value) or value < 0 or value > 255 then
			table.insert(errors, where .. ": color must be between 0 and 255")
			break
		end
	end
end

-- Returns a list of problems (empty when all looks are usable).
function DinoLook.validate(stages: { Stage }, looks: { [string]: Look }, maxParts: number): { string }
	local errors: { string } = {}
	local known: { [string]: boolean } = {}
	for _, stage in stages do
		known[stage.id] = true
		if looks[stage.id] == nil then
			table.insert(errors, "missing look for " .. stage.id)
		end
	end
	for id, look in looks do
		if not known[id] then
			table.insert(errors, "look for unknown stage " .. id)
			continue
		end
		if #look.parts == 0 then
			table.insert(errors, id .. ": no parts")
		elseif #look.parts > maxParts then
			table.insert(errors, id .. ": too many parts (" .. #look.parts .. " of " .. maxParts .. ")")
		end
		local names: { [string]: boolean } = {}
		for _, spec in look.parts do
			if names[spec.name] then
				table.insert(errors, id .. ": duplicate part name " .. spec.name)
			end
			names[spec.name] = true
			checkPart(id, spec, errors)
		end
	end
	return errors
end

-- Lowest point of a look relative to the figure center (for the floor check).
function DinoLook.lowestPoint(look: Look): number
	local lowest = math.huge
	for _, spec in look.parts do
		lowest = math.min(lowest, spec.offset.y - spec.size.y / 2)
	end
	return lowest
end

return DinoLook
