--!strict
-- The window after being eaten: who ate you and three big picture buttons: revive at your size
-- and put a bounty on the killer (both paid with Robux) and back to lobby (free). A saved revive
-- or bounty is used with a tap; otherwise the tap opens the purchase dialog, and the server uses
-- the item as soon as the purchase arrives. The server decides; this only sends the intention.
-- Reads the attributes the server publishes (display only). The screen is dimmed red behind the
-- window, which pops in; every choice is a large icon with one word, so it can be read by looking.
-- Only checkable in Roblox Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local Strings = require(Shared:WaitForChild("Strings"))
local OfferConfig = require(Shared:WaitForChild("Config"):WaitForChild("Offers"))

local PurchasePrompt = require(script.Parent:WaitForChild("PurchasePrompt"))
local UiKit = require(script.Parent:WaitForChild("UiKit"))
local UiTheme = require(script.Parent:WaitForChild("UiTheme"))

-- Base sizes in pixels.
local WIDTH = 380
local PADDING = 14
local FACE_HEIGHT = 84
local FACE_SIZE = 72
local BYLINE_HEIGHT = 28
local TILE_HEIGHT = 150
local TILE_GAP = 10
local TILE_COUNT = 3
local TILE_ICON = 64
local TILE_ICON_TOP = 12
local WORD_HEIGHT = 26
local SUB_HEIGHT = 28
local SUB_SIZE = 20
local CLOSING_HEIGHT = 28
local EDGE_THICKNESS = 3
-- The window sits at the bottom of the screen (the camera shows the arena from above in the rest);
-- distance to the bottom edge (above the stamina bar), and how far the window pops up (pixels).
local BOTTOM_MARGIN = 44
local POP_OFFSET = 40
local POP_SECONDS = 0.3
-- Transparency of the dim layer once it has faded in, and the seconds it takes.
local DIM_TRANSPARENCY = 0.7
local DIM_SECONDS = 0.4

local DeathScreen = {}

type Choice = { button: TextButton, word: TextLabel, sub: TextLabel }

-- One choice: a bubble tile with a big icon, one word below it and a small line at the bottom.
local function newChoice(parent: Instance, index: number, iconName: string): Choice
	local tileWidth = (WIDTH - PADDING * 2 - TILE_GAP * (TILE_COUNT - 1)) / TILE_COUNT
	local button = Instance.new("TextButton")
	button.Position = UDim2.fromOffset(
		PADDING + (index - 1) * (tileWidth + TILE_GAP),
		PADDING + FACE_HEIGHT + BYLINE_HEIGHT + PADDING
	)
	button.Size = UDim2.fromOffset(tileWidth, TILE_HEIGHT)
	button.Text = ""
	button.Parent = parent
	UiKit.styleBubble(button, UiTheme.accent)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.18, 0)
	corner.Parent = button

	local icon = UiKit.newIcon(button, iconName, UDim2.fromOffset(TILE_ICON, TILE_ICON))
	icon.AnchorPoint = Vector2.new(0.5, 0)
	icon.Position = UDim2.new(0.5, 0, 0, TILE_ICON_TOP)
	icon.Active = false

	local word = UiKit.newLabel(button, UiTheme.bodySize)
	word.AnchorPoint = Vector2.new(0.5, 0)
	word.Position = UDim2.new(0.5, 0, 0, TILE_ICON_TOP + TILE_ICON + 4)
	word.Size = UDim2.new(1, -8, 0, WORD_HEIGHT)
	word.TextXAlignment = Enum.TextXAlignment.Center
	word.TextScaled = true
	word.Active = false

	local sub = UiKit.newLabel(button, SUB_SIZE)
	sub.AnchorPoint = Vector2.new(0.5, 1)
	sub.Position = UDim2.new(0.5, 0, 1, -6)
	sub.Size = UDim2.new(1, -8, 0, SUB_HEIGHT)
	sub.TextXAlignment = Enum.TextXAlignment.Center
	sub.Active = false
	return { button = button, word = word, sub = sub }
end

-- A greyed out choice that does nothing (not available now).
local function makeDisabled(choice: Choice)
	choice.button.Active = false
	choice.button.AutoButtonColor = false
	choice.button.BackgroundColor3 = UiTheme.lockedCard
	choice.word.TextColor3 = UiTheme.lockedText
end

local function makeEnabled(choice: Choice, fill: Color3)
	choice.button.Active = true
	choice.button.AutoButtonColor = true
	choice.button.BackgroundColor3 = fill
	choice.word.TextColor3 = UiTheme.text
end

