--!strict
-- Small helpers to build interface parts the same way everywhere.
-- Only checkable in Roblox Studio.

local Players = game:GetService("Players")

local UiMetrics = require(script.Parent:WaitForChild("UiMetrics"))
local UiTheme = require(script.Parent:WaitForChild("UiTheme"))

local UiKit = {}

-- A ScreenGui that stays after respawn. It keeps the default insets, so it stays out of
-- the Roblox top bar and the device cutouts (notch, gesture bar).
function UiKit.newGui(name: string): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.ResetOnSpawn = false
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	return gui
end

-- Scales `target` and everything in it with the screen size.
function UiKit.addScale(target: GuiObject): UIScale
	local uiScale = Instance.new("UIScale")
	uiScale.Parent = target
	UiMetrics.watch(function()
		uiScale.Scale = UiMetrics.scale()
	end)
	return uiScale
end

-- Shows the ScreenGui only while the player is in the given mode ("lobby" or "playing"). The
-- server publishes the mode as a player attribute.
function UiKit.showOnlyInMode(gui: ScreenGui, mode: string)
	local player = Players.LocalPlayer
	local function apply()
		gui.Enabled = player:GetAttribute("Mode") == mode
	end
	player:GetAttributeChangedSignal("Mode"):Connect(apply)
	apply()
end

function UiKit.newLabel(parent: Instance, textSize: number): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.FontFace = UiTheme.font
	label.TextSize = textSize
	label.TextColor3 = UiTheme.text
	label.TextStrokeTransparency = 0.6
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Parent = parent
	return label
end

-- A semi-transparent rounded panel.
function UiKit.newPanel(parent: Instance): Frame
	local panel = Instance.new("Frame")
	panel.BackgroundColor3 = UiTheme.panel
	panel.BackgroundTransparency = UiTheme.panelTransparency
	panel.BorderSizePixel = 0
	panel.Parent = parent
	local corner = Instance.new("UICorner")
	corner.Parent = panel
	return panel
end

return UiKit
