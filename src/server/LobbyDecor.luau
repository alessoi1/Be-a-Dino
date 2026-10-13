--!strict
-- The research station look of the lobby: roof with a skylight, pillars, the back wall with the sign,
-- low side walls, lamps, benches, planters and a fossil skeleton on a pedestal. Built from parts, looks
-- only except pillars, walls, benches and planters (they are solid). The lobby service passes the folder
-- and gets the circles the decoration takes up (nobody spawns there). Only checkable in Roblox Studio.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log = require(Shared:WaitForChild("Log"))
local LobbyLayout = require(Shared:WaitForChild("LobbyLayout"))
local Strings = require(Shared:WaitForChild("Strings"))
local ArenaConfig = require(Shared:WaitForChild("Config"):WaitForChild("Arena"))
local Lobby = require(Shared:WaitForChild("Config"):WaitForChild("Lobby"))
local Decor = require(Shared:WaitForChild("Config"):WaitForChild("LobbyDecor"))

local Build = require(script.Parent:WaitForChild("Build"))

local log = Log.new("LobbyDecor")

-- Looks only (no game values).
local RAIL_CLEAR = 2
local SIGN_PIXELS_PER_STUD = 20
local SIGN_TOP_PIXELS = 40
local SIGN_HEIGHT_PIXELS = 130
local BONE_RIB_TILT = 0.55
local TAIL_PARTS = 6
local SPINE_PARTS = 12

local LobbyDecorBuilder = {}

local function color(value: Decor.RGB): Color3
	return Color3.fromRGB(value.r, value.g, value.b)
end

-- World position of a spot relative to the middle of the platform, `height` above the floor.
local function world(x: number, height: number, z: number): Vector3
	return Vector3.new(Lobby.centerX + x, Lobby.height + height, Lobby.centerZ + z)
end

local function block(
	folder: Instance,
	name: string,
	size: Vector3,
	position: Vector3,
	tint: Color3,
	material: Enum.Material,
	solid: boolean
): Part
	local part = Build.block(folder, name, size, position, tint, material, 0, solid)
	part.CanQuery = solid
	part.CastShadow = false
	return part
end

local function ball(
	folder: Instance,
	name: string,
	diameter: number,
	position: Vector3,
	tint: Color3,
	material: Enum.Material
): Part
	local part = block(folder, name, Vector3.one * diameter, position, tint, material, false)
	part.Shape = Enum.PartType.Ball
	return part
end

local function buildRoof(folder: Instance)
	local roof = Decor.roof
	local depth = roof.backZ - roof.frontZ
	local centerZ = (roof.frontZ + roof.backZ) / 2
	local sideWidth = roof.halfWidth - roof.skylightHalfWidth
	for _, side in { -1, 1 } do
		block(
			folder,
			"Roof",
			Vector3.new(sideWidth, roof.thickness, depth),
			world(side * (roof.skylightHalfWidth + sideWidth / 2), roof.height, centerZ),
			color(Decor.colors.darkMetal),
			Enum.Material.Metal,
			false
		)
	end
	local skylight = block(
		folder,
		"Skylight",
		Vector3.new(roof.skylightHalfWidth * 2, roof.thickness * 0.5, depth),
		world(0, roof.height, centerZ),
		color(Decor.colors.glass),
		Enum.Material.Glass,
		false
	)
	skylight.Transparency = roof.glassTransparency
	-- A beam along the front edge, and cross beams under the roof.
	block(
		folder,
		"RoofBeam",
		Vector3.new(roof.halfWidth * 2, 1.2, 1.2),
		world(0, roof.height - 1.2, roof.frontZ),
		color(Decor.colors.metal),
		Enum.Material.Metal,
		false
	)
	for _, z in { roof.frontZ + depth / 3, roof.frontZ + depth * 2 / 3 } do
		block(
			folder,
			"RoofBeam",
			Vector3.new(roof.halfWidth * 2, 0.9, 0.9),
			world(0, roof.height - 1, z),
			color(Decor.colors.metal),
			Enum.Material.Metal,
			false
		)
	end
end

local function buildPillars(folder: Instance)
	for _, spot in Decor.pillars do
		block(
			folder,
			"Pillar",
			Vector3.new(Decor.pillarSize, Decor.roof.height, Decor.pillarSize),
			world(spot.x, Decor.roof.height / 2, spot.z),
			color(Decor.colors.metal),
			Enum.Material.Metal,
			true
		)
	end
