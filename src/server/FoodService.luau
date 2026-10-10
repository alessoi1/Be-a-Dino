--!strict
-- Food on the arena: a fixed pool of parts, a data structure with the positions,
-- one server tick that checks distances (no Touched events) and a queue for the
-- pieces that grow back. Only checkable in Roblox Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log = require(Shared:WaitForChild("Log"))
local FoodField = require(Shared:WaitForChild("FoodField"))
local FoodKinds = require(Shared:WaitForChild("FoodKinds"))
local FoodSpawn = require(Shared:WaitForChild("FoodSpawn"))
local Arena = require(Shared:WaitForChild("Config"):WaitForChild("Arena"))
local FoodConfig = require(Shared:WaitForChild("Config"):WaitForChild("Food"))

local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local ServerClock = require(script.Parent:WaitForChild("ServerClock"))

type Pending = { id: number, readyAt: number }

-- Height of the food center above the floor, on top of half its size.
local FLOAT_HEIGHT = 1
-- Tries to place an outer piece outside the oasis before it is accepted anyway (a bad config
-- must not hang the server).
local OUTSIDE_TRIES = 10

local log = Log.new("FoodService")
local random = Random.new()

local field = FoodField.new()
local parts: { [number]: Part } = {}
local pending: { Pending } = {}
-- Pieces that belong to the oasis in the middle; they always grow back there.
local inOasis: { [number]: boolean } = {}
local oasis = FoodConfig.zones.center
local folder: Folder? = nil

local FoodService = {}

local function createPart(): Part
	local part = Instance.new("Part")
	part.Name = "Food"
	part.Shape = Enum.PartType.Ball
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Material = Enum.Material.SmoothPlastic
	return part
end

local function roll(): number
	return random:NextNumber()
end

local function placeFood(id: number)
	local kindIndex: number
	local x: number
	local z: number
	if inOasis[id] then
		kindIndex = FoodKinds.pickWeighted(FoodConfig.kinds, oasis.weights, roll())
		x, z = FoodSpawn.pickPositionInDisc(0, 0, oasis.radius, roll)
	else
		kindIndex = FoodKinds.pick(FoodConfig.kinds, roll())
		x, z = FoodSpawn.pickPositionOutsideDisc(Arena.size, FoodConfig.margin, 0, 0, oasis.radius, roll, OUTSIDE_TRIES)
	end
	local kind = FoodConfig.kinds[kindIndex]
	if not FoodField.place(field, id, x, z, kindIndex) then
		log.warn("food id already in use", { id = id })
		return
	end
	local part = parts[id]
	part.Size = Vector3.new(kind.size, kind.size, kind.size)
	part.Color = Color3.fromRGB(kind.color.r, kind.color.g, kind.color.b)
	part.Position = Vector3.new(x, kind.size / 2 + FLOAT_HEIGHT, z)
	part.Parent = folder
end

local function releaseFood(id: number, now: number)
	FoodField.remove(field, id)
	parts[id].Parent = nil
	table.insert(pending, FoodSpawn.schedule(id, now, FoodConfig.respawnSeconds))
end

local function respawnDue(now: number)
	local due, remaining = FoodSpawn.takeDue(pending, now)
	pending = remaining
	for _, id in due do
		placeFood(id)
	end
end

local function collectFor(player: Player, now: number)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if character == nil or humanoid == nil or root == nil or not root:IsA("BasePart") or humanoid.Health <= 0 then
		return
	end

	local radius = FoodField.pickupRadius(FoodConfig, character:GetScale())
	local position = root.Position
	local items = FoodField.inRange(field, position.X, position.Z, radius)
	if #items == 0 then
		return
	end

	local total = 0
	for _, item in items do
		total += FoodConfig.kinds[item.kind].value
		releaseFood(item.id, now)
	end
	PlayerState.addPoints(player, total)
	log.debug("food eaten", { userId = player.UserId, pieces = #items, points = total })
end

local function tick()
	local now = ServerClock.now()
	respawnDue(now)
	for _, player in Players:GetPlayers() do
		local ok, err = pcall(collectFor, player, now)
		if not ok then
			log.error("food pickup failed", { userId = player.UserId, error = tostring(err) })
		end
	end
end

function FoodService.start()
	local problems = FoodKinds.validate(FoodConfig.kinds)
	for _, problem in
		FoodKinds.validateZones(FoodConfig.kinds, FoodConfig.zones, Arena.size, FoodConfig.count, FoodConfig.margin)
	do
		table.insert(problems, problem)
	end
	if #problems > 0 then
		log.error("food config invalid, service not started", { problems = table.concat(problems, "; ") })
		return
	end

	local newFolder = Instance.new("Folder")
	newFolder.Name = "Food"
	newFolder.Parent = workspace
	folder = newFolder

	for id = 1, FoodConfig.count do
		inOasis[id] = id <= oasis.count
		parts[id] = createPart()
		placeFood(id)
	end
	log.info("food placed", { count = FoodField.count(field), oasis = oasis.count })

	local lastTick = ServerClock.now()
	RunService.Heartbeat:Connect(function()
		if ServerClock.now() - lastTick < FoodConfig.checkInterval then
			return
		end
		lastTick = ServerClock.now()
		local ok, err = pcall(tick)
		if not ok then
			log.error("food tick failed", { error = tostring(err) })
		end
	end)
	log.info("started")
end

return FoodService
