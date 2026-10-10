--!strict
-- Builds the arena (floor, walls and the oasis from parts) and finds a spawn spot inside it
-- for players who enter from the lobby. Only checkable in Roblox Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log = require(Shared:WaitForChild("Log"))
local FoodSpawn = require(Shared:WaitForChild("FoodSpawn"))
local SpawnPick = require(Shared:WaitForChild("SpawnPick"))
local Arena = require(Shared:WaitForChild("Config"):WaitForChild("Arena"))
local FoodConfig = require(Shared:WaitForChild("Config"):WaitForChild("Food"))

local Build = require(script.Parent:WaitForChild("Build"))
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))

local log = Log.new("ArenaService")

-- Height above the floor at which characters appear (they drop to the floor).
local SPAWN_HEIGHT = 5

local random = Random.new()

local ArenaService = {}

local function makePart(parent: Instance, name: string, size: Vector3, position: Vector3, color: Color3)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.CanCollide = true
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
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

-- The oasis in the middle: a flat disc just above the floor and a thin light column that
-- shows from afar where the middle is (looks only, no collision).
local OASIS_THICKNESS = 0.2
local BEACON_HEIGHT = 80
local BEACON_DIAMETER = 3
local BEACON_TRANSPARENCY = 0.6

local function buildOasis(folder: Instance)
	local radius = FoodConfig.zones.center.radius
	Build.cylinder(
		folder,
		"Oasis",
		OASIS_THICKNESS,
		radius * 2,
		0,
		0,
		0,
		Color3.fromRGB(70, 140, 210),
		Enum.Material.SmoothPlastic,
		0
	)
	Build.cylinder(
		folder,
		"OasisBeacon",
		BEACON_HEIGHT,
		BEACON_DIAMETER,
		OASIS_THICKNESS,
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

	local size = Arena.size
	local thick = Arena.wallThickness
	local height = Arena.wallHeight
	local floorColor = Color3.fromRGB(110, 170, 90)
	local wallColor = Color3.fromRGB(120, 100, 80)

	makePart(folder, "Floor", Vector3.new(size, 1, size), Vector3.new(0, -0.5, 0), floorColor)
	local wallLength = size + 2 * thick
	local offset = size / 2 + thick / 2
	makePart(
		folder,
		"WallNorth",
		Vector3.new(wallLength, height, thick),
		Vector3.new(0, height / 2, -offset),
		wallColor
	)
	makePart(folder, "WallSouth", Vector3.new(wallLength, height, thick), Vector3.new(0, height / 2, offset), wallColor)
	makePart(folder, "WallWest", Vector3.new(thick, height, size), Vector3.new(-offset, height / 2, 0), wallColor)
	makePart(folder, "WallEast", Vector3.new(thick, height, size), Vector3.new(offset, height / 2, 0), wallColor)

	buildOasis(folder)

	folder.Parent = workspace
	log.info("arena built", { size = size, wallHeight = height })
end

local function randomPoint(): { x: number, z: number }
	local x, z = FoodSpawn.pickPosition(Arena.size, Arena.spawnMargin, function()
		return random:NextNumber()
	end)
	return { x = x, z = z }
end

-- Of a few random spots, the one farthest from every other player in the arena.
function ArenaService.spawnPosition(spawning: Player): Vector3
	local others: { { x: number, z: number } } = {}
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
