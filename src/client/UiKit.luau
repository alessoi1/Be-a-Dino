--!strict
-- Small helpers to build interface parts the same way everywhere.
-- Only checkable in Roblox Studio.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Icons = require(Shared:WaitForChild("Config"):WaitForChild("Icons"))
local Log = require(Shared:WaitForChild("Log"))

local UiMetrics = require(script.Parent:WaitForChild("UiMetrics"))
local UiTheme = require(script.Parent:WaitForChild("UiTheme"))

local log = Log.new("UiKit")

-- The close button of a window (base pixels).
local CLOSE_SIZE = 32
local CLOSE_MARGIN = 8

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

-- An icon from Config/Icons: the image when there is one, otherwise its symbol character. Both
-- have no background, are tinted with the color of the icon and fill `size` (given by the caller).
function UiKit.newIcon(parent: Instance, name: string, size: UDim2): GuiObject
	local icon = (Icons :: { [string]: Icons.Icon })[name]
	if icon == nil then
		log.warn("unknown icon", { name = name })
		icon = { assetId = 0, glyph = "?", color = { r = 255, g = 255, b = 255 } }
	end
	local tint = Color3.fromRGB(icon.color.r, icon.color.g, icon.color.b)
	local view: GuiObject
	if icon.assetId ~= 0 then
		local image = Instance.new("ImageLabel")
		image.Image = "rbxassetid://" .. tostring(icon.assetId)
		image.ImageColor3 = tint
		image.ScaleType = Enum.ScaleType.Fit
		view = image
	else
		local text = Instance.new("TextLabel")
		text.Text = icon.glyph
		text.TextColor3 = tint
		text.TextScaled = true
		text.FontFace = UiTheme.font
		view = text
	end
	view.Name = "Icon_" .. name
	view.BackgroundTransparency = 1
	view.Size = size
	view.Parent = parent
	return view
end

-- A small "X" button in the top right corner of a window; `onClose` runs when it is tapped.
function UiKit.addCloseButton(window: GuiObject, onClose: () -> ()): TextButton
	local button = Instance.new("TextButton")
	button.Name = "CloseButton"
	button.AnchorPoint = Vector2.new(1, 0)
	button.Position = UDim2.new(1, -CLOSE_MARGIN, 0, CLOSE_MARGIN)
	button.Size = UDim2.fromOffset(CLOSE_SIZE, CLOSE_SIZE)
	button.Text = "X"
	button.FontFace = UiTheme.font
	button.TextSize = UiTheme.bodySize
	button.TextColor3 = UiTheme.text
	button.BackgroundColor3 = UiTheme.panel
	button.BackgroundTransparency = UiTheme.panelTransparency
	button.BorderSizePixel = 0
	button.AutoButtonColor = true
	button.Parent = window
	local corner = Instance.new("UICorner")
	corner.Parent = button
	button.Activated:Connect(onClose)
	return button
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
