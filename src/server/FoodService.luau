--!strict
-- Food on the arena: pools of parts (one pool per look, so a mesh piece never changes its mesh), a
-- data structure with the positions, one server tick that checks distances (no Touched events) and a
-- queue for the pieces that grow back. A look with a mesh is a MeshPart cloned from a template (the
-- painted vertex colors show); a look without one is a simple form. Only checkable in Roblox Studio.

local AssetService = game:GetService("AssetService")
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

local ComboService = require(script.Parent:WaitForChild("ComboService"))
local FrenzyService = require(script.Parent:WaitForChild("FrenzyService"))
local OfferService = require(script.Parent:WaitForChild("OfferService"))
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local QuestService = require(script.Parent:WaitForChild("QuestService"))
local ServerClock = require(script.Parent:WaitForChild("ServerClock"))

type Pending = { id: number, readyAt: number }

-- Height of the food center above the floor, on top of half its size.
local FLOAT_HEIGHT = 1
-- Tries to place an outer piece outside the oasis before it is accepted anyway (a bad config
-- must not hang the server).
local OUTSIDE_TRIES = 10
-- Seconds the food meshes may take to load, and the pause between two looks at the loading.
local MESH_WAIT_SECONDS = 20
local MESH_WAIT_STEP = 0.1

local log = Log.new("FoodService")
local random = Random.new()

local field = FoodField.new()
-- The part of every piece that is on the floor now, and which pool it belongs to.
local parts: { [number]: BasePart } = {}
local partKeys: { [number]: string } = {}
-- Mesh parts loaded once per look (key = kind id / look id), and the parts that are free again.
local templates: { [string]: MeshPart } = {}
local freeParts: { [string]: { BasePart } } = {}
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

-- Gives a stand-in piece the simple form and color of its look.
local function applyStandIn(part: Part, kind: FoodConfig.FoodKind, variant: FoodConfig.FoodVariant)
	local mesh = part:FindFirstChild("Look")
	if mesh == nil or not mesh:IsA("SpecialMesh") then
		return
	end
	local scale = Vector3.new(variant.scale.x, variant.scale.y, variant.scale.z)
	part.Size = Vector3.one * kind.size * scale
	part.Color = Color3.fromRGB(variant.color.r, variant.color.g, variant.color.b)
	mesh.MeshType = MESH_TYPES[variant.shape] or Enum.MeshType.Sphere
	mesh.MeshId = ""
	mesh.Scale = Vector3.one
end

local function lookKey(kind: FoodConfig.FoodKind, variant: FoodConfig.FoodVariant): string
	return kind.id .. "/" .. variant.id
end

-- Loads the mesh of every look that has one, all at once; a mesh that cannot be loaded leaves its
-- look as the simple form (and is logged).
local function loadTemplates()
	local waiting = 0
	local wanted = 0
	for _, kind in FoodConfig.kinds do
		for _, variant in kind.variants do
			if variant.meshId ~= 0 then
				wanted += 1
				waiting += 1
				local key = lookKey(kind, variant)
				task.spawn(function()
					local ok, result = pcall(function()
						return AssetService:CreateMeshPartAsync(Content.fromAssetId(variant.meshId))
					end)
					if ok then
						templates[key] = result
					else
						log.error(
							"food mesh not loaded",
							{ look = key, meshId = variant.meshId, error = tostring(result) }
						)
					end
					waiting -= 1
				end)
			end
		end
	end
	local waited = 0
	while waiting > 0 and waited < MESH_WAIT_SECONDS do
		task.wait(MESH_WAIT_STEP)
		waited += MESH_WAIT_STEP
	end
	local loaded = 0
	for _ in templates do
		loaded += 1
	end
	if waiting > 0 then
		log.warn("food meshes still loading, those looks use the simple form", { missing = waiting })
	end
	log.info("food meshes loaded", { loaded = loaded, wanted = wanted })
end

-- A part for a piece with this look: a free one of its pool, or a new one (a clone of the mesh
-- template, or a simple stand-in). Returns the part and its pool key.
local function takePart(kind: FoodConfig.FoodKind, variant: FoodConfig.FoodVariant): (BasePart, string)
	local key = lookKey(kind, variant)
	local pool = freeParts[key]
	if pool ~= nil and #pool > 0 then
		return table.remove(pool) :: BasePart, key
	end
	local template = templates[key]
	if template ~= nil then
		local clone = template:Clone()
		clone.Name = "Food"
		clone.Anchored = true
		clone.CanCollide = false
		clone.CanTouch = false
		clone.CanQuery = false
		clone.CastShadow = false
		clone.Massless = true
		-- The mesh keeps its proportions; the part is as big as the kind says. White shows the painted colors.
		clone.Size = template.Size * kind.size
		clone.Color = Color3.new(1, 1, 1)
		return clone, key
	end
	local stand = createPart()
	applyStandIn(stand, kind, variant)
	return stand, key
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
	local variantIndex = FoodKinds.pickVariant(kind, roll())
	local variant = kind.variants[variantIndex]
	if variant == nil then
		log.warn("food kind without a look", { kind = kind.id })
		FoodField.remove(field, id)
		table.insert(pending, FoodSpawn.schedule(id, ServerClock.now(), FoodConfig.respawnSeconds))
		return
	end
	local part, key = takePart(kind, variant)
	parts[id] = part
	partKeys[id] = key
	-- Turned at random, so the pieces do not all point the same way.
	part.CFrame = CFrame.new(x, part.Size.Y / 2 + FLOAT_HEIGHT, z) * CFrame.Angles(0, roll() * math.pi * 2, 0)
	-- Display only: the autofarm of the client prefers valuable pieces.
	part:SetAttribute("Value", kind.value)
	part.Parent = folder
end

local function releaseFood(id: number, now: number)
	FoodField.remove(field, id)
	local part = parts[id]
	if part ~= nil then
		part.Parent = nil
		local key = partKeys[id]
		local pool = freeParts[key]
		if pool == nil then
			pool = {}
			freeParts[key] = pool
		end
		table.insert(pool, part)
		parts[id] = nil
	end
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
	-- The food frenzy of the whole server raises it as well.
	total *= FrenzyService.factor()
	PlayerState.addPoints(player, total)
	local combo = ComboService.hit(player, now)
	QuestService.record(player, "food", 1)
	QuestService.record(player, "combo", combo)
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

	loadTemplates()

	for id = 1, FoodConfig.count do
		inOasis[id] = id <= oasis.count
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
