--!strict
-- Sprint button (hold) and stamina bar. Sends only the intention "sprint held or not";
-- the server decides about stamina and speed. Only checkable in Roblox Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local Strings = require(Shared:WaitForChild("Strings"))

local BUTTON_SIZE = 96
local BUTTON_MARGIN = 24
-- Lifts the button above the default mobile jump button area.
local BUTTON_LIFT = 140
local BAR_HEIGHT = 14
local BAR_BOTTOM_MARGIN = 16

local SprintControl = {}

local function isPointerInput(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

function SprintControl.start()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
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

	local gui = Instance.new("ScreenGui")
	gui.Name = "SprintControl"
	gui.ResetOnSpawn = false
	gui.Parent = playerGui

	local button = Instance.new("TextButton")
	button.Name = "SprintButton"
	button.AnchorPoint = Vector2.new(1, 1)
	button.Position = UDim2.new(1, -BUTTON_MARGIN, 1, -BUTTON_LIFT)
	button.Size = UDim2.fromOffset(BUTTON_SIZE, BUTTON_SIZE)
	button.Text = Strings.sprint.button
	button.TextScaled = true
	button.AutoButtonColor = true
	button.BackgroundColor3 = Color3.fromRGB(255, 170, 40)
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = button

	local bar = Instance.new("Frame")
	bar.Name = "StaminaBar"
	bar.AnchorPoint = Vector2.new(0.5, 1)
	bar.Position = UDim2.new(0.5, 0, 1, -BAR_BOTTOM_MARGIN)
	bar.Size = UDim2.new(0.4, 0, 0, BAR_HEIGHT)
	bar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	bar.BackgroundTransparency = 0.3
	bar.BorderSizePixel = 0
	bar.Parent = gui
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(255, 170, 40)
	fill.BorderSizePixel = 0
	fill.Parent = bar

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
