--!strict
-- The window after being eaten: who ate you and three choices: revive at your size and put a
-- bounty on the killer (both paid with Robux) and back to lobby (free). A saved revive or bounty
-- is used with a tap; otherwise the tap opens the purchase dialog, and the server uses the item as
-- soon as the purchase arrives. The server decides; this only sends the intention. Reads the
-- attributes the server publishes (display only). The screen is dimmed red behind the window,
-- which pops in; each choice has an icon, a title and a smaller second line.
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
local WIDTH = 360
local PADDING = 14
local HEADLINE_HEIGHT = 52
local HEADLINE_SIZE = 40
local BYLINE_HEIGHT = 28
local ROW_HEIGHT = 68
local ROW_GAP = 10
local CLOSING_HEIGHT = 24
local ICON_SIZE = 40
local ICON_GAP = 10
local SUB_SIZE = 14
local EDGE_THICKNESS = 3
-- Vertical position as a share of the screen height, and how far the window pops up from below.
local TOP_SHARE = 0.5
local POP_SHARE = 0.06
local POP_SECONDS = 0.3
-- Transparency of the dim layer once it has faded in, and the seconds it takes.
local DIM_TRANSPARENCY = 0.45
local DIM_SECONDS = 0.4

local DeathScreen = {}

type Choice = { button: TextButton, title: TextLabel, sub: TextLabel }

-- One choice: a bubble button with an icon on the left and a title with a smaller line below.
local function newChoice(parent: Instance, top: number, iconName: string): Choice
	local button = Instance.new("TextButton")
	button.Position = UDim2.fromOffset(PADDING, top)
	button.Size = UDim2.new(1, -PADDING * 2, 0, ROW_HEIGHT)
	button.Text = ""
	button.Parent = parent
	UiKit.styleBubble(button, UiTheme.accent)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.25, 0)
	corner.Parent = button

	local icon = UiKit.newIcon(button, iconName, UDim2.fromOffset(ICON_SIZE, ICON_SIZE))
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.Position = UDim2.new(0, ICON_GAP, 0.5, 0)
	icon.Active = false

	local textLeft = ICON_GAP * 2 + ICON_SIZE
	local title = UiKit.newLabel(button, UiTheme.bodySize)
	title.Position = UDim2.fromOffset(textLeft, 8)
	title.Size = UDim2.new(1, -textLeft - ICON_GAP, 0, 28)
	title.Active = false
	local sub = UiKit.newLabel(button, SUB_SIZE)
	sub.Position = UDim2.fromOffset(textLeft, 36)
	sub.Size = UDim2.new(1, -textLeft - ICON_GAP, 0, 22)
	sub.TextColor3 = UiTheme.silver
	sub.Active = false
	return { button = button, title = title, sub = sub }
end

-- A greyed out choice that does nothing (not available now).
local function makeDisabled(choice: Choice)
	choice.button.Active = false
	choice.button.AutoButtonColor = false
	choice.button.BackgroundColor3 = UiTheme.lockedCard
	choice.title.TextColor3 = UiTheme.lockedText
end

local function makeEnabled(choice: Choice, fill: Color3)
	choice.button.Active = true
	choice.button.AutoButtonColor = true
	choice.button.BackgroundColor3 = fill
	choice.title.TextColor3 = UiTheme.text
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

	local rowsTop = PADDING + HEADLINE_HEIGHT + BYLINE_HEIGHT + ROW_GAP
	local height = rowsTop + (ROW_HEIGHT + ROW_GAP) * 3 + CLOSING_HEIGHT + PADDING - ROW_GAP

	local panel = UiKit.newPanel(gui)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, TOP_SHARE)
	panel.Size = UDim2.fromOffset(WIDTH, height)
	panel.Visible = false
	UiKit.addScale(panel)
	local edge = panel:FindFirstChildOfClass("UIStroke")
	if edge ~= nil then
		edge.Color = UiTheme.danger
		edge.Transparency = 0
		edge.Thickness = EDGE_THICKNESS
	end

	local headline = UiKit.newLabel(panel, HEADLINE_SIZE)
	headline.Text = Strings.death.headline
	headline.TextColor3 = UiTheme.danger
	headline.TextXAlignment = Enum.TextXAlignment.Center
	headline.Position = UDim2.fromOffset(PADDING, PADDING)
	headline.Size = UDim2.new(1, -PADDING * 2, 0, HEADLINE_HEIGHT)

	local byline = UiKit.newLabel(panel, UiTheme.titleSize)
	byline.TextXAlignment = Enum.TextXAlignment.Center
	byline.Position = UDim2.fromOffset(PADDING, PADDING + HEADLINE_HEIGHT)
	byline.Size = UDim2.new(1, -PADDING * 2, 0, BYLINE_HEIGHT)

	local revive = newChoice(panel, rowsTop, "revive")
	local bounty = newChoice(panel, rowsTop + ROW_HEIGHT + ROW_GAP, "bounty")
	local lobby = newChoice(panel, rowsTop + (ROW_HEIGHT + ROW_GAP) * 2, "lobby")
	lobby.title.Text = Strings.death.lobby
	makeEnabled(lobby, UiTheme.lobbyButton)
	-- The free choice has no second line, so its title is centered in the button.
	lobby.title.Position = UDim2.fromOffset(ICON_GAP * 2 + ICON_SIZE, 0)
	lobby.title.Size = UDim2.new(1, -(ICON_GAP * 3 + ICON_SIZE), 1, 0)

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
		panel.Position = UDim2.fromScale(0.5, TOP_SHARE + POP_SHARE)
		TweenService:Create(
			panel,
			TweenInfo.new(POP_SECONDS, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Position = UDim2.fromScale(0.5, TOP_SHARE) }
		):Play()
		dim.BackgroundTransparency = 1
		TweenService:Create(dim, TweenInfo.new(DIM_SECONDS), { BackgroundTransparency = DIM_TRANSPARENCY }):Play()
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
		local saved = PurchasePrompt.canBuy()
		local revives = creditsOf("ReviveCredits")
		local bounties = creditsOf("BountyCredits")
		revive.title.Text = Strings.death.revive
		bounty.title.Text = string.format(Strings.death.bounty, name)
		if not saved then
			revive.sub.Text = Strings.death.needsSave
			bounty.sub.Text = Strings.death.needsSave
			makeDisabled(revive)
			makeDisabled(bounty)
		else
			revive.sub.Text = if revives > 0
				then string.format(Strings.death.savedCount, revives)
				else Strings.death.offer
			bounty.sub.Text = if bounties > 0
				then string.format(Strings.death.savedCount, bounties)
				else Strings.death.offer
			makeEnabled(revive, UiTheme.reviveButton)
			makeEnabled(bounty, UiTheme.bountyButton)
		end
		if player:GetAttribute("DeathKillerBot") == true then
			bounty.title.Text = Strings.death.bountyBot
			bounty.sub.Text = ""
			makeDisabled(bounty)
		end
		closing.Text = string.format(Strings.death.closing, math.ceil(left))
		dim.Visible = true
		panel.Visible = true
		if not wasOpen then
			wasOpen = true
			popIn()
		end
	end)
end

return DeathScreen
