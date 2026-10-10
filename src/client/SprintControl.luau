--!strict
-- Sprint button (hold) and stamina bar. Sends only the intention "sprint held or not";
-- the server decides about stamina and speed. The sizes follow the screen size.
-- Only checkable in Roblox Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local Strings = require(Shared:WaitForChild("Strings"))

local UiKit = require(script.Parent:WaitForChild("UiKit"))
local UiMetrics = require(script.Parent:WaitForChild("UiMetrics"))
local UiTheme = require(script.Parent:WaitForChild("UiTheme"))

-- Distance of the button to the bottom and right screen edge. The touch jump button that used
-- to sit here is hidden (see CoreGuiSetup), since jumping is off in this game.
local BUTTON_MARGIN = 24
local BAR_WIDTH = 0.3
local BAR_HEIGHT = 14
local BAR_BOTTOM_MARGIN = 16

local SprintControl = {}

local function isPointerInput(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

function SprintControl.start()
	local player = Players.LocalPlayer
	local sprintRemote = Remotes.event(Remotes.names.sprint)

	local sent = false
	local buttonHeld = false
	local keyHeld = false

	local function update()
		local wanted = buttonHeld or keyHeld
		if wanted == sent then
			return
		end
		sent = wanted
		sprintRemote:FireServer(wanted)
	end

	local gui = UiKit.newGui("SprintControl")

	local button = Instance.new("TextButton")
	button.Name = "SprintButton"
	button.AnchorPoint = Vector2.new(1, 1)
	button.Text = Strings.sprint.button
	button.FontFace = UiTheme.font
	button.TextSize = UiTheme.titleSize
	button.AutoButtonColor = true
	button.BackgroundColor3 = UiTheme.accent
	button.TextColor3 = UiTheme.text
	button.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = button

	local bar = Instance.new("Frame")
	bar.Name = "StaminaBar"
	bar.AnchorPoint = Vector2.new(0.5, 1)
	bar.BackgroundColor3 = UiTheme.panel
	bar.BackgroundTransparency = UiTheme.panelTransparency
	bar.BorderSizePixel = 0
	bar.Parent = gui
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = UiTheme.accent
	fill.BorderSizePixel = 0
	fill.Parent = bar

	UiMetrics.watch(function()
		local scale = UiMetrics.scale()
		local size = UiMetrics.buttonSize()
		button.Size = UDim2.fromOffset(size, size)
		button.Position = UDim2.new(1, -BUTTON_MARGIN * scale, 1, -BUTTON_MARGIN * scale)
		bar.Size = UDim2.new(BAR_WIDTH, 0, 0, math.floor(BAR_HEIGHT * scale))
		bar.Position = UDim2.new(0.5, 0, 1, -BAR_BOTTOM_MARGIN * scale)
	end)

	local function showStamina()
		local value = player:GetAttribute("Stamina")
		local fraction = if typeof(value) == "number" then math.clamp(value, 0, 1) else 1
		fill.Size = UDim2.fromScale(fraction, 1)
	end
	player:GetAttributeChangedSignal("Stamina"):Connect(showStamina)
	showStamina()

	button.InputBegan:Connect(function(input: InputObject)
		if isPointerInput(input) then
			buttonHeld = true
			update()
		end
	end)
	-- Listen globally so a release outside the button also ends the sprint.
	UserInputService.InputEnded:Connect(function(input: InputObject)
		if isPointerInput(input) and buttonHeld then
			buttonHeld = false
			update()
		elseif input.KeyCode == Enum.KeyCode.LeftShift then
			keyHeld = false
			update()
		end
	end)
	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if not processed and input.KeyCode == Enum.KeyCode.LeftShift then
			keyHeld = true
			update()
		end
	end)
end

return SprintControl
