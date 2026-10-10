--!strict
-- Status display at the top left: dino name, points, size, the way to the next dino and a
-- progress bar. Reads the values the server publishes as player attributes (display only).
-- Only checkable in Roblox Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Strings = require(Shared:WaitForChild("Strings"))

local UiKit = require(script.Parent:WaitForChild("UiKit"))
local UiTheme = require(script.Parent:WaitForChild("UiTheme"))

local PANEL_WIDTH = 210
local PADDING = 8
local TITLE_HEIGHT = 24
local DETAIL_HEIGHT = 22
local BAR_HEIGHT = 10
local BAR_GAP = 4

local StatusDisplay = {}

local function formatScale(scale: number): string
	local text = string.format("%.1f", scale)
	local withComma = string.gsub(text, "%.", ",")
	return withComma
end

function StatusDisplay.start()
	local player = Players.LocalPlayer
	local gui = UiKit.newGui("StatusDisplay")

	local panel = UiKit.newPanel(gui)
	panel.Position = UDim2.fromOffset(UiTheme.margin, UiTheme.margin)
	-- The height is shared with the menu button below it (see UiTheme.statusPanelHeight).
	panel.Size = UDim2.fromOffset(PANEL_WIDTH, UiTheme.statusPanelHeight)
	UiKit.addScale(panel)

	local title = UiKit.newLabel(panel, UiTheme.titleSize)
	title.Position = UDim2.fromOffset(PADDING, PADDING)
	title.Size = UDim2.new(1, -PADDING * 2, 0, TITLE_HEIGHT)

	local detail = UiKit.newLabel(panel, UiTheme.bodySize)
	detail.Position = UDim2.fromOffset(PADDING, PADDING + TITLE_HEIGHT)
	detail.Size = UDim2.new(1, -PADDING * 2, 0, DETAIL_HEIGHT)

	local bar = Instance.new("Frame")
	bar.Position = UDim2.fromOffset(PADDING, PADDING + TITLE_HEIGHT + DETAIL_HEIGHT + BAR_GAP)
	bar.Size = UDim2.new(1, -PADDING * 2, 0, BAR_HEIGHT)
	bar.BackgroundColor3 = UiTheme.panel
	bar.BorderSizePixel = 0
	bar.Parent = panel
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = UiTheme.good
	fill.BorderSizePixel = 0
	fill.Parent = bar

	local function refresh()
		local stage = player:GetAttribute("Stage")
		local points = player:GetAttribute("Points")
		local progress = player:GetAttribute("StageProgress")
		local scale = player:GetAttribute("Scale")
		local nextStage = player:GetAttribute("NextStage")
		local missing = player:GetAttribute("PointsToNext")

		local name = if typeof(stage) == "string" then Strings.dinos[stage] or stage else ""
		local pointsValue = if typeof(points) == "number" then points else 0
		title.Text = string.format("%s · %d %s", name, pointsValue, Strings.status.points)

		local sizeText = if typeof(scale) == "number"
			then string.format(Strings.status.size, formatScale(scale))
			else ""
		local wayText: string
		if typeof(nextStage) == "string" and nextStage ~= "" and typeof(missing) == "number" then
			wayText = string.format(Strings.status.toNext, missing, Strings.dinos[nextStage] or nextStage)
		else
			wayText = Strings.status.maxStage
		end
		detail.Text = wayText .. " · " .. sizeText

		fill.Size = UDim2.fromScale(if typeof(progress) == "number" then math.clamp(progress, 0, 1) else 0, 1)
	end

	for _, attribute in { "Stage", "Points", "StageProgress", "Scale", "NextStage", "PointsToNext" } do
		player:GetAttributeChangedSignal(attribute):Connect(refresh)
	end
	refresh()
end

return StatusDisplay
