--!strict
-- The window after being eaten: who ate you and three choices: revive at your size and put a
-- bounty on the killer (both paid with Robux) and back to lobby (free). A saved revive or bounty
-- is used with a tap; otherwise the tap opens the purchase dialog, and the server uses the item as
-- soon as the purchase arrives. The server decides; this only sends the intention. Reads the
-- attributes the server publishes (display only). Only checkable in Roblox Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local Strings = require(Shared:WaitForChild("Strings"))
local OfferConfig = require(Shared:WaitForChild("Config"):WaitForChild("Offers"))

local PurchasePrompt = require(script.Parent:WaitForChild("PurchasePrompt"))
local UiKit = require(script.Parent:WaitForChild("UiKit"))
local UiTheme = require(script.Parent:WaitForChild("UiTheme"))

-- Base sizes in pixels.
local WIDTH = 340
local PADDING = 12
local TITLE_HEIGHT = 32
local INFO_HEIGHT = 24
local ROW_HEIGHT = 60
local ROW_GAP = 8
-- Vertical position as a share of the screen height (a little below the middle).
local TOP_SHARE = 0.55

local DeathScreen = {}

local function newRow(parent: Instance, top: number): TextButton
	local row = Instance.new("TextButton")
	row.Position = UDim2.fromOffset(PADDING, top)
	row.Size = UDim2.new(1, -PADDING * 2, 0, ROW_HEIGHT)
	row.FontFace = UiTheme.font
	row.TextSize = UiTheme.bodySize
	row.TextWrapped = true
	row.BorderSizePixel = 0
	row.Parent = parent
	local corner = Instance.new("UICorner")
	corner.Parent = row
	return row
end

-- A greyed out row that does nothing (a choice that is not available now).
local function makeDisabled(row: TextButton)
	row.Active = false
	row.AutoButtonColor = false
	row.BackgroundColor3 = UiTheme.lockedCard
	row.TextColor3 = UiTheme.lockedText
end

-- A paid row that can be tapped.
local function makeEnabled(row: TextButton)
	row.Active = true
	row.AutoButtonColor = true
	row.BackgroundColor3 = UiTheme.accent
	row.TextColor3 = UiTheme.text
end

function DeathScreen.start()
	local player = Players.LocalPlayer
	local remote = Remotes.event(Remotes.names.deathChoice)
	local gui = UiKit.newGui("DeathScreen")

	local rowsTop = PADDING + TITLE_HEIGHT + INFO_HEIGHT + ROW_GAP
	local height = rowsTop + (ROW_HEIGHT + ROW_GAP) * 3 + PADDING - ROW_GAP

	local panel = UiKit.newPanel(gui)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, TOP_SHARE)
	panel.Size = UDim2.fromOffset(WIDTH, height)
	panel.Visible = false
	UiKit.addScale(panel)

	local title = UiKit.newLabel(panel, UiTheme.titleSize)
	title.Position = UDim2.fromOffset(PADDING, PADDING)
	title.Size = UDim2.new(1, -PADDING * 2, 0, TITLE_HEIGHT)

	local closing = UiKit.newLabel(panel, UiTheme.bodySize)
	closing.Position = UDim2.fromOffset(PADDING, PADDING + TITLE_HEIGHT)
	closing.Size = UDim2.new(1, -PADDING * 2, 0, INFO_HEIGHT)
	closing.TextColor3 = UiTheme.lockedText

	local revive = newRow(panel, rowsTop)

	local bounty = newRow(panel, rowsTop + ROW_HEIGHT + ROW_GAP)
	makeDisabled(bounty)

	local lobby = newRow(panel, rowsTop + (ROW_HEIGHT + ROW_GAP) * 2)
	lobby.Text = Strings.death.lobby
	lobby.BackgroundColor3 = UiTheme.good
	lobby.TextColor3 = UiTheme.text
	lobby.AutoButtonColor = true

	lobby.Activated:Connect(function()
		remote:FireServer("lobby")
	end)

	-- A saved one is used with the server; without one the purchase dialog opens first.
	local function creditsOf(attribute: string): number
		local value = player:GetAttribute(attribute)
		return if typeof(value) == "number" then value else 0
	end
	revive.Activated:Connect(function()
		if not revive.Active then
			return
		end
		if creditsOf("ReviveCredits") > 0 then
			remote:FireServer("revive")
		else
			PurchasePrompt.request(OfferConfig.products.revive)
		end
	end)
	bounty.Activated:Connect(function()
		if not bounty.Active then
			return
		end
		if creditsOf("BountyCredits") > 0 then
			remote:FireServer("bounty")
		else
			PurchasePrompt.request(OfferConfig.products.bounty)
		end
	end)

	RunService.RenderStepped:Connect(function()
		local until_ = player:GetAttribute("DeathUntil")
		local left = if typeof(until_) == "number" then until_ - workspace:GetServerTimeNow() else 0
		if left <= 0 then
			panel.Visible = false
			return
		end
		local killer = player:GetAttribute("DeathKiller")
		local name = if typeof(killer) == "string" then killer else ""
		title.Text = string.format(Strings.death.title, name)
		local saved = PurchasePrompt.canBuy()
		local revives = creditsOf("ReviveCredits")
		local bounties = creditsOf("BountyCredits")
		if not saved then
			revive.Text = Strings.death.revive .. "\n" .. Strings.death.needsSave
			bounty.Text = string.format(Strings.death.bounty, name) .. "\n" .. Strings.death.needsSave
			makeDisabled(revive)
			makeDisabled(bounty)
		else
			revive.Text = if revives > 0
				then string.format(Strings.death.reviveSaved, revives)
				else Strings.death.revive .. "\n" .. Strings.death.offer
			bounty.Text = if bounties > 0
				then string.format(Strings.death.bountySaved, name, bounties)
				else string.format(Strings.death.bounty, name) .. "\n" .. Strings.death.offer
			makeEnabled(revive)
			makeEnabled(bounty)
		end
		if player:GetAttribute("DeathKillerBot") == true then
			bounty.Text = Strings.death.bountyBot
			makeDisabled(bounty)
		end
		closing.Text = string.format(Strings.death.closing, math.ceil(left))
		panel.Visible = true
	end)
end

return DeathScreen
