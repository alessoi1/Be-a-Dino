--!strict
-- Builds the arena (a round floor and a wall ring from parts under the glass dome; the look comes
-- from the SceneryService and the DomeService) and finds a spawn spot inside it for players who
-- enter from the lobby. Only checkable in Roblox Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log = require(Shared:WaitForChild("Log"))
local FoodSpawn = require(Shared:WaitForChild("FoodSpawn"))
local SpawnPick = require(Shared:WaitForChild("SpawnPick"))
local Arena = require(Shared:WaitForChild("Config"):WaitForChild("Arena"))
local FoodConfig = require(Shared:WaitForChild("Config"):WaitForChild("Food"))

local Build = require(script.Parent:WaitForChild("Build"))
local DomeService = require(script.Parent:WaitForChild("DomeService"))
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local SceneryService = require(script.Parent:WaitForChild("SceneryService"))

local log = Log.new("ArenaService")

-- Height above the floor at which characters appear (they drop to the floor).
local SPAWN_HEIGHT = 5
-- Thickness of the floor (studs) and how much longer than needed the wall pieces are (no gaps).
local FLOOR_THICKNESS = 1
local WALL_OVERLAP = 1.02

local random = Random.new()

-- Where the bots are right now (nil until the BotService registers).
local botPositions: (() -> { { x: number, z: number } })? = nil

local ArenaService = {}

-- The round floor: a thin upright-axis cylinder whose top lies at y = 0. It reaches under the
-- wall, so there is no gap at the edge.
local function buildFloor(folder: Instance, floorColor: Color3)
	local floor = Build.cylinder(
		folder,
		"Floor",
		FLOOR_THICKNESS,
		(Arena.radius + Arena.wallThickness) * 2,
		-FLOOR_THICKNESS,
		0,
		0,
		floorColor,
		Enum.Material.SmoothPlastic,
		0
	)
	floor.CanCollide = true
	floor.CanQuery = true
	floor.CanTouch = true
end

-- The wall: a ring of straight pieces around the floor. Each piece is a flat block whose inner
-- face touches the circle; it is as long as the outer face, so neighbors leave no gap.
local function buildWalls(folder: Instance, wallColor: Color3)
	local walls = Instance.new("Folder")
	walls.Name = "Walls"
	local count = Arena.wallSegments
	local thick = Arena.wallThickness
	local height = Arena.wallHeight
	local length = 2 * (Arena.radius + thick) * math.tan(math.pi / count) * WALL_OVERLAP
	for index = 1, count do
		local angle = (index - 0.5) / count * math.pi * 2
		local distance = Arena.radius + thick / 2
		local position = Vector3.new(math.cos(angle) * distance, height / 2, math.sin(angle) * distance)
		-- The thin side (local Z) points away from the middle.
		local part = Instance.new("Part")
		part.Name = "Wall"
		part.Size = Vector3.new(length, height, thick)
		part.CFrame = CFrame.new(position) * CFrame.Angles(0, math.pi / 2 - angle, 0)
		part.Anchored = true
		part.CanCollide = true
		part.Color = wallColor
		part.Material = Enum.Material.SmoothPlastic
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.Parent = walls
	end
	walls.Parent = folder
end

-- Parts of the Studio baseplate template. Its top lies at the same height as the arena floor,
-- so both flicker (z-fighting) and the grey ground shows through. They are removed at the start.
local TEMPLATE_PARTS = { "Baseplate", "SpawnLocation" }

local function removeTemplateParts()
	for _, name in TEMPLATE_PARTS do
		local part = workspace:FindFirstChild(name)
		if part ~= nil then
			part:Destroy()
			log.info("template part removed", { name = name })
		end
	end
end

-- A thin light column in the middle shows from afar where the waterhole is (looks only, no
-- collision). The waterhole itself is built by the SceneryService.
local BEACON_BOTTOM = 0.6
local BEACON_HEIGHT = 80
local BEACON_DIAMETER = 3
local BEACON_TRANSPARENCY = 0.6

local function buildBeacon(folder: Instance)
	Build.cylinder(
		folder,
		"OasisBeacon",
		BEACON_HEIGHT,
		BEACON_DIAMETER,
		BEACON_BOTTOM,
		0,
		0,
		Color3.fromRGB(150, 220, 255),
		Enum.Material.Neon,
		BEACON_TRANSPARENCY
	)
end

local function build()
	removeTemplateParts()
	local existing = workspace:FindFirstChild("Arena")
	if existing ~= nil then
		existing:Destroy()
	end

	local folder = Instance.new("Folder")
	folder.Name = "Arena"

	local floorColor = Color3.fromRGB(110, 170, 90)
	local wallColor = Color3.fromRGB(120, 100, 80)

	buildFloor(folder, floorColor)
	buildWalls(folder, wallColor)

	buildBeacon(folder)
	SceneryService.build(folder)
	DomeService.build(folder)

	folder.Parent = workspace
	log.info("arena built", { radius = Arena.radius, walls = Arena.wallSegments, wallHeight = Arena.wallHeight })
end

local function randomPoint(): { x: number, z: number }
	local x, z = FoodSpawn.pickPosition(Arena.radius, Arena.spawnMargin, function()
		return random:NextNumber()
	end)
	return { x = x, z = z }
end

-- Registers where the bots are, so nobody spawns right next to one (set by the BotService).
function ArenaService.setBotPositions(provider: () -> { { x: number, z: number } })
	botPositions = provider
end

-- Of a few random spots, the one farthest from every other player and bot in the arena.
-- `spawning` is nil for a bot.
function ArenaService.spawnPosition(spawning: Player?): Vector3
	local others: { { x: number, z: number } } = {}
	if botPositions ~= nil then
		for _, point in botPositions() do
			table.insert(others, point)
		end
	end
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if player ~= spawning and PlayerState.getMode(player) == "playing" and root ~= nil and root:IsA("BasePart") then
			table.insert(others, { x = root.Position.X, z = root.Position.Z })
		end
	end
	local candidates = {}
	for _ = 1, Arena.spawnCandidates do
		table.insert(candidates, randomPoint())
	end
	-- Nobody spawns in or right next to the oasis.
	local oasis = FoodConfig.zones.center
	local allowed = SpawnPick.outsideDisc(candidates, 0, 0, oasis.radius + oasis.spawnClearance)
	if #allowed == 0 then
		allowed = candidates
	end
	-- ... and not in or right next to a tree, rock or plant.
	local clear = {}
	for _, candidate in allowed do
		if SceneryService.isClearForSpawn(candidate.x, candidate.z) then
			table.insert(clear, candidate)
		end
	end
	if #clear > 0 then
		allowed = clear
	end
	local best = SpawnPick.best(allowed, others) or randomPoint()
	return Vector3.new(best.x, SPAWN_HEIGHT, best.z)
end

-- Puts the character of a player into the arena (entering from the lobby). Returns false
-- when the character cannot be moved.
function ArenaService.placeInArena(player: Player): boolean
	local character = player.Character
	if character == nil then
		return false
	end
	local position = ArenaService.spawnPosition(player)
	local ok, err = pcall(function()
		character:PivotTo(CFrame.new(position))
	end)
	if not ok then
		log.error("spawn placement failed", { userId = player.UserId, error = tostring(err) })
		return false
	end
	log.info("spawned in arena", { userId = player.UserId, x = position.X, z = position.Z })
	return true
end

function ArenaService.start()
	build()
	log.info("started")
end

return ArenaService
