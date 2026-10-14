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

-- Transparency of the dark outline around text (0 = fully dark).
local TEXT_STROKE = 0.35
-- Corner and edge of a panel, and the outline of a bright button (base pixels).
local PANEL_CORNER = 10
local PANEL_EDGE = 2
local BUTTON_OUTLINE = 3
-- The close button of a window (base pixels).
local CLOSE_SIZE = 32
local CLOSE_MARGIN = 8

local UiKit = {}

-- A ScreenGui that stays after respawn. It keeps the default insets (unless `ignoreInset`), so it
-- stays out of the Roblox top bar and the device cutouts (notch, gesture bar).
function UiKit.newGui(name: string, ignoreInset: boolean?): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.ResetOnSpawn = false
	-- True: the gui starts at the very edge of the screen (also under the Roblox top bar).
	gui.IgnoreGuiInset = ignoreInset == true
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
	label.TextStrokeTransparency = TEXT_STROKE
	label.TextStrokeColor3 = UiTheme.outline
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

-- The symbol character of an icon, for texts that mix a symbol with a number or word.
function UiKit.glyph(name: string): string
	local icon = (Icons :: { [string]: Icons.Icon })[name]
	if icon == nil then
		log.warn("unknown icon", { name = name })
		return "?"
	end
	return icon.glyph
end

-- A text with the symbol of an icon in front of it.
function UiKit.withIcon(name: string, text: string): string
	return UiKit.glyph(name) .. " " .. text
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
	corner.CornerRadius = UDim.new(0, PANEL_CORNER)
	corner.Parent = panel
	local edge = Instance.new("UIStroke")
	edge.Color = UiTheme.panelEdge
	edge.Transparency = UiTheme.panelEdgeTransparency
	edge.Thickness = PANEL_EDGE
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.Parent = panel
	UiKit.addGloss(panel)
	return panel
end

-- A soft light-to-dark gradient from top to bottom; it gives flat fills some depth.
function UiKit.addGloss(target: GuiObject): UIGradient
	local gradient = Instance.new("UIGradient")
	gradient.Name = "Gloss"
	gradient.Color = ColorSequence.new(UiTheme.glossTop, UiTheme.glossBottom)
	gradient.Rotation = 90
	gradient.Parent = target
	return gradient
end

-- A progress bar: a dark rounded track with a colored fill. Returns the track and the fill; the
-- caller sets the size of the track and `fill.Size = UDim2.fromScale(share, 1)`.
function UiKit.newBar(parent: Instance, color: Color3): (Frame, Frame)
	local track = Instance.new("Frame")
	track.BackgroundColor3 = UiTheme.barBack
	track.BackgroundTransparency = 0.2
	track.BorderSizePixel = 0
	track.Parent = parent
	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(0.5, 0)
	trackCorner.Parent = track
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = color
	fill.BorderSizePixel = 0
	fill.Parent = track
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0.5, 0)
	fillCorner.Parent = fill
	UiKit.addGloss(fill)
	return track, fill
end

-- Makes a button a bright "bubble": solid fill, thick dark outline, white text with a dark outline.
function UiKit.styleBubble(button: GuiButton, fill: Color3)
	button.BackgroundColor3 = fill
	button.BackgroundTransparency = 0
	button.AutoButtonColor = true
	button.BorderSizePixel = 0
	local outline = button:FindFirstChildOfClass("UIStroke")
	if outline == nil then
		outline = Instance.new("UIStroke")
		outline.Parent = button
	end
	outline.Color = UiTheme.outline
	outline.Thickness = BUTTON_OUTLINE
	outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	if button:FindFirstChild("Gloss") == nil then
		UiKit.addGloss(button)
	end
end

-- A short word under an icon of a button (fills `size`, shrinks to fit, white with a dark outline).
function UiKit.newCaption(parent: Instance, text: string, size: UDim2): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = "Caption"
	label.BackgroundTransparency = 1
	label.FontFace = UiTheme.font
	label.TextScaled = true
	label.TextColor3 = UiTheme.text
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = UiTheme.outline
	label.Text = text
	label.Size = size
	label.Active = false
	label.Parent = parent
	return label
end

return UiKit