end

-- The back wall with the name of the station, and low walls along the sides (up to the dome wall).
local function buildWalls(folder: Instance)
	local half = Lobby.size / 2
	local wall = Decor.backWall
	local backZ = half - wall.thickness / 2
	local back = block(
		folder,
		"BackWall",
		Vector3.new(Lobby.size, wall.height, wall.thickness),
		world(0, wall.height / 2, backZ),
		color(Decor.colors.wall),
		Enum.Material.Metal,
		true
	)
	-- The sign is on the front of the wall (the side facing the window), near the top.
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = SIGN_PIXELS_PER_STUD
	gui.Parent = back
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(0, SIGN_TOP_PIXELS)
	label.Size = UDim2.fromOffset(Lobby.size * SIGN_PIXELS_PER_STUD, SIGN_HEIGHT_PIXELS)
	label.FontFace = Font.fromEnum(Enum.Font.FredokaOne)
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.3
	label.Text = Strings.lobby.title
	label.Parent = gui

	-- The side walls run from the dome wall (where the glass railings start) to the back wall.
	local outer = ArenaConfig.radius + ArenaConfig.wallThickness
	local startZ = math.sqrt(math.max(0, outer * outer - half * half)) + RAIL_CLEAR - Lobby.centerZ
	local length = (half - wall.thickness) - startZ
	if length > 0 then
		for _, side in { -1, 1 } do
			block(
				folder,
				"SideWall",
				Vector3.new(1, Decor.sideWallHeight, length),
				world(side * (half - 0.5), Decor.sideWallHeight / 2, startZ + length / 2),
				color(Decor.colors.metal),
				Enum.Material.Metal,
				true
			)
		end
	end
end

local function buildLamps(folder: Instance)
	local drop = Decor.lampDrop
	for _, spot in Decor.lamps do
		local top = Decor.roof.height - Decor.roof.thickness / 2
		block(
			folder,
			"LampRod",
			Vector3.new(0.3, drop, 0.3),
			world(spot.x, top - drop / 2, spot.z),
			color(Decor.colors.metal),
			Enum.Material.Metal,
			false
		)
		local bulb = ball(
			folder,
			"Lamp",
			2.4,
			world(spot.x, top - drop - 1, spot.z),
			color(Decor.colors.lamp),
			Enum.Material.Neon
		)
		local light = Instance.new("PointLight")
		light.Color = color(Decor.colors.lamp)
		light.Range = Decor.lampRange
		light.Brightness = Decor.lampBrightness
		light.Shadows = false
		light.Parent = bulb
	end
end

-- A bench facing the window (north, toward -Z).
local function buildBench(folder: Instance, spot: Decor.Spot)
	local wood = color(Decor.colors.wood)
	block(folder, "BenchSeat", Vector3.new(8, 0.8, 2.6), world(spot.x, 1.7, spot.z), wood, Enum.Material.Wood, true)
	block(
		folder,
		"BenchBack",
		Vector3.new(8, 2.4, 0.5),
		world(spot.x, 3.3, spot.z + 1.1),
		wood,
		Enum.Material.Wood,
		false
	)
	for _, side in { -1, 1 } do
		block(
			folder,
			"BenchLeg",
			Vector3.new(0.8, 1.6, 2.2),
			world(spot.x + side * 3.4, 0.8, spot.z),
			color(Decor.colors.metal),
			Enum.Material.Metal,
			false
		)
	end
end

local function buildPlanter(folder: Instance, spot: Decor.Spot)
	Build.cylinder(
		folder,
		"Planter",
		1.8,
		5,
		Lobby.height,
		Lobby.centerX + spot.x,
		Lobby.centerZ + spot.z,
		color(Decor.colors.planter),
		Enum.Material.Concrete,
		0
	).CanCollide =
		true
	ball(folder, "Plant", 4.6, world(spot.x, 3.4, spot.z), color(Decor.colors.leaf), Enum.Material.Grass)
	ball(folder, "Plant", 3, world(spot.x + 1, 5.4, spot.z - 0.6), color(Decor.colors.leafLight), Enum.Material.Grass)
end

