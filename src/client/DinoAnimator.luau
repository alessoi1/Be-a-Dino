--!strict
-- Animates the dinos while they walk: turns the joints of the legs and the tail (the Motor6Ds the
-- server builds into every real dino shape) with the angles from DinoAnim. This runs only on this
-- client, only for dinos near the camera, and sends nothing; the speed comes from how far the
-- dino moved since the last update. Dinos with a placeholder look have no joints and stay stiff.
-- Only checkable in Roblox Studio.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local DinoAnim = require(Shared:WaitForChild("DinoAnim"))
local Log = require(Shared:WaitForChild("Log"))
local AnimationConfig = require(Shared:WaitForChild("Config"):WaitForChild("Animation"))

-- The look model inside a character is called like this (see AppearanceService).
local LOOK_NAME = "DinoLook"
-- Bots live in this folder of the workspace (see BotService).
local BOTS_FOLDER = "Bots"

type Entry = {
	container: Model,
	root: BasePart,
	motors: { [string]: Motor6D },
	state: DinoAnim.State,
	-- Where the dino was at the last update, and when.
	lastPosition: Vector3,
	lastTime: number,
	-- Whether the joints were moved at the last update (they are reset when the dino is far away).
	posed: boolean,
}

local log = Log.new("DinoAnimator")

local DinoAnimator = {}

local function newEntry(container: Model, look: Model): Entry?
	local root = container:FindFirstChild("HumanoidRootPart")
	if root == nil or not root:IsA("BasePart") then
		return nil
	end
	local motors: { [string]: Motor6D } = {}
	for _, descendant in look:GetDescendants() do
		if descendant:IsA("Motor6D") and DinoAnim.LIMBS[descendant.Name] then
			motors[descendant.Name] = descendant
		end
	end
	if next(motors) == nil then
		return nil
	end
	return {
		container = container,
		root = root,
		motors = motors,
		state = DinoAnim.newState(),
		lastPosition = root.Position,
		lastTime = os.clock(),
		posed = false,
	}
end

-- Sets the joints of an entry back to the straight pose.
local function straighten(entry: Entry)
	for _, motor in entry.motors do
		motor.Transform = CFrame.identity
	end
	entry.posed = false
end

local function update(entry: Entry, now: number)
	local elapsed = now - entry.lastTime
	if elapsed <= 0 then
		return
	end
	local position = entry.root.Position
	local moved = Vector3.new(position.X - entry.lastPosition.X, 0, position.Z - entry.lastPosition.Z)
	local speed = moved.Magnitude / elapsed
	entry.lastPosition = position
	entry.lastTime = now

	local scale = entry.container:GetScale()
	entry.state = DinoAnim.step(AnimationConfig, entry.state, speed, scale, elapsed)
	local amount = DinoAnim.amount(AnimationConfig, speed)
	for name, motor in entry.motors do
		local angle = DinoAnim.angle(AnimationConfig, entry.state, name, amount)
		motor.Transform = if name == "tail" then CFrame.Angles(0, angle, 0) else CFrame.Angles(angle, 0, 0)
	end
	entry.posed = true
end

function DinoAnimator.start()
	local problems = DinoAnim.validate(AnimationConfig)
	if #problems > 0 then
		log.error("animation config invalid, not started", { problems = table.concat(problems, "; ") })
		return
	end

	-- One entry per look model; a new look (a new stage) gets a new entry.
	local entries: { [Model]: Entry } = {}

	local function consider(container: Instance)
		if not container:IsA("Model") then
			return
		end
		local look = container:FindFirstChild(LOOK_NAME)
		if look == nil or not look:IsA("Model") or entries[look] ~= nil then
			return
		end
		local entry = newEntry(container, look)
		if entry ~= nil then
			entries[look] = entry
			log.debug("dino animated", { name = container.Name })
		end
	end

	local function search()
		for _, child in workspace:GetChildren() do
			consider(child)
		end
		local bots = workspace:FindFirstChild(BOTS_FOLDER)
		if bots ~= nil then
			for _, bot in bots:GetChildren() do
				consider(bot)
			end
		end
	end

	local sinceSearch = AnimationConfig.searchInterval
	-- PreSimulation comes after the animation update of the characters (which sets every joint of
	-- the character back to straight) and before the physics apply the joints, so the angles stay.
	RunService.PreSimulation:Connect(function(dt: number)
		sinceSearch += dt
		if sinceSearch >= AnimationConfig.searchInterval then
			sinceSearch = 0
			search()
		end
		local camera = workspace.CurrentCamera
		if camera == nil then
			return
		end
		local cameraPosition = camera.CFrame.Position
		local now = os.clock()
		for look, entry in entries do
			if look.Parent == nil or entry.root.Parent == nil then
				entries[look] = nil
				continue
			end
			local distance = (entry.root.Position - cameraPosition).Magnitude
			if distance > AnimationConfig.maxDistance then
				if entry.posed then
					straighten(entry)
				end
				entry.lastPosition = entry.root.Position
				entry.lastTime = now
			elseif
				distance <= AnimationConfig.nearDistance or now - entry.lastTime >= AnimationConfig.updateInterval
			then
				local ok, err = pcall(update, entry, now)
				if not ok then
					log.error("animation failed", { name = entry.container.Name, error = tostring(err) })
					entries[look] = nil
				end
			end
		end
	end)
	log.info("started")
end

return DinoAnimator
