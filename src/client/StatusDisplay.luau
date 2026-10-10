--!strict
-- Simple status display at the top: dino name, points and progress to the next
-- dino. Reads the values the server publishes as player attributes (display only).
-- Only checkable in Roblox Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Strings = require(Shared:WaitForChild("Strings"))

local PANEL_WIDTH = 0.5
local PANEL_MAX_WIDTH = 360
local PANEL_TOP = 12
local LABEL_HEIGHT = 28
local BAR_HEIGHT = 12

local StatusDisplay = {}

function StatusDisplay.start()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local gui = Instance.new("ScreenGui")
	gui.Name = "StatusDisplay"
	gui.ResetOnSpawn = false
	gui.Parent = playerGui

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0)
	panel.Position = UDim2.new(0.5, 0, 0, PANEL_TOP)
	panel.Size = UDim2.new(PANEL_WIDTH, 0, 0, LABEL_HEIGHT + BAR_HEIGHT)
	panel.BackgroundTransparency = 1
	panel.Parent = gui
	local constraint = Instance.new("UISizeConstraint")
	constraint.MaxSize = Vector2.new(PANEL_MAX_WIDTH, LABEL_HEIGHT + BAR_HEIGHT)
	constraint.Parent = panel

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, LABEL_HEIGHT)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.5
	label.Parent = panel

	local bar = Instance.new("Frame")
	bar.Position = UDim2.fromOffset(0, LABEL_HEIGHT)
	bar.Size = UDim2.new(1, 0, 0, BAR_HEIGHT)
	bar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	bar.BackgroundTransparency = 0.3
	bar.BorderSizePixel = 0
	bar.Parent = panel
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = Color3.fromRGB(110, 200, 90)
	fill.BorderSizePixel = 0
	fill.Parent = bar

	local function refresh()
		local stage = player:GetAttribute("Stage")
		local points = player:GetAttribute("Points")
		local progress = player:GetAttribute("StageProgress")
		local name = if typeof(stage) == "string" then Strings.dinos[stage] or stage else ""
		local pointsValue = if typeof(points) == "number" then points else 0
		label.Text = string.format("%s · %d %s", name, pointsValue, Strings.status.points)
		fill.Size = UDim2.fromScale(if typeof(progress) == "number" then math.clamp(progress, 0, 1) else 0, 1)
	end

	for _, attribute in { "Stage", "Points", "StageProgress" } do
		player:GetAttributeChangedSignal(attribute):Connect(refresh)
	end
	refresh()
end

return StatusDisplay