-- A rib bone: a thin block tilted outward (side = -1 or 1 toward -Z or +Z).
local function rib(folder: Instance, x: number, y: number, z: number, side: number)
	local part = block(
		folder,
		"Rib",
		Vector3.new(0.5, 4, 0.5),
		world(x, y, z + side * 1.3),
		color(Decor.colors.bone),
		Enum.Material.Marble,
		false
	)
	part.CFrame = CFrame.new(part.Position) * CFrame.Angles(side * BONE_RIB_TILT, 0, 0)
end

-- A dinosaur skeleton lying along x on a pedestal: spine, ribs, tail and skull (looks only).
local function buildSkeleton(folder: Instance)
	local spot = Decor.skeleton
	local bone = color(Decor.colors.bone)
	block(
		folder,
		"Pedestal",
		Vector3.new(38, 1, 9),
		world(spot.x, 0.5, spot.z),
		color(Decor.colors.darkMetal),
		Enum.Material.Metal,
		true
	)
	for index = 0, SPINE_PARTS - 1 do
		local fraction = index / (SPINE_PARTS - 1)
		local x = spot.x - 10 + index * 1.9
		local y = 5.4 + 1.5 * math.sin(fraction * math.pi)
		block(folder, "Vertebra", Vector3.new(1.5, 1.2, 1.2), world(x, y, spot.z), bone, Enum.Material.Marble, false)
		if index >= 2 and index <= 8 and index % 2 == 0 then
			rib(folder, x, y - 1.8, spot.z, -1)
			rib(folder, x, y - 1.8, spot.z, 1)
		end
		-- A stand under the spine.
		if index % 4 == 1 then
			block(
				folder,
				"Stand",
				Vector3.new(0.4, y - 1.2, 0.4),
				world(x, (y - 0.4) / 2 + 0.5, spot.z),
				color(Decor.colors.metal),
				Enum.Material.Metal,
				false
			)
		end
	end
	-- The tail gets thinner and lower.
	for index = 1, TAIL_PARTS do
		local shrink = 1 - index / (TAIL_PARTS + 1)
		block(
			folder,
			"Tail",
			Vector3.new(1.8, 1.1 * shrink + 0.3, 1.1 * shrink + 0.3),
			world(spot.x - 10 - index * 1.9, 5.4 - index * 0.35, spot.z),
			bone,
			Enum.Material.Marble,
			false
		)
	end
	-- The skull and the jaw at the front.
	local headX = spot.x + 10 + 4
	block(folder, "Skull", Vector3.new(5.5, 2.8, 3.2), world(headX, 6.6, spot.z), bone, Enum.Material.Marble, false)
	block(folder, "Jaw", Vector3.new(4.6, 0.7, 2.6), world(headX + 0.4, 4.9, spot.z), bone, Enum.Material.Marble, false)
	block(
		folder,
		"Eye",
		Vector3.new(0.5, 0.8, 0.8),
		world(headX + 0.4, 7.2, spot.z - 1.5),
		Color3.fromRGB(30, 26, 22),
		Enum.Material.SmoothPlastic,
		false
	)
end

-- A lighter ring around the play circle, so it reads as the middle of the lobby.
local function buildRing(folder: Instance)
	for _, zone in Lobby.zones do
		if zone.kind == "play" then
			Build.cylinder(
				folder,
				"PlayRing",
				0.12,
				(zone.radius + Decor.ringExtra) * 2,
				Lobby.height,
				Lobby.centerX + zone.x,
				Lobby.centerZ + zone.z,
				color(Decor.colors.ring),
				Enum.Material.Metal,
				0
			)
		end
	end
end

-- Builds everything into `parent` and returns the circles it takes up, in world coordinates, for the
-- spawn of the lobby.
function LobbyDecorBuilder.build(parent: Instance): { LobbyLayout.Circle }
	local folder = Instance.new("Folder")
	folder.Name = "Station"
	buildRoof(folder)
	buildPillars(folder)
	buildWalls(folder)
	buildLamps(folder)
	for _, spot in Decor.benches do
		buildBench(folder, spot)
	end
	for _, spot in Decor.planters do
		buildPlanter(folder, spot)
	end
	buildSkeleton(folder)
	buildRing(folder)
	folder.Parent = parent

	local circles = LobbyLayout.circles(Decor)
	for _, circle in circles do
		circle.x += Lobby.centerX
		circle.z += Lobby.centerZ
	end
	log.info("lobby station built", { parts = #folder:GetDescendants(), circles = #circles })
	return circles
end

return LobbyDecorBuilder
