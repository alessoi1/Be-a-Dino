--!strict
-- Builds the arena (floor and walls from parts) and places every new character
-- at a random spot inside it. Only checkable in Roblox Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log = require(Shared:WaitForChild("Log"))
local FoodSpawn = require(Shared:WaitForChild("FoodSpawn"))
local SpawnPick = require(Shared:WaitForChild("SpawnPick"))
local Arena = require(Shared:WaitForChild("Config"):WaitForChild("Arena"))

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

local function build()
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

	folder.Parent = workspace
	log.info("arena built", { size = size, wallHeight = height })
end

local function randomPoint(): { x: number, z: number }
	local x, z = FoodSpawn.pickPosition(Arena.size, Arena.spawnMargin, function()
		return random:NextNumber()
	end)
	return { x = x, z = z }
end

-- Of a few random spots, the one farthest from every other living player.
function ArenaService.spawnPosition(spawning: Player): Vector3
	local others: { { x: number, z: number } } = {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if player ~= spawning and root ~= nil and root:IsA("BasePart") then
			table.insert(others, { x = root.Position.X, z = root.Position.Z })
		end
	end
	local candidates = {}
	for _ = 1, Arena.spawnCandidates do
		table.insert(candidates, randomPoint())
	end
	local best = SpawnPick.best(candidates, others) or randomPoint()
	return Vector3.new(best.x, SPAWN_HEIGHT, best.z)
end

local function placeCharacter(player: Player, character: Model)
	local position = ArenaService.spawnPosition(player)
	local ok, err = pcall(function()
		character:PivotTo(CFrame.new(position))
	end)
	if not ok then
		log.error("spawn placement failed", { userId = player.UserId, error = tostring(err) })
		return
	end
	log.info("spawned", { userId = player.UserId, x = position.X, z = position.Z })
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(character: Model)
		placeCharacter(player, character)
	end)
	if player.Character ~= nil then
		placeCharacter(player, player.Character)
	end
end

function ArenaService.start()
	build()
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	log.info("started")
end

return ArenaService
