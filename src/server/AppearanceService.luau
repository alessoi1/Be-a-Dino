--!strict
-- Shows every player as the dino of their current stage: hides the avatar and welds
-- the dino look to the figure. A real model (ServerStorage/Models/<stage id>) is used
-- when it exists and passes the checks, then the real shape of the dino (the meshes of
-- Config/DinoMeshes, colored per dino), otherwise the placeholder built from parts
-- (Config/DinoLooks). The Humanoid stays the physics body, so movement is unchanged.
-- Only checkable in Roblox Studio.

local AssetService = game:GetService("AssetService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log = require(Shared:WaitForChild("Log"))
local DinoBody = require(Shared:WaitForChild("DinoBody"))
local DinoLook = require(Shared:WaitForChild("DinoLook"))
local DinoMesh = require(Shared:WaitForChild("DinoMesh"))
local Variants = require(Shared:WaitForChild("Variants"))
local Dinos = require(Shared:WaitForChild("Config"):WaitForChild("Dinos"))
local DinoLooks = require(Shared:WaitForChild("Config"):WaitForChild("DinoLooks"))
local DinoMeshes = require(Shared:WaitForChild("Config"):WaitForChild("DinoMeshes"))
local VariantConfig = require(Shared:WaitForChild("Config"):WaitForChild("Variants"))

local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local ServerClock = require(script.Parent:WaitForChild("ServerClock"))

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

-- Gives the id of the variant shown on a dino of a player (nil is the normal look).
type VariantProvider = (player: Player, stageId: string) -> string?

local variantProvider: VariantProvider? = nil

-- The Roblox materials of the variants (the config names them as text).
local MATERIALS: { [string]: Enum.Material } = {
	Neon = Enum.Material.Neon,
	Metal = Enum.Material.Metal,
	SmoothPlastic = Enum.Material.SmoothPlastic,
	Plastic = Enum.Material.Plastic,
}

local AppearanceService = {}

-- Registers where the variants come from (set by the VariantService at the start).
function AppearanceService.setVariantProvider(provider: VariantProvider)
	variantProvider = provider
end

-- Looks built from plans are made once and kept.
local plannedLooks: { [string]: any } = {}

-- The look of a dino: hand-written, or built from its plan (and kept).
local function lookFor(stageId: string): { parts: { any } }?
	local explicit = DinoLooks.looks[stageId]
	if explicit ~= nil then
		return explicit
	end
	local cached = plannedLooks[stageId]
	if cached ~= nil then
		return cached
	end
	local planned = DinoLooks.plans[stageId]
	if planned == nil then
		return nil
	end
	local built = DinoBody.build(planned)
	plannedLooks[stageId] = built
	return built
end

local function buildPlaceholder(stageId: string, variantId: string?): Model?
	local look = lookFor(stageId)
	if look == nil then
		return nil
	end
	local variant = if variantId ~= nil then Variants.find(VariantConfig.variants, variantId) else nil
	local model = Instance.new("Model")
	model.Name = stageId
	if variant ~= nil then
		-- The client animates the rainbow variant near the camera (see VariantEffects).
		model:SetAttribute("Variant", variant.id)
	end
	local count = #look.parts
	for index, spec in look.parts do
		local part = Instance.new("Part")
		part.Name = spec.name
		part.Shape = if spec.shape == "Ball" then Enum.PartType.Ball else Enum.PartType.Block
		part.Size = Vector3.new(spec.size.x, spec.size.y, spec.size.z)
		local color = spec.color
		local material = Enum.Material.SmoothPlastic
		if variant ~= nil then
			local appearance = Variants.appearance(
				variant,
				spec.color,
				spec.role,
				index,
				count,
				VariantConfig.rainbowSaturation,
				VariantConfig.rainbowValue
			)
			color = appearance.color
			material = MATERIALS[appearance.material] or material
			part.Transparency = appearance.transparency
		end
		part.Color = Color3.fromRGB(color.r, color.g, color.b)
		part.Material = material
		part.CFrame = CFrame.new(spec.offset.x, spec.offset.y, spec.offset.z)
		part.Parent = model
	end
	-- Pivot at the figure center, so scaling and placing work from there.
	model.WorldPivot = CFrame.new()
	return model
end

-- The loaded meshes of every template: template name -> part name -> MeshPart (never shown, only
-- cloned). The state is "loading" until the first try is over.
local meshParts: { [string]: { [string]: MeshPart } } = {}
local meshState: "loading" | "ready" | "failed" = "loading"
-- Seconds between two checks while a dino waits for the meshes.
local MESH_WAIT_STEP = 0.1

-- Loads every mesh of every template. A mesh that cannot be loaded (wrong id, no permission, no
-- connection) is logged and the dinos of that template keep their placeholder.
local function loadMeshes()
	local failed = false
	for templateName, template in DinoMeshes.templates do
		local parts: { [string]: MeshPart } = {}
		for _, spec in template.parts do
			local ok, result = pcall(function()
				return AssetService:CreateMeshPartAsync(Content.fromAssetId(spec.meshId))
			end)
			if ok then
				parts[spec.name] = result
			else
				failed = true
				log.error(
					"mesh not loaded",
					{ template = templateName, part = spec.name, meshId = spec.meshId, error = tostring(result) }
				)
			end
		end
		meshParts[templateName] = parts
	end
	meshState = if failed then "failed" else "ready"
	log.info("meshes loaded", { state = meshState })
end

local function colorOf(color: { r: number, g: number, b: number }): Color3
	return Color3.fromRGB(color.r, color.g, color.b)
end

-- The look of a dino from its real shape: the meshes of the template, colored for this dino
-- (and its variant). Nil when the dino has no shape yet or the meshes are not usable.
local function buildMeshLook(stageId: string, variantId: string?): Model?
	local entry = DinoMesh.resolve(stageId, DinoLooks.plans, DinoMeshes.dinos, DinoMeshes.templates)
	if entry == nil then
		return nil
	end
	local waited = 0
	while meshState == "loading" and waited < DinoMeshes.loadWaitSeconds do
		task.wait(MESH_WAIT_STEP)
		waited += MESH_WAIT_STEP
	end
	local loaded = meshParts[entry.template]
	if meshState == "loading" then
		log.warn("meshes still loading, placeholder used", { stage = stageId })
		return nil
	end
	if loaded == nil then
		return nil
	end

	local template = DinoMeshes.templates[entry.template]
	local variant = if variantId ~= nil then Variants.find(VariantConfig.variants, variantId) else nil
	local varied = 0
	for _, spec in template.parts do
		if DinoMesh.isVaried(spec.role) then
			varied += 1
		end
	end

	local model = Instance.new("Model")
	model.Name = stageId
	if variant ~= nil then
		-- The client animates the rainbow variant near the camera (see VariantEffects).
		model:SetAttribute("Variant", variant.id)
	end
	local variedIndex = 0
	for _, spec in template.parts do
		local source = loaded[spec.name]
		if source == nil then
			continue
		end
		local part = source:Clone()
		part.Name = spec.name
		part.CFrame = CFrame.new(spec.offset.x, spec.offset.y, spec.offset.z)
		local color = DinoMesh.colorFor(spec.role, entry, DinoMeshes.fixed)
		if DinoMesh.isVaried(spec.role) then
			variedIndex += 1
			if variant ~= nil then
				local appearance = Variants.appearance(
					variant,
					color,
					spec.role,
					variedIndex,
					varied,
					VariantConfig.rainbowSaturation,
					VariantConfig.rainbowValue
				)
				color = appearance.color
				part.Material = MATERIALS[appearance.material] or part.Material
				part.Transparency = appearance.transparency
			end
		else
			-- Eyes and the dark details do not change with the variants (also not the rainbow).
			part:SetAttribute("NoVariant", true)
		end
		part.Color = colorOf(color)
		part.Parent = model
	end
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

local function loadLook(stageId: string, variantId: string?): Model?
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
	local meshLook = buildMeshLook(stageId, variantId)
	if meshLook ~= nil then
		return meshLook
	end
	return buildPlaceholder(stageId, variantId)
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

-- Scales the look to the character, puts it on the root and welds every part to it.
local function mountLook(character: Model, root: BasePart, look: Model)
	look.Name = LOOK_NAME
	look:ScaleTo(character:GetScale())
	look:PivotTo(root.CFrame)
	look.Parent = character
	for _, descendant in look:GetDescendants() do
		if descendant:IsA("BasePart") then
			weld(root, descendant)
		end
	end
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

	local variantId: string? = nil
	if variantProvider ~= nil then
		local provided, result = pcall(variantProvider, player, stageId)
		if provided then
			variantId = result
		else
			log.error("variant provider failed", { userId = player.UserId, stage = stageId, error = tostring(result) })
		end
	end
	local look = loadLook(stageId, variantId)
	if look == nil then
		log.error("no look for stage", { userId = player.UserId, stage = stageId })
		return
	end
	mountLook(character, root, look)
	hideAvatar(character)
	log.debug("look attached", { userId = player.UserId, stage = stageId })
end

-- Gives a bot (a model with a HumanoidRootPart and no player) the dino look of a stage.
function AppearanceService.attachBotLook(model: Model, stageId: string): boolean
	local root = model:FindFirstChild("HumanoidRootPart")
	if root == nil or not root:IsA("BasePart") or model.Parent == nil then
		log.warn("bot look not attached", { stage = stageId, reason = "no_root" })
		return false
	end
	local old = model:FindFirstChild(LOOK_NAME)
	if old ~= nil then
		old:Destroy()
	end
	local look = loadLook(stageId, nil)
	if look == nil then
		log.error("no look for stage", { stage = stageId, bot = true })
		return false
	end
	mountLook(model, root, look)
	log.debug("bot look attached", { stage = stageId })
	return true
end

-- Removes the dino look at once (used when a player is eaten).
function AppearanceService.removeLook(character: Model)
	local look = character:FindFirstChild(LOOK_NAME)
	if look ~= nil then
		look:Destroy()
	end
end

-- White glow around the character while the spawn protection lasts.
local function showProtection(character: Model, seconds: number)
	local highlight = Instance.new("Highlight")
	highlight.Name = "SpawnProtection"
	highlight.Adornee = character
	highlight.FillColor = Color3.fromRGB(255, 255, 255)
	highlight.FillTransparency = PROTECTION_FILL_TRANSPARENCY
	highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	highlight.OutlineTransparency = PROTECTION_OUTLINE_TRANSPARENCY
	highlight.Parent = character
	Debris:AddItem(highlight, seconds)
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

local function onStage(player: Player, stageId: string, reason: "reset" | "grow" | "round")
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
		elseif reason == "round" then
			-- Lasts as long as the protection of the server (a shield potion makes it longer).
			local seconds = PlayerState.protectedUntil(player) - ServerClock.now()
			if seconds > 0 then
				showProtection(character, seconds)
			end
		end
	end)
end

-- Builds the look of the current dino again (for example after another variant was chosen).
function AppearanceService.refresh(player: Player, stageId: string)
	local character = player.Character
	if character == nil then
		return
	end
	task.spawn(function()
		local ok, err = pcall(attachLook, player, character, stageId)
		if not ok then
			log.error("refresh failed", { userId = player.UserId, stage = stageId, error = tostring(err) })
		end
	end)
end

function AppearanceService.start()
	local problems = DinoLook.validate(Dinos, DinoBody.resolveAll(DinoLooks.looks, DinoLooks.plans), DinoLooks.maxParts)
	if #problems > 0 then
		log.error("dino looks invalid", { problems = table.concat(problems, "; ") })
	end

	local meshProblems = DinoMesh.validate(DinoMeshes.templates, DinoMeshes.dinos, DinoMeshes.fixed, DinoLooks.maxParts)
	if #meshProblems > 0 then
		log.error("dino meshes invalid", { problems = table.concat(meshProblems, "; ") })
		meshState = "failed"
	else
		task.spawn(loadMeshes)
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
