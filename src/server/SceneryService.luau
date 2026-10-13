--!strict
-- The look of the arena: warm light and haze, moss floor with patches and dirt paths, rock
-- walls, the waterhole with a stone ring, and trees, rocks and plants spread over the floor.
-- Everything except the walls themselves is looks only; trees, rocks and logs are made solid by
-- invisible collision shapes (the "Colliders" folder). Only checkable in Roblox Studio.

local AssetService = game:GetService("AssetService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log = require(Shared:WaitForChild("Log"))
local DomeShape = require(Shared:WaitForChild("DomeShape"))
local ScenerySpawn = require(Shared:WaitForChild("ScenerySpawn"))
local WallWindow = require(Shared:WaitForChild("WallWindow"))
local Arena = require(Shared:WaitForChild("Config"):WaitForChild("Arena"))
local FoodConfig = require(Shared:WaitForChild("Config"):WaitForChild("Food"))
local CollisionConfig = require(Shared:WaitForChild("Config"):WaitForChild("Collision"))
local DomeConfig = require(Shared:WaitForChild("Config"):WaitForChild("Dome"))
local Scenery = require(Shared:WaitForChild("Config"):WaitForChild("Scenery"))

local Build = require(script.Parent:WaitForChild("Build"))

local log = Log.new("SceneryService")

local ATMOSPHERE_NAME = "ArenaAtmosphere"
local COLOR_CORRECTION_NAME = "ArenaColorCorrection"
-- How far a rock sinks into the floor (share of its height).
local ROCK_SINK = 0.2

local SceneryService = {}

-- Props placed in the arena (set by build, read when somebody spawns).
local placedProps: { ScenerySpawn.Placed } = {}
-- The solid props as discs (set by build, read by the bots to walk around them).
local solidDiscs: { ScenerySpawn.Disc } = {}
-- Transparency of the collision shapes when they are shown for checking.
local SHOWN_COLLIDER_TRANSPARENCY = 0.6
local COLLIDER_FOLDER_NAME = "Colliders"
local COLLIDER_COLOR = Color3.fromRGB(255, 60, 60)

local function color(value: Scenery.RGB): Color3
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

local function makeRandom(): () -> number
	local random = Random.new(Scenery.seed)
	return function(): number
		return random:NextNumber()
	end
end

local function applyLighting()
	local light = Scenery.lighting
	Lighting.ClockTime = light.clockTime
	Lighting.Brightness = light.brightness
	Lighting.Ambient = color(light.ambient)
	Lighting.OutdoorAmbient = color(light.outdoorAmbient)
	Lighting.ColorShift_Top = color(light.colorShiftTop)
	Lighting.ExposureCompensation = light.exposureCompensation

	for _, name in { ATMOSPHERE_NAME, COLOR_CORRECTION_NAME } do
		local old = Lighting:FindFirstChild(name)
		if old ~= nil then
			old:Destroy()
		end
	end

	local haze = Scenery.atmosphere
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = ATMOSPHERE_NAME
	atmosphere.Density = haze.density
	atmosphere.Offset = haze.offset
	atmosphere.Color = color(haze.color)
	atmosphere.Decay = color(haze.decay)
	atmosphere.Glare = haze.glare
	atmosphere.Haze = haze.haze
	atmosphere.Parent = Lighting

	local grading = Scenery.colorCorrection
	local correction = Instance.new("ColorCorrectionEffect")
	correction.Name = COLOR_CORRECTION_NAME
	correction.Brightness = grading.brightness
	correction.Contrast = grading.contrast
	correction.Saturation = grading.saturation
	correction.TintColor = color(grading.tint)
	correction.Parent = Lighting
	log.info("lighting applied", { clockTime = light.clockTime })
end

-- A flat piece with no collision, no shadow and no queries.
local function visualBlock(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	tint: Color3,
	surface: Enum.Material
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Color = tint
	part.Material = surface
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function buildPatches(folder: Instance, radius: number, rng: () -> number)
	local ground = Scenery.ground
	local patches = ScenerySpawn.patches(
		radius,
		ground.patchMargin,
		ground.patchCount,
		ground.patchMinRadius,
		ground.patchMaxRadius,
		#ground.patchColors,
		rng
	)
	for index, patch in patches do
		local level = (index - 1) % ground.patchLevels
		Build.cylinder(
			folder,
			"Patch",
			ground.patchThickness,
			patch.radius * 2,
			0.01 + level * ground.patchLevelStep,
			patch.x,
			patch.z,
			color(ground.patchColors[patch.tone]),
			Enum.Material.Grass,
			0
		)
	end
end

local function buildPaths(folder: Instance, radius: number, rng: () -> number)
	local ground = Scenery.ground
	local oasis = FoodConfig.zones.center
	local startRadius = oasis.radius + Scenery.waterhole.ringStoneMax
	local tint = color(ground.pathColor)
	local segments = 0
	for index = 1, ground.pathCount do
		-- Evenly spread directions with a little random shift.
		local angle = (index - 1) / ground.pathCount * math.pi * 2 + (rng() - 0.5) * 0.5
		local points = ScenerySpawn.pathPoints(
			angle,
			startRadius,
			radius,
			ground.pathWallInset,
			ground.pathStep,
			ground.pathWobble,
			rng
		)
		for pointIndex = 1, #points - 1 do
			local from = Vector3.new(points[pointIndex].x, ground.pathHeight, points[pointIndex].z)
			local to = Vector3.new(points[pointIndex + 1].x, ground.pathHeight, points[pointIndex + 1].z)
			-- A little longer than the step, so the segments overlap at the bends.
			local length = (to - from).Magnitude + ground.pathWidth * 0.5
			visualBlock(
				folder,
				"Path",
				Vector3.new(ground.pathWidth, ground.pathThickness, length),
				CFrame.lookAt((from + to) / 2, to),
				tint,
				Enum.Material.Ground
			)
			segments += 1
		end
	end
	log.info("paths built", { paths = ground.pathCount, segments = segments })
end

local function buildWallRocks(folder: Instance, radius: number, rng: () -> number)
	local walls = Scenery.walls
	local rocks = ScenerySpawn.wallRocks(radius, {
		spacing = walls.rockSpacing,
		minWidth = walls.rockMinWidth,
		maxWidth = walls.rockMaxWidth,
		minHeight = walls.rockMinHeight,
		maxHeight = walls.rockMaxHeight,
		minDepth = walls.rockMinDepth,
		maxDepth = walls.rockMaxDepth,
		jitter = walls.rockJitter,
		yaw = walls.rockYaw,
		tones = #walls.rockColors,
	}, rng)
	local surface = material(walls.rockMaterial)
	local pieces = Arena.wallSegments
	for _, rock in rocks do
		-- No rocks in front of the viewing window (and one piece beside it): it is for looking through.
		if WallWindow.looksThrough(rock.angle, pieces, Arena.windowAngleDegrees, Arena.windowSegments, 1) then
			continue
		end
		-- Center sits slightly outside the inner wall face, so only part of the rock stands in the arena.
		local across = radius + rock.depth * 0.2
		local position = Vector3.new(math.cos(rock.angle) * across, 0, math.sin(rock.angle) * across)
		-- The depth of the rock points away from the middle.
		local facing = math.pi / 2 - rock.angle
		position += Vector3.new(0, rock.height / 2 - rock.height * ROCK_SINK, 0)
		local cframe = CFrame.new(position) * CFrame.Angles(0, facing + rock.yaw, 0)
		visualBlock(
			folder,
			"WallRock",
			Vector3.new(rock.width, rock.height, rock.depth),
			cframe,
			color(walls.rockColors[rock.tone]),
			surface
		)
	end
	log.info("wall rocks built", { count = #rocks })
end

local function buildWaterhole(folder: Instance, rng: () -> number)
	local hole = Scenery.waterhole
	local radius = FoodConfig.zones.center.radius
	local shoreBottom = hole.baseHeight
	local waterBottom = shoreBottom + hole.shoreThickness
	Build.cylinder(
		folder,
		"Shore",
		hole.shoreThickness,
		radius * 2,
		shoreBottom,
		0,
		0,
		color(hole.shoreColor),
		Enum.Material.Sand,
		0
	)
	Build.cylinder(
		folder,
		"Water",
		hole.waterThickness,
		(radius - hole.shoreWidth) * 2,
		waterBottom,
		0,
		0,
		color(hole.waterColor),
		material(hole.waterMaterial),
		hole.waterTransparency
	)
	local surface = material(Scenery.walls.rockMaterial)
	for index = 1, hole.ringStones do
		local angle = (index - 1) / hole.ringStones * math.pi * 2 + (rng() - 0.5) * 0.1
		local width = hole.ringStoneMin + rng() * (hole.ringStoneMax - hole.ringStoneMin)
		local height = hole.ringStoneHeight * (0.7 + rng() * 0.6)
		local distance = radius + width * 0.2
		local position =
			Vector3.new(math.cos(angle) * distance, height / 2 - height * ROCK_SINK, math.sin(angle) * distance)
		-- The long side follows the ring.
		local cframe = CFrame.new(position) * CFrame.Angles(0, -angle + (rng() - 0.5) * 0.4, 0)
		visualBlock(
			folder,
			"RingStone",
			Vector3.new(width * 0.6, height, width),
			cframe,
			color(hole.ringColors[math.floor(rng() * #hole.ringColors) + 1]),
			surface
		)
	end
	log.info("waterhole built", { radius = radius, stones = hole.ringStones })
end

-- Stand-in shapes until the real meshes are imported.
local function buildStandIn(parent: Instance, kind: Scenery.PropKind, placed: ScenerySpawn.Placed, rng: () -> number)
	local size = kind.fallbackSize * (1 + (rng() * 2 - 1) * Scenery.placement.sizeJitter)
	local shade = 1 + (rng() * 2 - 1) * Scenery.placement.brightnessJitter
	local tint = color(kind.color):Lerp(Color3.new(0, 0, 0), 1 - math.clamp(shade, 0, 1))
	local base = CFrame.new(placed.x, 0, placed.z) * CFrame.Angles(0, placed.yaw, 0)
	local model = Instance.new("Model")
	model.Name = kind.id

	if kind.fallback == "tree" then
		local trunkHeight = size * 0.6
		Build.cylinder(
			model,
			"Trunk",
			trunkHeight,
			size * 0.1,
			0,
			placed.x,
			placed.z,
			Color3.fromRGB(98, 72, 52),
			Enum.Material.Wood,
			0
		)
		local crown = visualBlock(
			model,
			"Crown",
			Vector3.new(size * 0.6, size * 0.5, size * 0.6),
			base * CFrame.new(0, trunkHeight + size * 0.15, 0),
			tint,
			Enum.Material.Grass
		)
		crown.Shape = Enum.PartType.Ball
	elseif kind.fallback == "bush" then
		local bush = visualBlock(
			model,
			"Bush",
			Vector3.new(size, size * 0.6, size),
			base * CFrame.new(0, size * 0.25, 0),
			tint,
			Enum.Material.Grass
		)
		bush.Shape = Enum.PartType.Ball
	elseif kind.fallback == "log" then
		local trunk = visualBlock(
			model,
			"Log",
			Vector3.new(size, size * 0.18, size * 0.18),
			base * CFrame.new(0, size * 0.09, 0),
			tint,
			Enum.Material.Wood
		)
		trunk.Shape = Enum.PartType.Cylinder
	else
		visualBlock(
			model,
			"Rock",
			Vector3.new(size, size * 0.65, size * 0.85),
			base
				* CFrame.new(0, size * 0.65 / 2 - size * 0.65 * ROCK_SINK, 0)
				* CFrame.Angles(0, 0, (rng() - 0.5) * 0.3),
			tint,
			Enum.Material.Slate
		)
	end
	model.Parent = parent
end

-- Loads the mesh of a prop kind once. Returns nil when it is not imported or cannot be loaded.
local function loadTemplate(kind: Scenery.PropKind): MeshPart?
	if kind.meshId == 0 then
		return nil
	end
	local ok, result = pcall(function()
		return AssetService:CreateMeshPartAsync(Content.fromAssetId(kind.meshId))
	end)
	if not ok then
		log.error("prop mesh not loaded", { id = kind.id, meshId = kind.meshId, error = tostring(result) })
		return nil
	end
	return result
end

local function buildMeshProp(
	parent: Instance,
	template: MeshPart,
	kind: Scenery.PropKind,
	placed: ScenerySpawn.Placed,
	rng: () -> number
)
	local part = template:Clone()
	local factor = kind.scale * (1 + (rng() * 2 - 1) * Scenery.placement.sizeJitter)
	local shade = math.clamp(1 + (rng() * 2 - 1) * Scenery.placement.brightnessJitter, 0, 1)
	part.Name = kind.id
	part.Size = part.Size * factor
	-- The foot of the mesh stands on the floor (its middle is half the height up).
	part.CFrame = CFrame.new(placed.x, part.Size.Y / 2, placed.z) * CFrame.Angles(0, placed.yaw, 0)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Color = Color3.new(shade, shade, shade)
	part.Parent = parent
end

local function buildProps(folder: Instance, props: { ScenerySpawn.Placed })
	local byId: { [string]: Scenery.PropKind } = {}
	for _, kind in Scenery.props do
		byId[kind.id] = kind
	end
	local templates: { [string]: MeshPart } = {}
	local tried: { [string]: boolean } = {}
	local rng = makeRandom()
	local meshCount = 0
	for _, placed in props do
		local kind = byId[placed.id]
		if kind ~= nil then
			if not tried[kind.id] then
				-- Try once per kind, also when it fails.
				tried[kind.id] = true
				local loaded = loadTemplate(kind)
				if loaded ~= nil then
					templates[kind.id] = loaded
				end
			end
			local template = templates[kind.id]
			if template ~= nil then
				buildMeshProp(folder, template, kind, placed, rng)
				meshCount += 1
			else
				buildStandIn(folder, kind, placed, rng)
			end
		end
	end
	log.info("props built", { total = #props, withMesh = meshCount })
end

-- Radius of the disc a collider takes up on the floor (for the steering).
local function colliderRadius(collider: Scenery.Collider): number
	if collider.shape == "cylinder" then
		return collider.radius
	end
	return math.max(collider.width, collider.depth) / 2
end

-- Invisible solid shapes for the props that block: smooth cylinders where possible, so a dino
-- slides along them instead of sticking. They cannot be hit by queries (the camera ignores them)
-- and carry their radius as an attribute for the autofarm on the client.
local function buildColliders(parent: Instance, props: { ScenerySpawn.Placed })
	local byId: { [string]: Scenery.PropKind } = {}
	local radii: { [string]: number } = {}
	for _, kind in Scenery.props do
		byId[kind.id] = kind
		if kind.collider ~= nil then
			radii[kind.id] = colliderRadius(kind.collider)
		end
	end
	solidDiscs = ScenerySpawn.obstacles(props, radii)

	local folder = Instance.new("Folder")
	folder.Name = COLLIDER_FOLDER_NAME
	local transparency = if CollisionConfig.showColliders then SHOWN_COLLIDER_TRANSPARENCY else 1
	local built = 0
	for _, placed in props do
		local kind = byId[placed.id]
		local collider = if kind ~= nil then kind.collider else nil
		if collider ~= nil then
			local part: Part
			if collider.shape == "cylinder" then
				part = Build.cylinder(
					folder,
					"Collider_" .. placed.id,
					collider.height,
					collider.radius * 2,
					0,
					placed.x,
					placed.z,
					COLLIDER_COLOR,
					Enum.Material.SmoothPlastic,
					transparency
				)
			else
				part = Build.block(
					folder,
					"Collider_" .. placed.id,
					Vector3.new(collider.width, collider.height, collider.depth),
					Vector3.new(placed.x, collider.height / 2, placed.z),
					COLLIDER_COLOR,
					Enum.Material.SmoothPlastic,
					transparency,
					true
				)
				part.CFrame = CFrame.new(placed.x, collider.height / 2, placed.z) * CFrame.Angles(0, placed.yaw, 0)
			end
			part.CanCollide = true
			part.CanQuery = false
			part.CanTouch = false
			part.CastShadow = false
			part:SetAttribute("Radius", colliderRadius(collider))
			built += 1
		end
	end
	folder.Parent = parent
	log.info("colliders built", { count = built, shown = CollisionConfig.showColliders })
end

-- Shallow ponds: a sandy shore and the water on it. Walkable, looks only.
local function buildPonds(folder: Instance, ponds: { ScenerySpawn.Disc })
	local config = Scenery.ponds
	local shoreBottom = config.baseHeight
	local waterBottom = shoreBottom + config.shoreThickness
	for _, pond in ponds do
		Build.cylinder(
			folder,
			"PondShore",
			config.shoreThickness,
			pond.r * 2,
			shoreBottom,
			pond.x,
			pond.z,
			color(config.shoreColor),
			Enum.Material.Sand,
			0
		)
		Build.cylinder(
			folder,
			"PondWater",
			config.waterThickness,
			math.max(1, pond.r - config.shoreWidth) * 2,
			waterBottom,
			pond.x,
			pond.z,
			color(config.waterColor),
			material(config.waterMaterial),
			config.waterTransparency
		)
	end
	log.info("ponds built", { count = #ponds })
end

-- Vines hang from the lowest ring beam of the dome, in front of the wall rocks. Not in front of the
-- viewing window. Each is a thin stem and a leaf ball (two parts, no collision).
local function buildVines(folder: Instance, rng: () -> number)
	local config = Scenery.vines
	local domeRadius = Arena.radius + Arena.wallThickness / 2
	local elevation = math.rad(DomeConfig.frame.ringElevations[1])
	local vines = ScenerySpawn.vines(
		config.count,
		config.minLength,
		config.maxLength,
		config.maxTilt,
		function(angle: number): boolean
			-- The directions of ScenerySpawn are from +X toward +Z, like the wall pieces.
			return WallWindow.looksThrough(angle, Arena.wallSegments, Arena.windowAngleDegrees, Arena.windowSegments, 1)
		end,
		rng
	)
	local stemTint = color(config.stemColor)
	local leafTint = color(config.leafColor)
	for _, vine in vines do
		local x, y, z = DomeShape.point(domeRadius, vine.angle, elevation)
		x, z = x * config.inset, z * config.inset
		local top = Vector3.new(x, y, z)
		local base = CFrame.new(top) * CFrame.Angles(vine.tiltX, 0, vine.tiltZ)
		visualBlock(
			folder,
			"Vine",
			Vector3.new(config.thickness, vine.length, config.thickness),
			base * CFrame.new(0, -vine.length / 2, 0),
			stemTint,
			Enum.Material.Grass
		)
		local leaf = visualBlock(
			folder,
			"VineLeaf",
			Vector3.one * config.leafSize,
			base * CFrame.new(0, -vine.length, 0),
			leafTint,
			Enum.Material.Grass
		)
		leaf.Shape = Enum.PartType.Ball
	end
	log.info("vines built", { count = #vines })
end

-- Spreads the props over the floor and remembers where they are, then builds them: first the
-- chokepoints (pairs of rocks) and the cover (groups of plants), then the single props with space
-- around the waterhole, the ponds, these groups and the walls. The loading of meshes may wait, so
-- it runs on its own.
local function placeProps(folder: Instance, radius: number, ponds: { ScenerySpawn.Disc })
	local placement = Scenery.placement
	local oasis = FoodConfig.zones.center
	local exclusions: { ScenerySpawn.Disc } =
		{ { x = 0, z = 0, r = oasis.radius + Scenery.waterhole.ringStoneMax + placement.waterholeClearance } }
	for _, pond in ponds do
		table.insert(exclusions, { x = pond.x, z = pond.z, r = pond.r + Scenery.ponds.clearance })
	end

	local byId: { [string]: Scenery.PropKind } = {}
	for _, kind in Scenery.props do
		byId[kind.id] = kind
	end
	local rng = makeRandom()
	local placed: { ScenerySpawn.Placed } = {}

	-- Chokepoints from the rocks of the gate prop.
	local gateRock = byId[Scenery.gates.rockId]
	local gateCollider = if gateRock ~= nil then gateRock.collider else nil
	if gateRock ~= nil and gateCollider ~= nil then
		local gates = ScenerySpawn.gates(
			radius,
			placement.wallMargin,
			exclusions,
			Scenery.gates.count,
			Scenery.gates.gaps,
			colliderRadius(gateCollider),
			placement.candidates,
			rng
		)
		for _, gate in gates do
			for _, rock in gate.rocks do
				table.insert(
					placed,
					{ id = gateRock.id, x = rock.x, z = rock.z, yaw = rng() * math.pi * 2, radius = gateRock.radius }
				)
			end
			table.insert(exclusions, { x = gate.x, z = gate.z, r = gate.reach + Scenery.gates.clearance })
		end
		log.info("gates placed", { count = #gates, wanted = Scenery.gates.count })
	else
		log.warn("gate rock prop has no collider, no gates", { id = Scenery.gates.rockId })
	end

	-- Cover: groups of bushes and ferns.
	local radii: { [string]: number } = {}
	for _, id in Scenery.clusters.ids do
		radii[id] = if byId[id] ~= nil then byId[id].radius else 1
	end
	local clusters = ScenerySpawn.clusters(
		radius,
		placement.wallMargin,
		exclusions,
		Scenery.clusters.count,
		Scenery.clusters.minMembers,
		Scenery.clusters.maxMembers,
		Scenery.clusters.spread,
		Scenery.clusters.ids,
		radii,
		placement.candidates,
		rng
	)
	for _, cluster in clusters do
		for _, member in cluster.members do
			table.insert(placed, member)
		end
		table.insert(exclusions, { x = cluster.x, z = cluster.z, r = Scenery.clusters.spread + 2 })
	end
	log.info("cover placed", { clusters = #clusters, wanted = Scenery.clusters.count })

	local kinds: { ScenerySpawn.Kind } = {}
	local wanted = 0
	for _, kind in Scenery.props do
		table.insert(kinds, { id = kind.id, count = kind.count, radius = kind.radius })
		wanted += kind.count
	end
	for _, prop in ScenerySpawn.scatter(radius, placement.wallMargin, exclusions, kinds, placement.candidates, rng) do
		table.insert(placed, prop)
	end
	placedProps = placed
	if #placedProps < wanted then
		log.warn("not every prop found room", { placed = #placedProps, wanted = wanted })
	end

	buildColliders(folder, placedProps)

	local propFolder = Instance.new("Folder")
	propFolder.Name = "Props"
	propFolder.Parent = folder
	task.spawn(function()
		local ok, err = pcall(buildProps, propFolder, placedProps)
		if not ok then
			log.error("props failed", { error = tostring(err) })
		end
	end)
end

-- The wall pieces (solid, except the glass window) get a rock look; everything else is built in front of them.
function SceneryService.build(folder: Instance)
	local radius = Arena.radius
	local rng = makeRandom()

	local ok, err = pcall(applyLighting)
	if not ok then
		log.error("lighting failed", { error = tostring(err) })
	end

	local floor = folder:FindFirstChild("Floor")
	if floor ~= nil and floor:IsA("BasePart") then
		floor.Color = color(Scenery.ground.base)
		floor.Material = Enum.Material.Grass
	end
	local walls = folder:FindFirstChild("Walls")
	if walls ~= nil then
		for _, wall in walls:GetChildren() do
			if wall:IsA("BasePart") and wall.Name == "Wall" then
				wall.Color = color(Scenery.walls.color)
				wall.Material = material(Scenery.walls.material)
			end
		end
	end

	local decoration = Instance.new("Folder")
	decoration.Name = "Scenery"
	decoration.Parent = folder
	buildPatches(decoration, radius, rng)
	buildPaths(decoration, radius, rng)
	buildWaterhole(decoration, rng)
	buildWallRocks(decoration, radius, rng)

	-- Ponds first: the props keep away from them.
	local oasis = FoodConfig.zones.center
	local ponds = ScenerySpawn.ponds(
		radius,
		Scenery.placement.wallMargin,
		{ { x = 0, z = 0, r = oasis.radius + Scenery.waterhole.ringStoneMax + Scenery.placement.waterholeClearance } },
		Scenery.ponds.count,
		Scenery.ponds.minRadius,
		Scenery.ponds.maxRadius,
		Scenery.placement.candidates,
		rng
	)
	buildPonds(decoration, ponds)
	buildVines(decoration, rng)
	placeProps(decoration, radius, ponds)
	log.info("scenery built")
end

-- The solid props as discs on the floor, for the steering of the bots.
function SceneryService.obstacles(): { ScenerySpawn.Disc }
	return solidDiscs
end

-- Whether a spawn spot is far enough from every prop.
function SceneryService.isClearForSpawn(x: number, z: number): boolean
	return ScenerySpawn.clearOfProps(x, z, placedProps, Scenery.placement.spawnGap)
end

return SceneryService
