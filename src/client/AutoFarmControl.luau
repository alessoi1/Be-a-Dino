--!strict
-- The autofarm button above the sprint button (and the F key). The server decides whether the
-- autofarm is on and publishes it as the player attribute `AutoFarm`; while it is on, this module
-- walks the dino to the best food and away from bigger players (the choice is AutoFarm.pickTarget).
-- Moving by hand takes over and asks the server to switch it off. The walking belongs to the
-- client, as for every player; the server still checks speed and does the food pickup.
-- Only checkable in Roblox Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AutoFarm = require(Shared:WaitForChild("AutoFarm"))
local Avoidance = require(Shared:WaitForChild("Avoidance"))
local Log = require(Shared:WaitForChild("Log"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Strings = require(Shared:WaitForChild("Strings"))
local Arena = require(Shared:WaitForChild("Config"):WaitForChild("Arena"))
local AutoFarmConfig = require(Shared:WaitForChild("Config"):WaitForChild("AutoFarm"))
local CollisionConfig = require(Shared:WaitForChild("Config"):WaitForChild("Collision"))

local UiKit = require(script.Parent:WaitForChild("UiKit"))
local UiMetrics = require(script.Parent:WaitForChild("UiMetrics"))
local UiTheme = require(script.Parent:WaitForChild("UiTheme"))

-- Same distance to the right and bottom edge as the sprint button, and a gap above it (base pixels).
local BUTTON_MARGIN = 24
local BUTTON_GAP = 12
-- Name of the folder with the invisible collision shapes the server builds in the arena.
local COLLIDER_FOLDER_NAME = "Colliders"
-- Seconds to wait for the Roblox controls module.
local CONTROLS_WAIT = 10

local log = Log.new("AutoFarmControl")

local AutoFarmControl = {}

function AutoFarmControl.start()
	local player = Players.LocalPlayer
	local remote = Remotes.event(Remotes.names.autoFarm)
	local gui = UiKit.newGui("AutoFarmControl")
	UiKit.showOnlyInMode(gui, "playing")

	local button = Instance.new("TextButton")
	button.Name = "AutoFarmButton"
	button.AnchorPoint = Vector2.new(1, 1)
	button.FontFace = UiTheme.font
	button.TextSize = UiTheme.bodySize
	button.TextColor3 = UiTheme.text
	button.TextWrapped = true
	button.BackgroundTransparency = UiTheme.panelTransparency
	button.AutoButtonColor = true
	button.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = button

	UiMetrics.watch(function()
		local scale = UiMetrics.scale()
		local size = UiMetrics.smallButtonSize()
		button.Size = UDim2.fromOffset(size, size)
		button.Position =
			UDim2.new(1, -BUTTON_MARGIN * scale, 1, -(BUTTON_MARGIN + BUTTON_GAP) * scale - UiMetrics.buttonSize())
	end)

	local function isOn(): boolean
		return player:GetAttribute("AutoFarm") == true
	end

	-- A manual input already asked the server to stop; do not ask again until it is off.
	local stopAsked = false

	local function refreshButton()
		local on = isOn()
		button.Text = if on then Strings.autofarm.on else Strings.autofarm.off
		button.BackgroundColor3 = if on then UiTheme.good else UiTheme.panel
		button.BackgroundTransparency = if on then 0 else UiTheme.panelTransparency
		if not on then
			stopAsked = false
		end
	end
	player:GetAttributeChangedSignal("AutoFarm"):Connect(refreshButton)
	refreshButton()

	local function toggle()
		remote:FireServer(not isOn())
	end
	button.Activated:Connect(toggle)
	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if not processed and input.KeyCode == Enum.KeyCode.F and player:GetAttribute("Mode") == "playing" then
			toggle()
		end
	end)

	-- The Roblox controls tell what the player is steering by hand (keys or the touch stick).
	local controls: any = nil
	task.spawn(function()
		local ok, result = pcall(function()
			local module = player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule", CONTROLS_WAIT)
			return require(module :: ModuleScript):GetControls()
		end)
		if ok and result ~= nil then
			controls = result
		else
			log.warn("controls not found, only the button and the F key switch the autofarm off", {
				error = tostring(result),
			})
		end
	end)

	-- The solid props as discs, read from the collision shapes once they exist (they never move).
	local obstacles: { Avoidance.Disc } = {}
	local obstaclesLoaded = false
	local function loadObstacles()
		local folder = workspace:FindFirstChild(COLLIDER_FOLDER_NAME, true)
		if folder == nil then
			return
		end
		for _, part in folder:GetChildren() do
			local radius = part:GetAttribute("Radius")
			if part:IsA("BasePart") and typeof(radius) == "number" then
				table.insert(obstacles, { x = part.Position.X, z = part.Position.Z, r = radius })
			end
		end
		obstaclesLoaded = true
		log.info("obstacles read", { count = #obstacles })
	end

	-- Reads food and players and walks to the chosen target.
	local function step()
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if character == nil or humanoid == nil or root == nil or not root:IsA("BasePart") or humanoid.Health <= 0 then
			return
		end

		local me: AutoFarm.Me = { x = root.Position.X, z = root.Position.Z, scale = character:GetScale() }

		local foods: { AutoFarm.Food } = {}
		local folder = workspace:FindFirstChild("Food")
		if folder ~= nil then
			for _, part in folder:GetChildren() do
				if part:IsA("BasePart") then
					local value = part:GetAttribute("Value")
					table.insert(foods, {
						x = part.Position.X,
						z = part.Position.Z,
						value = if typeof(value) == "number" then value else 1,
					})
				end
			end
		end

		local others: { AutoFarm.Other } = {}
		for _, other in Players:GetPlayers() do
			if other ~= player and other:GetAttribute("Mode") == "playing" then
				local otherRoot = other.Character and other.Character:FindFirstChild("HumanoidRootPart")
				local scale = other:GetAttribute("Scale")
				if otherRoot ~= nil and otherRoot:IsA("BasePart") then
					table.insert(others, {
						x = otherRoot.Position.X,
						z = otherRoot.Position.Z,
						scale = if typeof(scale) == "number" then scale else 1,
					})
				end
			end
		end

		if not obstaclesLoaded then
			loadObstacles()
		end

		local target = AutoFarm.pickTarget(AutoFarmConfig, Arena, me, foods, others, Arena.size)
		if target.kind == "idle" then
			humanoid:MoveTo(root.Position)
		else
			-- Walk around trees and rocks on the way.
			local waypoint = Avoidance.steer(
				{ x = me.x, z = me.z },
				{ x = target.x, z = target.z },
				obstacles,
				me.scale * CollisionConfig.bodyRadiusPerScale + CollisionConfig.margin,
				CollisionConfig.lookAhead,
				CollisionConfig.maxDetours
			)
			humanoid:MoveTo(Vector3.new(waypoint.x, root.Position.Y, waypoint.z))
		end
	end

	local sinceStep = 0
	RunService.Heartbeat:Connect(function(dt: number)
		if not isOn() then
			return
		end
		if controls ~= nil then
			local ok, vector = pcall(function()
				return controls:GetMoveVector()
			end)
			if ok and typeof(vector) == "Vector3" and vector.Magnitude > AutoFarmConfig.manualInputThreshold then
				-- The player steers: take over and switch the autofarm off.
				if not stopAsked then
					stopAsked = true
					remote:FireServer(false)
				end
				return
			end
		end
		sinceStep += dt
		if sinceStep < AutoFarmConfig.tickSeconds then
			return
		end
		sinceStep = 0
		local ok, err = pcall(step)
		if not ok then
			log.error("autofarm step failed", { error = tostring(err) })
		end
	end)
end

return AutoFarmControl