function DeathScreen.start()
	local player = Players.LocalPlayer
	local remote = Remotes.event(Remotes.names.deathChoice)
	local gui = UiKit.newGui("DeathScreen", true)

	-- Dim layer over the whole screen; it also keeps taps from reaching the game behind it.
	local dim = Instance.new("Frame")
	dim.Size = UDim2.fromScale(1, 1)
	dim.BackgroundColor3 = UiTheme.dim
	dim.BackgroundTransparency = 1
	dim.BorderSizePixel = 0
	dim.Active = true
	dim.Visible = false
	dim.Parent = gui

	local height = PADDING + FACE_HEIGHT + BYLINE_HEIGHT + PADDING + TILE_HEIGHT + PADDING + CLOSING_HEIGHT + PADDING

	local panel = UiKit.newPanel(gui)
	panel.AnchorPoint = Vector2.new(0.5, 1)
	panel.Position = UDim2.new(0.5, 0, 1, -BOTTOM_MARGIN)
	panel.Size = UDim2.fromOffset(WIDTH, height)
	panel.Visible = false
	UiKit.addScale(panel)
	local edge = panel:FindFirstChildOfClass("UIStroke")
	if edge ~= nil then
		edge.Color = UiTheme.danger
		edge.Transparency = 0
		edge.Thickness = EDGE_THICKNESS
	end

	-- A dizzy face instead of a headline.
	local face = UiKit.newLabel(panel, FACE_SIZE)
	face.Text = UiKit.glyph("eaten")
	face.TextXAlignment = Enum.TextXAlignment.Center
	face.Position = UDim2.fromOffset(PADDING, PADDING)
	face.Size = UDim2.new(1, -PADDING * 2, 0, FACE_HEIGHT)

	local byline = UiKit.newLabel(panel, UiTheme.titleSize)
	byline.TextColor3 = UiTheme.danger
	byline.TextXAlignment = Enum.TextXAlignment.Center
	byline.Position = UDim2.fromOffset(PADDING, PADDING + FACE_HEIGHT)
	byline.Size = UDim2.new(1, -PADDING * 2, 0, BYLINE_HEIGHT)

	local revive = newChoice(panel, 1, "revive")
	local bounty = newChoice(panel, 2, "bounty")
	local lobby = newChoice(panel, 3, "lobby")
	revive.word.Text = Strings.death.revive
	lobby.word.Text = Strings.death.lobby
	lobby.sub.Text = ""
	makeEnabled(lobby, UiTheme.lobbyButton)

	local closing = UiKit.newLabel(panel, UiTheme.bodySize)
	closing.TextColor3 = UiTheme.lockedText
	closing.TextXAlignment = Enum.TextXAlignment.Center
	closing.Position = UDim2.new(0, PADDING, 1, -PADDING - CLOSING_HEIGHT)
	closing.Size = UDim2.new(1, -PADDING * 2, 0, CLOSING_HEIGHT)

	lobby.button.Activated:Connect(function()
		remote:FireServer("lobby")
	end)

	-- A saved one is used with the server; without one the purchase dialog opens first.
	local function creditsOf(attribute: string): number
		local value = player:GetAttribute(attribute)
		return if typeof(value) == "number" then value else 0
	end
	revive.button.Activated:Connect(function()
		if not revive.button.Active then
			return
		end
		if creditsOf("ReviveCredits") > 0 then
			remote:FireServer("revive")
		else
			PurchasePrompt.request(OfferConfig.products.revive)
		end
	end)
	bounty.button.Activated:Connect(function()
		if not bounty.button.Active then
			return
		end
		if creditsOf("BountyCredits") > 0 then
			remote:FireServer("bounty")
		else
			PurchasePrompt.request(OfferConfig.products.bounty)
		end
	end)

	-- The window pops up and the dim layer fades in each time the window opens.
	local function popIn()
		panel.Position = UDim2.new(0.5, 0, 1, -BOTTOM_MARGIN + POP_OFFSET)
		TweenService:Create(
			panel,
			TweenInfo.new(POP_SECONDS, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Position = UDim2.new(0.5, 0, 1, -BOTTOM_MARGIN) }
		):Play()
		dim.BackgroundTransparency = 1
		TweenService:Create(dim, TweenInfo.new(DIM_SECONDS), { BackgroundTransparency = DIM_TRANSPARENCY }):Play()
	end

	-- The small line of a paid choice: the number of saved ones, or the cart for the offer.
	local function subOf(credits: number): string
		return if credits > 0 then "x" .. tostring(credits) else UiKit.glyph("offer")
	end

	local wasOpen = false
	RunService.RenderStepped:Connect(function()
		local until_ = player:GetAttribute("DeathUntil")
		local left = if typeof(until_) == "number" then until_ - workspace:GetServerTimeNow() else 0
		if left <= 0 then
			panel.Visible = false
			dim.Visible = false
			wasOpen = false
			return
		end
		local killer = player:GetAttribute("DeathKiller")
		local name = if typeof(killer) == "string" then killer else ""
		byline.Text = string.format(Strings.death.title, name)
		bounty.word.Text = Strings.death.bounty
		if not PurchasePrompt.canBuy() then
			revive.sub.Text = UiKit.glyph("locked")
			bounty.sub.Text = UiKit.glyph("locked")
			makeDisabled(revive)
			makeDisabled(bounty)
		else
			revive.sub.Text = subOf(creditsOf("ReviveCredits"))
			bounty.sub.Text = subOf(creditsOf("BountyCredits"))
			makeEnabled(revive, UiTheme.reviveButton)
			makeEnabled(bounty, UiTheme.bountyButton)
		end
		if player:GetAttribute("DeathKillerBot") == true then
			bounty.sub.Text = UiKit.glyph("locked")
			makeDisabled(bounty)
		end
		closing.Text = UiKit.withIcon("timer", tostring(math.ceil(left)))
		dim.Visible = true
		panel.Visible = true
		if not wasOpen then
			wasOpen = true
			popIn()
		end
	end)
end

return DeathScreen
