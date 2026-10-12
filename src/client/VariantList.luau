--!strict
-- The variant list of one dino inside the dinodex window: the normal look and the four variants,
-- each with a color preview, the name and the state. Tapping an owned variant sends the intention
-- to the server, which checks everything. Reads the attributes the server publishes (display
-- only). Only checkable in Roblox Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local Strings = require(Shared:WaitForChild("Strings"))
local VariantBook = require(Shared:WaitForChild("VariantBook"))
local Variants = require(Shared:WaitForChild("Variants"))
local DinoLooks = require(Shared:WaitForChild("Config"):WaitForChild("DinoLooks"))
local VariantConfig = require(Shared:WaitForChild("Config"):WaitForChild("Variants"))

local UiKit = require(script.Parent:WaitForChild("UiKit"))
local UiTheme = require(script.Parent:WaitForChild("UiTheme"))

-- Base sizes in pixels.
local ROW_HEIGHT = 56
local ROW_GAP = 8
local PADDING = 8
local CHIP_SIZE = 22
local CHIP_GAP = 4
local STATUS_WIDTH = 150
-- Colors of a dino without a look to take them from.
local FALLBACK_BODY = { r = 110, g = 200, b = 90 }
local FALLBACK_ACCENT = { r = 235, g = 215, b = 100 }

local VariantList = {}

type Color = { r: number, g: number, b: number }

-- The ids of the variants in config order.
local variantOrder: { string } = {}
for _, variant in VariantConfig.variants do
	table.insert(variantOrder, variant.id)
end

-- The two colors a dino has in its normal look (main color and second color).
local function baseColors(dinoId: string): (Color, Color)
	local plan = DinoLooks.plans[dinoId]
	if plan ~= nil then
		return plan.body, plan.accent
	end
	local look = DinoLooks.looks[dinoId]
	local body: Color = FALLBACK_BODY
	local accent: Color = FALLBACK_ACCENT
	if look ~= nil then
		local bodySeen = false
		local accentSeen = false
		for _, spec in look.parts do
			if spec.role == "body" and not bodySeen then
				body = spec.color
				bodySeen = true
			elseif spec.role == "accent" and not accentSeen then
				accent = spec.color
				accentSeen = true
			end
		end
	end
	return body, accent
end

-- The preview colors of a row: the normal look, or the colors the variant gives those parts.
local function previewColors(dinoId: string, variantId: string): (Color3, Color3)
	local body, accent = baseColors(dinoId)
	local variant = Variants.find(VariantConfig.variants, variantId)
	if variant ~= nil then
		local bodyLook = Variants.appearance(
			variant,
			body,
			"body",
			1,
			2,
			VariantConfig.rainbowSaturation,
			VariantConfig.rainbowValue
		)
		local accentLook = Variants.appearance(
			variant,
			accent,
			"accent",
			2,
			2,
			VariantConfig.rainbowSaturation,
			VariantConfig.rainbowValue
		)
		body = bodyLook.color
		accent = accentLook.color
	end
	return Color3.fromRGB(body.r, body.g, body.b), Color3.fromRGB(accent.r, accent.g, accent.b)
end

-- Builds the list inside `parent` (the area below the window header). Returns functions to show
-- the variants of a dino, hide the list and refresh it.
function VariantList.create(parent: Instance, position: UDim2, size: UDim2)
	local player = Players.LocalPlayer
	local equipRemote = Remotes.event(Remotes.names.equipVariant)

	local list = Instance.new("ScrollingFrame")
	list.Name = "VariantList"
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.Position = position
	list.Size = size
	list.CanvasSize = UDim2.new()
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.ScrollBarThickness = 4
	list.Visible = false
	list.Parent = parent
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, ROW_GAP)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list

	local currentDino: string? = nil

	local function refresh()
		for _, child in list:GetChildren() do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		local dinoId = currentDino
		if dinoId == nil then
			return
		end

		local ownedText = player:GetAttribute("Variants")
		local equippedText = player:GetAttribute("EquippedVariants")
		local owned = VariantBook.decodeOwned(if typeof(ownedText) == "string" then ownedText else "")
		local equipped = VariantBook.decodeEquipped(if typeof(equippedText) == "string" then equippedText else "")

		local rows = VariantBook.rows(variantOrder, VariantConfig.normalId, owned[dinoId] or {}, equipped[dinoId])
		for index, row in rows do
			local button = Instance.new("TextButton")
			button.LayoutOrder = index
			button.Size = UDim2.new(1, -PADDING, 0, ROW_HEIGHT)
			button.BackgroundColor3 = UiTheme.panel
			button.BackgroundTransparency = 0.2
			button.BorderSizePixel = 0
			button.Text = ""
			button.AutoButtonColor = row.status == "available"
			button.Parent = list
			local corner = Instance.new("UICorner")
			corner.Parent = button

			local bodyColor, accentColor = previewColors(dinoId, row.id)
			for chipIndex, color in { bodyColor, accentColor } do
				local chip = Instance.new("Frame")
				chip.BackgroundColor3 = color
				chip.BorderSizePixel = 0
				chip.Position =
					UDim2.fromOffset(PADDING + (chipIndex - 1) * (CHIP_SIZE + CHIP_GAP), (ROW_HEIGHT - CHIP_SIZE) / 2)
				chip.Size = UDim2.fromOffset(CHIP_SIZE, CHIP_SIZE)
				chip.Parent = button
				local chipCorner = Instance.new("UICorner")
				chipCorner.CornerRadius = UDim.new(0.5, 0)
				chipCorner.Parent = chip
			end

			local nameX = PADDING * 2 + CHIP_SIZE * 2 + CHIP_GAP
			local name = UiKit.newLabel(button, UiTheme.bodySize)
			name.Text = Strings.variants[row.id] or row.id
			name.Position = UDim2.fromOffset(nameX, 0)
			name.Size = UDim2.new(1, -(nameX + STATUS_WIDTH + PADDING), 1, 0)

			local status = UiKit.newLabel(button, UiTheme.bodySize)
			status.AnchorPoint = Vector2.new(1, 0)
			status.Position = UDim2.new(1, -PADDING, 0, 0)
			status.Size = UDim2.new(0, STATUS_WIDTH, 1, 0)
			status.TextXAlignment = Enum.TextXAlignment.Right
			status.TextWrapped = true
			status.TextTruncate = Enum.TextTruncate.None
			if row.status == "equipped" then
				status.Text = Strings.collection.variantEquipped
				status.TextColor3 = UiTheme.good
			elseif row.status == "available" then
				status.Text = Strings.collection.variantEquip
			else
				status.Text = Strings.collection.variantLocked
				status.TextColor3 = UiTheme.lockedText
				name.TextColor3 = UiTheme.lockedText
			end

			local variantId = row.id
			button.Activated:Connect(function()
				if row.status == "available" then
					equipRemote:FireServer(dinoId, variantId)
				end
			end)
		end
	end

	for _, attribute in { "Variants", "EquippedVariants" } do
		player:GetAttributeChangedSignal(attribute):Connect(refresh)
	end

	return {
		show = function(dinoId: string)
			currentDino = dinoId
			list.Visible = true
			list.CanvasPosition = Vector2.zero
			refresh()
		end,
		hide = function()
			currentDino = nil
			list.Visible = false
		end,
		refresh = refresh,
	}
end

return VariantList
