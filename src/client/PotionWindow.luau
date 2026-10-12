--!strict
-- The potion window of the booster circle: open while the player stands in the booster circle in
-- the lobby. It lists the four potions with what they do, the time left and a "View offer" button
-- that opens the purchase dialog. The potions run only in the arena. The server grants a potion
-- when Roblox sends the receipt; the time left is read from the attribute the server publishes
-- (display only). Only checkable in Roblox Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Offers = require(Shared:WaitForChild("Offers"))
local Strings = require(Shared:WaitForChild("Strings"))
local TimeFormat = require(Shared:WaitForChild("TimeFormat"))
local OfferConfig = require(Shared:WaitForChild("Config"):WaitForChild("Offers"))

local PurchasePrompt = require(script.Parent:WaitForChild("PurchasePrompt"))
local UiKit = require(script.Parent:WaitForChild("UiKit"))
local UiTheme = require(script.Parent:WaitForChild("UiTheme"))

-- Base sizes in pixels.
local WINDOW_WIDTH = 340
local PADDING = 12
local TITLE_HEIGHT = 36
local HINT_HEIGHT = 24
local ROW_HEIGHT = 64
local ROW_GAP = 8
local BUTTON_WIDTH = 104
local BUTTON_HEIGHT = 44

local PotionWindow = {}

-- What a potion does, as a short text.
local function effectText(potion: { effect: string, factor: number?, bonusSeconds: number? }): string
	local effect = Strings.potions.effects[potion.effect]
	if potion.effect == "shield" then
		return string.format(effect, tostring(potion.bonusSeconds or 0))
	elseif potion.effect == "speed" then
		return string.format(effect, string.format("%d", math.floor(((potion.factor or 1) - 1) * 100 + 0.5)))
	end
	return string.format(effect, tostring(potion.factor or 1))
end

type Row = { id: string, info: TextLabel, button: TextButton }

function PotionWindow.start()
	local player = Players.LocalPlayer
	local gui = UiKit.newGui("PotionWindow")

	local order = OfferConfig.potionOrder
	local height = PADDING * 2 + TITLE_HEIGHT + (ROW_HEIGHT + ROW_GAP) * #order + HINT_HEIGHT

	local window = UiKit.newPanel(gui)
	window.Name = "Window_boost"
	window.AnchorPoint = Vector2.new(0.5, 0.5)
	window.Position = UDim2.fromScale(0.5, 0.5)
	window.Size = UDim2.fromOffset(WINDOW_WIDTH, height)
	window.Visible = false
	UiKit.addScale(window)

	local title = UiKit.newLabel(window, UiTheme.titleSize)
	title.Text = Strings.potions.title
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Position = UDim2.fromOffset(PADDING, PADDING)
	title.Size = UDim2.new(1, -PADDING * 2, 0, TITLE_HEIGHT)

	local rows: { Row } = {}
	local top = PADDING + TITLE_HEIGHT
	for _, potionId in order do
		local potion = OfferConfig.potions[potionId]
		local info = UiKit.newLabel(window, UiTheme.bodySize)
		info.Position = UDim2.fromOffset(PADDING, top)
		info.Size = UDim2.new(1, -PADDING * 3 - BUTTON_WIDTH, 0, ROW_HEIGHT)
		info.TextWrapped = true
		info.TextTruncate = Enum.TextTruncate.None

		local button = Instance.new("TextButton")
		button.AnchorPoint = Vector2.new(1, 0)
		button.Position = UDim2.new(1, -PADDING, 0, top + (ROW_HEIGHT - BUTTON_HEIGHT) / 2)
		button.Size = UDim2.fromOffset(BUTTON_WIDTH, BUTTON_HEIGHT)
		button.FontFace = UiTheme.font
		button.TextSize = UiTheme.bodySize
		button.TextWrapped = true
		button.BorderSizePixel = 0
		button.Parent = window
		local corner = Instance.new("UICorner")
		corner.Parent = button

		button.Activated:Connect(function()
			if button.Active then
				PurchasePrompt.request(OfferConfig.products[potion.product])
			end
		end)
		table.insert(rows, { id = potionId, info = info, button = button })
		top += ROW_HEIGHT + ROW_GAP
	end

	local hint = UiKit.newLabel(window, UiTheme.bodySize)
	hint.Text = Strings.potions.unavailable
	hint.TextColor3 = UiTheme.lockedText
	hint.TextXAlignment = Enum.TextXAlignment.Center
	hint.Position = UDim2.fromOffset(PADDING, top)
	hint.Size = UDim2.new(1, -PADDING * 2, 0, HINT_HEIGHT)

	local function refresh()
		local saved = PurchasePrompt.canBuy()
		local attribute = player:GetAttribute("Potions")
		local running = Offers.decodePotions(if typeof(attribute) == "string" then attribute else "")
		hint.Text = if saved then Strings.potions.hint else Strings.potions.unavailable
		for _, row in rows do
			local potion = OfferConfig.potions[row.id]
			local left = running[row.id] or 0
			local text = Strings.potions.names[row.id]
				.. "\n"
				.. effectText(potion)
				.. "\n"
				.. string.format(Strings.potions.duration, TimeFormat.compact(potion.durationSeconds))
			if left > 0 then
				text = Strings.potions.names[row.id]
					.. "\n"
					.. effectText(potion)
					.. "\n"
					.. string.format(Strings.potions.left, TimeFormat.compact(left))
			end
			row.info.Text = text

			local full = left + potion.durationSeconds > OfferConfig.maxPotionSeconds
			local enabled = saved and not full
			row.button.Text = if full then Strings.potions.full else Strings.potions.offer
			row.button.Active = enabled
			row.button.AutoButtonColor = enabled
			row.button.BackgroundColor3 = if enabled then UiTheme.accent else UiTheme.lockedCard
			row.button.TextColor3 = if enabled then UiTheme.text else UiTheme.lockedText
		end
	end
	for _, name in { "Potions", "DataReady", "DataGuest" } do
		player:GetAttributeChangedSignal(name):Connect(refresh)
	end

	local function applyZone()
		window.Visible = player:GetAttribute("ZoneId") == "boost"
		if window.Visible then
			refresh()
		end
	end
	player:GetAttributeChangedSignal("ZoneId"):Connect(applyZone)
	applyZone()
	refresh()
end

return PotionWindow
