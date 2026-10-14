--!strict
-- The food frenzy banner: a pulsing orange bar at the top of the screen while the frenzy runs,
-- with the factor and the seconds left. The server publishes the state as workspace attributes
-- (display only). Only checkable in Roblox Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Strings = require(Shared:WaitForChild("Strings"))
local FrenzyConfig = require(Shared:WaitForChild("Config"):WaitForChild("Frenzy"))

local UiKit = require(script.Parent:WaitForChild("UiKit"))
local UiTheme = require(script.Parent:WaitForChild("UiTheme"))

-- Base sizes in pixels.
local WIDTH = 300
local HEIGHT = 56
-- Distance to the top edge of the screen (base pixels; the combo sits below it).
local TOP_OFFSET = 8
-- The banner breathes: size change in percent and cycles per second.
local PULSE_AMOUNT = 0.04
local PULSE_SPEED = 3

local FrenzyBanner = {}

function FrenzyBanner.start()
	local player = Players.LocalPlayer
	local gui = UiKit.newGui("FrenzyBanner")
	UiKit.showOnlyInMode(gui, "playing")

	local box = UiKit.newPanel(gui)
	box.AnchorPoint = Vector2.new(0.5, 0)
	box.Position = UDim2.new(0.5, 0, 0, TOP_OFFSET)
	box.Size = UDim2.fromOffset(WIDTH, HEIGHT)
	box.BackgroundColor3 = UiTheme.accent
	box.BackgroundTransparency = 0.1
	box.Visible = false
	UiKit.addScale(box)
	local edge = box:FindFirstChildOfClass("UIStroke")
	if edge ~= nil then
		edge.Color = UiTheme.gold
		edge.Transparency = 0
	end

	local label = UiKit.newLabel(box, UiTheme.titleSize)
	label.Size = UDim2.fromScale(1, 1)
	label.TextXAlignment = Enum.TextXAlignment.Center
	local pulse = Instance.new("UIScale")
	pulse.Parent = label

	RunService.RenderStepped:Connect(function()
		local active = workspace:GetAttribute("FrenzyActive") == true and player:GetAttribute("Mode") == "playing"
		box.Visible = active
		if not active then
			return
		end
		local endsAt = workspace:GetAttribute("FrenzyEndsAt")
		local left = if typeof(endsAt) == "number" then math.max(0, endsAt - workspace:GetServerTimeNow()) else 0
		label.Text = string.format(
			"%s %s x%d  %s",
			UiKit.glyph("food"),
			Strings.frenzy.title,
			FrenzyConfig.pointsFactor,
			UiKit.withIcon("timer", tostring(math.ceil(left)))
		)
		pulse.Scale = 1 + math.sin(os.clock() * PULSE_SPEED) * PULSE_AMOUNT
	end)
end

return FrenzyBanner
