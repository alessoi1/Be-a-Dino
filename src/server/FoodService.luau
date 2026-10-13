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
local Progression = require(Shared:WaitForChild("Progression"))
local Dinos = require(Shared:WaitForChild("Config"):WaitForChild("Dinos"))
local Arena = require(Shared:WaitForChild("Config"):WaitForChild("Arena"))
local FoodConfig = require(Shared:WaitForChild("Config"):WaitForChild("Food"))

local OfferService = require(script.Parent:WaitForChild("OfferService"))
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

-- The forms of the stand-in looks (a Part with a SpecialMesh; one form per piece, no extra parts).
local MESH_TYPES: { [string]: Enum.MeshType } = {
	ball = Enum.MeshType.Sphere,
	block = Enum.MeshType.Brick,
	cylinder = Enum.MeshType.Cylinder,
	wedge = Enum.MeshType.Wedge,
}

local function createPart(): Part
	local part = Instance.new("Part")
	part.Name = "Food"
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Material = Enum.Material.SmoothPlastic
	local mesh = Instance.new("SpecialMesh")
	mesh.Name = "Look"
	mesh.Parent = part
	return part
end

-- Gives the piece the look of a variant: a simple form, or the mesh once there is one.
local function applyLook(part: Part, kind: FoodConfig.FoodKind, variant: FoodConfig.FoodVariant)
	local mesh = part:FindFirstChild("Look")
	if mesh == nil or not mesh:IsA("SpecialMesh") then
		return
	end
	local scale = Vector3.new(variant.scale.x, variant.scale.y, variant.scale.z)
	part.Size = Vector3.one * kind.size * scale
	part.Color = Color3.fromRGB(variant.color.r, variant.color.g, variant.color.b)
	if variant.meshId ~= 0 then
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.MeshId = "rbxassetid://" .. tostring(variant.meshId)
		mesh.Scale = Vector3.new(variant.meshScale.x, variant.meshScale.y, variant.meshScale.z)
	else
		mesh.MeshType = MESH_TYPES[variant.shape] or Enum.MeshType.Sphere
		mesh.MeshId = ""
		mesh.Scale = Vector3.one
	end
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
		x, z =
			FoodSpawn.pickPositionOutsideDisc(Arena.radius, FoodConfig.margin, 0, 0, oasis.radius, roll, OUTSIDE_TRIES)
	end
	local kind = FoodConfig.kinds[kindIndex]
	if not FoodField.place(field, id, x, z, kindIndex) then
		log.warn("food id already in use", { id = id })
		return
	end
	local part = parts[id]
	local variantIndex = FoodKinds.pickVariant(kind, roll())
	local variant = kind.variants[variantIndex]
	if variant ~= nil then
		applyLook(part, kind, variant)
	else
		log.warn("food kind without a look", { kind = kind.id })
		part.Size = Vector3.one * kind.size
	end
	-- Turned at random, so the pieces do not all point the same way.
	part.CFrame = CFrame.new(x, part.Size.Y / 2 + FLOAT_HEIGHT, z) * CFrame.Angles(0, roll() * math.pi * 2, 0)
	-- Display only: the autofarm of the client prefers valuable pieces.
	part:SetAttribute("Value", kind.value)
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

-- Takes the pieces within reach of a dino at (x, z) with the given scale and returns the points
-- they give for a dino whose food unit is `unit` (0 when there is nothing in reach).
local function takeAround(x: number, z: number, scale: number, unit: number, now: number): number
	local items = FoodField.inRange(field, x, z, FoodField.pickupRadius(FoodConfig, scale))
	local total = 0
	for _, item in items do
		total += Progression.foodGain(unit, FoodConfig.kinds[item.kind].value)
		releaseFood(item.id, now)
	end
	return total
end

-- The pieces within `radius` of a point, for a bot that looks for food. Each piece has its value.
function FoodService.piecesNear(
	x: number,
	z: number,
	radius: number
): { { id: number, x: number, z: number, value: number } }
	local found = {}
	for _, item in FoodField.inRange(field, x, z, radius) do
		table.insert(found, { id = item.id, x = item.x, z = item.z, value = FoodConfig.kinds[item.kind].value })
	end
	return found
end

-- A bot at (x, z) eats what is in its reach. Returns the points (0 when nothing was in reach).
function FoodService.collectAt(x: number, z: number, scale: number, unit: number): number
	return takeAround(x, z, scale, unit, ServerClock.now())
end

local function collectFor(player: Player, now: number)
	if PlayerState.getMode(player) ~= "playing" then
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if character == nil or humanoid == nil or root == nil or not root:IsA("BasePart") or humanoid.Health <= 0 then
		return
	end

	-- A piece is worth more on a higher stage, so every stage takes about the same number of pieces.
	local growth = PlayerState.get(player)
	local unit = if growth ~= nil then Dinos[growth.stageIndex].foodUnit else Dinos[1].foodUnit
	local position = root.Position
	local total = takeAround(position.X, position.Z, character:GetScale(), unit, now)
	if total <= 0 then
		return
	end
	-- A running growth potion raises the points from food (not from eating players).
	total *= OfferService.growthFactor(player)
	PlayerState.addPoints(player, total)
	log.debug("food eaten", { userId = player.UserId, points = total })
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
		FoodKinds.validateZones(FoodConfig.kinds, FoodConfig.zones, Arena.radius, FoodConfig.count, FoodConfig.margin)
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
