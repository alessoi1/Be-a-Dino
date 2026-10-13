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
-- Share of the button the icon fills.
local ICON_SHARE = 0.5
-- Share of the button height the word under the icon takes.
local CAPTION_SHARE = 0.26
-- The stamina icon left of the bar: size and gap to the bar (base pixels).
local BAR_ICON_SIZE = 22
local BAR_ICON_GAP = 6

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
	UiKit.showOnlyInMode(gui, "playing")

	local button = Instance.new("TextButton")
	button.Name = "SprintButton"
	button.AnchorPoint = Vector2.new(1, 1)
	button.Text = ""
	button.Parent = gui
	UiKit.styleBubble(button, UiTheme.sprintButton)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.3, 0)
	corner.Parent = button

	local sprintIcon = UiKit.newIcon(button, "sprint", UDim2.fromScale(ICON_SHARE, ICON_SHARE))
	sprintIcon.AnchorPoint = Vector2.new(0.5, 0)
	sprintIcon.Position = UDim2.fromScale(0.5, 0.1)
	-- The word under the icon says what the button does.
	local caption = UiKit.newCaption(button, Strings.sprint.button, UDim2.fromScale(0.8, CAPTION_SHARE))
	caption.AnchorPoint = Vector2.new(0.5, 1)
	caption.Position = UDim2.fromScale(0.5, 0.94)
	-- Taps go to the button, not to the icon.
	sprintIcon.Active = false

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

	-- The stamina icon sits left of the bar.
	local staminaIcon = UiKit.newIcon(gui, "stamina", UDim2.fromOffset(BAR_ICON_SIZE, BAR_ICON_SIZE))
	staminaIcon.AnchorPoint = Vector2.new(1, 1)

	UiMetrics.watch(function()
		local scale = UiMetrics.scale()
		local size = UiMetrics.buttonSize()
		local barHeight = math.floor(BAR_HEIGHT * scale)
		staminaIcon.Size = UDim2.fromOffset(math.floor(BAR_ICON_SIZE * scale), math.floor(BAR_ICON_SIZE * scale))
		staminaIcon.Position =
			UDim2.new(0.5 - BAR_WIDTH / 2, -BAR_ICON_GAP * scale, 1, -(BAR_BOTTOM_MARGIN - 1) * scale)
		staminaIcon.Visible = barHeight > 0
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
