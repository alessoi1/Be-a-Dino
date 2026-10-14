--!strict
-- The eating combo: a flame with the count at the top of the screen while the player keeps
-- eating. The number pops bigger with every piece, and more at every milestone. The server
-- publishes `ComboCount` and `ComboUntil` (server time); display only. It gives no bonus.
-- Only checkable in Roblox Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ComboConfig = require(Shared:WaitForChild("Config"):WaitForChild("Combo"))

local UiKit = require(script.Parent:WaitForChild("UiKit"))
local UiTheme = require(script.Parent:WaitForChild("UiTheme"))

-- Base sizes in pixels.
local WIDTH = 150
local HEIGHT = 60
local TEXT_SIZE = 34
-- Vertical position as a share of the screen height (between the top panels and the messages).
local TOP_SHARE = 0.16
-- How much bigger the label pops on a new piece and on a milestone, and how long that takes.
local POP_SCALE = 1.15
local MILESTONE_POP_SCALE = 1.5
local POP_SECONDS = 0.15

local ComboDisplay = {}

function ComboDisplay.start()
	local player = Players.LocalPlayer
	local gui = UiKit.newGui("ComboDisplay")
	UiKit.showOnlyInMode(gui, "playing")

	local box = Instance.new("Frame")
	box.AnchorPoint = Vector2.new(0.5, 0)
	box.Position = UDim2.fromScale(0.5, TOP_SHARE)
	box.Size = UDim2.fromOffset(WIDTH, HEIGHT)
	box.BackgroundTransparency = 1
	box.Visible = false
	box.Parent = gui
	UiKit.addScale(box)

	local label = UiKit.newLabel(box, TEXT_SIZE)
	label.Size = UDim2.fromScale(1, 1)
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextColor3 = UiTheme.gold
	local popScale = Instance.new("UIScale")
	popScale.Parent = label

	local lastCount = 0
	local function pop(count: number)
		local milestone = count % ComboConfig.milestoneEvery == 0
		popScale.Scale = if milestone then MILESTONE_POP_SCALE else POP_SCALE
		TweenService:Create(popScale, TweenInfo.new(POP_SECONDS), { Scale = 1 }):Play()
	end

	RunService.RenderStepped:Connect(function()
		local count = player:GetAttribute("ComboCount")
		local until_ = player:GetAttribute("ComboUntil")
		local active = typeof(count) == "number"
			and typeof(until_) == "number"
			and count >= ComboConfig.minShown
			and until_ > workspace:GetServerTimeNow()
		box.Visible = active
		if not active then
			lastCount = 0
			return
		end
		if count ~= lastCount then
			lastCount = count
			label.Text = UiKit.withIcon("combo", "x" .. tostring(count))
			pop(count)
		end
	end)
end

return ComboDisplay
