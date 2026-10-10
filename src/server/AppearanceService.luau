--!strict
-- Shows every player as the dino of their current stage: hides the avatar and welds
-- the dino look to the figure. A real model (ServerStorage/Models/<stage id>) is used
-- when it exists and passes the checks, otherwise the placeholder built from parts
-- (Config/DinoLooks). The Humanoid stays the physics body, so movement is unchanged.
-- Only checkable in Roblox Studio.

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log = require(Shared:WaitForChild("Log"))
local DinoLook = require(Shared:WaitForChild("DinoLook"))
local Dinos = require(Shared:WaitForChild("Config"):WaitForChild("Dinos"))
local DinoLooks = require(Shared:WaitForChild("Config"):WaitForChild("DinoLooks"))
local Arena = require(Shared:WaitForChild("Config"):WaitForChild("Arena"))

local PlayerState = require(script.Parent:WaitForChild("PlayerState"))

local LOOK_NAME = "DinoLook"
local MODELS_FOLDER = "Models"
-- Seconds to wait for the parts of a new character.
local CHARACTER_WAIT = 5
-- Cloud particles: lifetime range in seconds and speed range in studs per second.
local CLOUD_LIFETIME_MIN = 0.8
local CLOUD_LIFETIME_MAX = 1.2
local CLOUD_SPEED_MIN = 8
local CLOUD_SPEED_MAX = 14
local CLOUD_SIZE = 1.5
-- Look of the glow while a player is protected after a respawn.
local PROTECTION_FILL_TRANSPARENCY = 0.7
local PROTECTION_OUTLINE_TRANSPARENCY = 0.3

local log = Log.new("AppearanceService")

local AppearanceService = {}

local function buildPlaceholder(stageId: string): Model?
	local look = DinoLooks.looks[stageId]
	if look == nil then
		return nil
	end
	local model = Instance.new("Model")
	model.Name = stageId
	for _, spec in look.parts do
		local part = Instance.new("Part")
		part.Name = spec.name
		part.Shape = if spec.shape == "Ball" then Enum.PartType.Ball else Enum.PartType.Block
		part.Size = Vector3.new(spec.size.x, spec.size.y, spec.size.z)
		part.Color = Color3.fromRGB(spec.color.r, spec.color.g, spec.color.b)
		part.Material = Enum.Material.SmoothPlastic
		part.CFrame = CFrame.new(spec.offset.x, spec.offset.y, spec.offset.z)
		part.Parent = model
	end
	-- Pivot at the figure center, so scaling and placing work from there.
	model.WorldPivot = CFrame.new()
	return model
end

-- Returns false with a log entry when the model breaks the rules.
local function checkModel(stageId: string, model: Model): boolean
	local partCount = 0
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			partCount += 1
		elseif descendant:IsA("LuaSourceContainer") or descendant:IsA("Sound") then
			log.error(
				"model rejected",
				{ stage = stageId, reason = "forbidden_instance", class = descendant.ClassName }
			)
			return false
		end
	end
	if partCount == 0 or partCount > DinoLooks.maxParts then
		log.error(
			"model rejected",
			{ stage = stageId, reason = "part_count", parts = partCount, max = DinoLooks.maxParts }
		)
		return false
	end
	return true
end

local function loadLook(stageId: string): Model?
	local models = ServerStorage:FindFirstChild(MODELS_FOLDER)
	local template = models and models:FindFirstChild(stageId)
	if template ~= nil and template:IsA("Model") and checkModel(stageId, template) then
		local clone = template:Clone()
		log.debug("real model used", { stage = stageId })
		return clone
	end
	if template ~= nil and not template:IsA("Model") then
		log.error("model rejected", { stage = stageId, reason = "not_a_model", class = template.ClassName })
	end
	return buildPlaceholder(stageId)
end

-- Makes the avatar invisible; the dino look is skipped.
local function hideAvatar(character: Model)
	local look = character:FindFirstChild(LOOK_NAME)
	for _, descendant in character:GetDescendants() do
		if look ~= nil and descendant:IsDescendantOf(look) then
			continue
		end
		if descendant:IsA("Accessory") or descendant:IsA("Clothing") or descendant:IsA("ShirtGraphic") then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") or descendant:IsA("Decal") then
			descendant.Transparency = 1
		end
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid ~= nil then
		humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	end
