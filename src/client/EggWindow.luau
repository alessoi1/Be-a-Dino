--!strict
-- The egg window of the shop: open while the player stands in the shop circle in the lobby. It
-- shows the price, the coins, all chances as percentages and the button to open an egg. The
-- client only sends the intention; the server checks and rolls, and sends the result back
-- (display only). Only checkable in Roblox Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Eggs = require(Shared:WaitForChild("Eggs"))
local MenuBar = require(Shared:WaitForChild("MenuBar"))
local NumberFormat = require(Shared:WaitForChild("NumberFormat"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Strings = require(Shared:WaitForChild("Strings"))
local EggConfig = require(Shared:WaitForChild("Config"):WaitForChild("Eggs"))
local VariantConfig = require(Shared:WaitForChild("Config"):WaitForChild("Variants"))

local MenuState = require(script.Parent:WaitForChild("MenuState"))
local UiKit = require(script.Parent:WaitForChild("UiKit"))
local UiTheme = require(script.Parent:WaitForChild("UiTheme"))

-- Base sizes in pixels.
local WINDOW_WIDTH = 320
local PADDING = 12
local ROW_HEIGHT = 26
local TITLE_HEIGHT = 40
local BUTTON_HEIGHT = 52
local RESULT_HEIGHT = 56
-- Seconds the shaking egg is shown before the result, and how long the button waits at most.
local SHAKE_SECONDS = 0.8
local WAIT_LIMIT_SECONDS = 4

local EggWindow = {}

function EggWindow.start()
	local player = Players.LocalPlayer
	local openRemote = Remotes.event(Remotes.names.openEgg)
	local resultRemote = Remotes.event(Remotes.names.eggResult)
	local gui = UiKit.newGui("EggWindow")

	local order: { string } = {}
	for _, variant in VariantConfig.variants do
		table.insert(order, variant.id)
	end
	local percents = Eggs.percentages(EggConfig.weights, order)

	local rows = #order
	local height = PADDING * 2 + TITLE_HEIGHT + ROW_HEIGHT * (rows + 3) + RESULT_HEIGHT + BUTTON_HEIGHT + PADDING * 2

	local window = UiKit.newPanel(gui)
	window.Name = "Window_shop"
	window.AnchorPoint = Vector2.new(0.5, 0.5)
	window.Position = UDim2.fromScale(0.5, 0.5)
	window.Size = UDim2.fromOffset(WINDOW_WIDTH, height)
	window.Visible = false
	UiKit.addScale(window)

	local y = PADDING
	local function addLabel(text: string, size: number, rowHeight: number): TextLabel
		local label = UiKit.newLabel(window, size)
		label.Text = text
		label.Position = UDim2.fromOffset(PADDING, y)
		label.Size = UDim2.new(1, -PADDING * 2, 0, rowHeight)
		y += rowHeight
		return label
	end

	local title = addLabel(Strings.eggs.title, UiTheme.titleSize, TITLE_HEIGHT)
	title.TextXAlignment = Enum.TextXAlignment.Center
	addLabel(string.format(Strings.eggs.price, NumberFormat.compact(EggConfig.price)), UiTheme.bodySize, ROW_HEIGHT)
	local balance = addLabel("", UiTheme.bodySize, ROW_HEIGHT)
	balance.TextColor3 = UiTheme.own

	local chancesTitle = addLabel(Strings.eggs.chancesTitle, UiTheme.bodySize, ROW_HEIGHT)
	chancesTitle.TextColor3 = UiTheme.lockedText
	for _, id in order do
		local percent = percents[id]
		local text = if percent % 1 == 0 then string.format("%d", percent) else string.format("%.1f", percent)
		addLabel(string.format(Strings.eggs.chance, Strings.variants[id] or id, text), UiTheme.bodySize, ROW_HEIGHT)
	end

	local result = addLabel("", UiTheme.bodySize, RESULT_HEIGHT)
	result.TextXAlignment = Enum.TextXAlignment.Center
	result.TextWrapped = true
	result.TextTruncate = Enum.TextTruncate.None

	y += PADDING
	local button = Instance.new("TextButton")
	button.AnchorPoint = Vector2.new(0.5, 0)
	button.Position = UDim2.new(0.5, 0, 0, y)
	button.Size = UDim2.new(1, -PADDING * 2, 0, BUTTON_HEIGHT)
	button.BackgroundColor3 = UiTheme.accent
	button.FontFace = UiTheme.font
	button.TextSize = UiTheme.titleSize
	button.TextColor3 = UiTheme.text
	button.Parent = window
	local corner = Instance.new("UICorner")
	corner.Parent = button

	-- Waiting for the server: the button is locked so one tap opens one egg.
	local waiting = 0
	local function refresh()
		local coins = player:GetAttribute("Coins")
		local owned = if typeof(coins) == "number" then coins else 0
		balance.Text = string.format(Strings.eggs.balance, NumberFormat.compact(owned))
		local saved = player:GetAttribute("DataReady") == true and player:GetAttribute("DataGuest") ~= true
		if waiting > 0 then
			button.Text = Strings.eggs.opening
			button.Active = false
			button.AutoButtonColor = false
		elseif not saved then
			button.Text = Strings.eggs.unavailable
			button.Active = false
			button.AutoButtonColor = false
		elseif owned < EggConfig.price then
			button.Text = Strings.eggs.notEnough
			button.Active = false
			button.AutoButtonColor = false
		else
			button.Text = Strings.eggs.open
			button.Active = true
			button.AutoButtonColor = true
		end
		button.TextWrapped = true
	end
	player:GetAttributeChangedSignal("Coins"):Connect(refresh)
	player:GetAttributeChangedSignal("DataReady"):Connect(refresh)
	player:GetAttributeChangedSignal("DataGuest"):Connect(refresh)

	button.Activated:Connect(function()
		if waiting > 0 or not button.Active then
			return
		end
		waiting += 1
		local mine = waiting
		result.Text = ""
		refresh()
		openRemote:FireServer()
		-- If the server never answers (refused), unlock the button again.
		task.delay(WAIT_LIMIT_SECONDS, function()
			if waiting == mine then
				waiting = 0
				refresh()
			end
		end)
	end)

	resultRemote.OnClientEvent:Connect(function(dinoId: any, variantId: any, duplicate: any, refund: any)
		if typeof(dinoId) ~= "string" or typeof(variantId) ~= "string" or typeof(duplicate) ~= "boolean" then
			return
		end
		local mine = waiting
		result.Text = "..."
		task.delay(SHAKE_SECONDS, function()
			if waiting ~= mine then
				return
			end
			local name = string.format(
				Strings.eggs.got,
				Strings.variants[variantId] or variantId,
				Strings.dinos[dinoId] or dinoId
			)
			local extra
			if duplicate then
				local back = if typeof(refund) == "number" then refund else 0
				extra = Strings.eggs.duplicate
					.. (
						if back > 0
							then " (" .. string.format(Strings.eggs.refund, NumberFormat.compact(back)) .. ")"
							else ""
					)
			else
				extra = Strings.eggs.newOne
			end
			result.Text = name .. "\n" .. extra
			waiting = 0
			refresh()
		end)
	end)

	-- Open in the shop circle or after a tap on the menu bar; the X closes it.
	local function applyZone()
		window.Visible = MenuBar.visible(player:GetAttribute("ZoneId"), MenuState.get(), "shop")
	end
	player:GetAttributeChangedSignal("ZoneId"):Connect(applyZone)
	MenuState.changed:Connect(applyZone)
	UiKit.addCloseButton(window, function()
		MenuState.close()
		window.Visible = false
	end)
	applyZone()
	refresh()
end

return EggWindow
