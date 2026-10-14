--!strict
-- A short hint at the start of a round: "Eat the food to grow!". It goes away after a few seconds
-- or as soon as the first piece was eaten (the size went up). Reads the player attributes `Mode`
-- and `Points`. Display only. Only checkable in Roblox Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Strings = require(Shared:WaitForChild("Strings"))
local EffectConfig = require(Shared:WaitForChild("Config"):WaitForChild("FoodEffects"))

local UiKit = require(script.Parent:WaitForChild("UiKit"))
local UiTheme = require(script.Parent:WaitForChild("UiTheme"))

-- Base sizes in pixels.
local WIDTH = 340
local HEIGHT = 40
local TOP = 56
-- Seconds between two checks.
local CHECK_SECONDS = 0.25

local EatHint = {}

function EatHint.start()
	local player = Players.LocalPlayer
	local gui = UiKit.newGui("EatHint")
	UiKit.showOnlyInMode(gui, "playing")

	local label = UiKit.newLabel(gui, UiTheme.titleSize)
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Position = UDim2.new(0.5, 0, 0, TOP)
	label.Size = UDim2.fromOffset(WIDTH, HEIGHT)
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.Text = Strings.hints.eatToGrow
	label.Visible = false
	UiKit.addScale(label)

	local startedAt = 0
	local startPoints = 0
	local active = false

	local function begin()
		local points = player:GetAttribute("Points")
		startPoints = if typeof(points) == "number" then points else 0
		startedAt = os.clock()
		active = player:GetAttribute("Mode") == "playing"
		label.Visible = active
	end
	player:GetAttributeChangedSignal("Mode"):Connect(begin)
	begin()

	task.spawn(function()
		while true do
			task.wait(CHECK_SECONDS)
			if active then
				local points = player:GetAttribute("Points")
				local ate = typeof(points) == "number" and points > startPoints
				if ate or os.clock() - startedAt >= EffectConfig.hintSeconds then
					active = false
					label.Visible = false
				end
			end
			-- Not behind the death window.
			local until_ = player:GetAttribute("DeathUntil")
			local dead = typeof(until_) == "number" and until_ > workspace:GetServerTimeNow()
			label.Visible = active and not dead
		end
	end)
end

return EatHint
