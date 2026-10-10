--!strict
-- Small helpers to build the world from parts (arena and lobby). Only checkable in Roblox Studio.

local Build = {}

-- A round part standing upright along Y (Roblox cylinders lie along X by default), with its
-- bottom at `bottomY`. It has no collision and cannot be touched or hit by queries.
function Build.cylinder(
	parent: Instance,
	name: string,
	height: number,
	diameter: number,
	bottomY: number,
	centerX: number,
	centerZ: number,
	color: Color3,
	material: Enum.Material,
	transparency: number
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = Enum.PartType.Cylinder
	part.Size = Vector3.new(height, diameter, diameter)
	part.CFrame = CFrame.new(centerX, bottomY + height / 2, centerZ) * CFrame.Angles(0, 0, math.rad(90))
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Color = color
	part.Material = material
	part.Transparency = transparency
	part.Parent = parent
	return part
end

-- A fixed block. `solid` decides whether players collide with it.
function Build.block(
	parent: Instance,
	name: string,
	size: Vector3,
	position: Vector3,
	color: Color3,
	material: Enum.Material,
	transparency: number,
	solid: boolean
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.CanCollide = solid
	part.CanTouch = false
	part.CastShadow = false
	part.Color = color
	part.Material = material
	part.Transparency = transparency
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

return Build