end

local function weld(root: BasePart, part: BasePart)
	part.Anchored = false
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	local constraint = Instance.new("WeldConstraint")
	constraint.Part0 = root
	constraint.Part1 = part
	constraint.Parent = part
end

local function attachLook(player: Player, character: Model, stageId: string)
	local root = character:WaitForChild("HumanoidRootPart", CHARACTER_WAIT)
	if root == nil or not root:IsA("BasePart") or character.Parent == nil then
		log.warn("look not attached", { userId = player.UserId, reason = "no_character" })
		return
	end

	local old = character:FindFirstChild(LOOK_NAME)
	if old ~= nil then
		old:Destroy()
	end

	local look = loadLook(stageId)
	if look == nil then
		log.error("no look for stage", { userId = player.UserId, stage = stageId })
		return
	end
	look.Name = LOOK_NAME
	look:ScaleTo(character:GetScale())
	look:PivotTo(root.CFrame)
	look.Parent = character
	for _, descendant in look:GetDescendants() do
		if descendant:IsA("BasePart") then
			weld(root, descendant)
		end
	end
	hideAvatar(character)
	log.debug("look attached", { userId = player.UserId, stage = stageId })
end

-- Removes the dino look at once (used when a player is eaten).
function AppearanceService.removeLook(character: Model)
	local look = character:FindFirstChild(LOOK_NAME)
	if look ~= nil then
		look:Destroy()
	end
end

-- White glow around the character while the spawn protection lasts.
local function showProtection(character: Model)
	local highlight = Instance.new("Highlight")
	highlight.Name = "SpawnProtection"
	highlight.Adornee = character
	highlight.FillColor = Color3.fromRGB(255, 255, 255)
	highlight.FillTransparency = PROTECTION_FILL_TRANSPARENCY
	highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	highlight.OutlineTransparency = PROTECTION_OUTLINE_TRANSPARENCY
	highlight.Parent = character
	Debris:AddItem(highlight, Arena.spawnProtectionSeconds)
end

function AppearanceService.playCloud(character: Model)
	local root = character:FindFirstChild("HumanoidRootPart")
	if root == nil or not root:IsA("BasePart") then
		return
	end
	local scale = character:GetScale()
	local attachment = Instance.new("Attachment")
	attachment.Parent = root
	local emitter = Instance.new("ParticleEmitter")
	emitter.Enabled = false
	emitter.Rate = 0
	emitter.Lifetime = NumberRange.new(CLOUD_LIFETIME_MIN, CLOUD_LIFETIME_MAX)
	emitter.Speed = NumberRange.new(CLOUD_SPEED_MIN * scale, CLOUD_SPEED_MAX * scale)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, CLOUD_SIZE * scale),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Color = ColorSequence.new(Color3.fromRGB(240, 240, 240))
	emitter.Parent = attachment
	emitter:Emit(DinoLooks.effect.particleCount)
	Debris:AddItem(attachment, DinoLooks.effect.seconds + CLOUD_LIFETIME_MAX)
end

local function onStage(player: Player, stageId: string, reason: "reset" | "grow")
	local character = player.Character
	if character == nil then
		return
	end
	-- The character may still be assembling, so do not block the caller.
	task.spawn(function()
		local ok, err = pcall(attachLook, player, character, stageId)
		if not ok then
			log.error("attach failed", { userId = player.UserId, stage = stageId, error = tostring(err) })
			return
		end
		if reason == "grow" then
			AppearanceService.playCloud(character)
		else
			showProtection(character)
		end
	end)
end

function AppearanceService.start()
	local problems = DinoLook.validate(Dinos, DinoLooks.looks, DinoLooks.maxParts)
	if #problems > 0 then
		log.error("dino looks invalid", { problems = table.concat(problems, "; ") })
	end

	PlayerState.onStage(onStage)

	-- If an avatar is still loaded (setting off), hide it as soon as it is complete.
	local function watch(player: Player)
		player.CharacterAppearanceLoaded:Connect(function(character: Model)
			hideAvatar(character)
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	log.info("started")
end

return AppearanceService
