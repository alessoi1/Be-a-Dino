--!strict
-- The glass dome over the arena: a big transparent half sphere (seen from outside) and a frame of
-- ribs and rings from straight beams (what the players see from inside). Looks only, no
-- collision; the wall at the foot is built by the ArenaService. Only checkable in Roblox Studio.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local DomeShape = require(Shared:WaitForChild("DomeShape"))
local Log = require(Shared:WaitForChild("Log"))
local Arena = require(Shared:WaitForChild("Config"):WaitForChild("Arena"))
local DomeConfig = require(Shared:WaitForChild("Config"):WaitForChild("Dome"))

local log = Log.new("DomeService")

local DomeService = {}

local function color(value: DomeConfig.RGB): Color3
	return Color3.fromRGB(value.r, value.g, value.b)
end

local function material(name: string): Enum.Material
	local found = (Enum.Material :: any)[name]
	if found == nil then
		log.warn("unknown material, using plastic", { name = name })
		return Enum.Material.SmoothPlastic
	end
	return found
end

local function lookless(part: BasePart)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
end

local function buildGlass(folder: Instance, radius: number)
	local glass = DomeConfig.glass
	local part = Instance.new("Part")
	part.Name = "Glass"
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.one * radius * 2
	part.Position = Vector3.zero
	lookless(part)
	part.Color = color(glass.color)
	part.Material = material(glass.material)
	part.Transparency = glass.transparency
	part.Reflectance = glass.reflectance
	part.Parent = folder
end

local function buildBeams(folder: Instance, radius: number)
	local frame = DomeConfig.frame
	local beams = DomeShape.ribs(radius, frame.ribs, frame.ribSegments)
	for _, ring in DomeShape.rings(radius, frame.ringElevations, frame.ringMinSegments, frame.ringMaxSegments) do
		table.insert(beams, ring)
	end
	local tint = color(frame.color)
	local surface = material(frame.material)
	for _, beam in beams do
		local from = Vector3.new(beam.ax, beam.ay, beam.az)
		local to = Vector3.new(beam.bx, beam.by, beam.bz)
		local length = (to - from).Magnitude
		if length > 0 then
			local part = Instance.new("Part")
			part.Name = "Beam"
			part.Size = Vector3.new(frame.thickness, frame.thickness, length)
			part.CFrame = CFrame.lookAt((from + to) / 2, to)
			lookless(part)
			part.Color = tint
			part.Material = surface
			part.TopSurface = Enum.SurfaceType.Smooth
			part.BottomSurface = Enum.SurfaceType.Smooth
			part.Parent = folder
		end
	end
	return #beams
end

-- Builds the dome into `parent` (the arena folder). The frame sits on the middle of the wall.
function DomeService.build(parent: Instance)
	local radius = Arena.radius + Arena.wallThickness / 2
	local folder = Instance.new("Folder")
	folder.Name = "Dome"
	buildGlass(folder, radius + Arena.wallThickness / 2)
	local beams = buildBeams(folder, radius)
	folder.Parent = parent
	log.info("dome built", { radius = radius, beams = beams })
end

return DomeService
