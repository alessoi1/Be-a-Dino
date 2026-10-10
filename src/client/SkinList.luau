--!strict
-- The skin list of one dino inside the collection window: one row per skin with a color
-- preview, the name and the state. Tapping an available skin sends the intention to the
-- server, which checks everything. Reads the attributes the server publishes (display only).
-- Only checkable in Roblox Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CollectionView = require(Shared:WaitForChild("CollectionView"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local SkinView = require(Shared:WaitForChild("SkinView"))
local Strings = require(Shared:WaitForChild("Strings"))
local DinoLooks = require(Shared:WaitForChild("Config"):WaitForChild("DinoLooks"))
local SkinConfig = require(Shared:WaitForChild("Config"):WaitForChild("Skins"))

local UiKit = require(script.Parent:WaitForChild("UiKit"))
local UiTheme = require(script.Parent:WaitForChild("UiTheme"))

-- Base sizes in pixels.
local ROW_HEIGHT = 64
local ROW_GAP = 8
local PADDING = 8
local CHIP_SIZE = 22
local CHIP_GAP = 4
local STATUS_WIDTH = 150

local SkinList = {}

type Color = { r: number, g: number, b: number }

-- Same shape as SkinView.Skin (the module is loaded by path, so its types are not visible here).
type Skin = {
	id: string,
	dinoId: string,
	unlock: { kind: string, stageId: string?, points: number?, productId: number? },
	colors: { body: Color, accent: Color }?,
}

-- The two preview colors of a skin; the default skin shows the colors of the look.
local function previewColors(dinoId: string, skin: Skin): (Color3, Color3)
	if skin.colors ~= nil then
		local colors = skin.colors
		return Color3.fromRGB(colors.body.r, colors.body.g, colors.body.b),
			Color3.fromRGB(colors.accent.r, colors.accent.g, colors.accent.b)
	end
	local body: Color = { r = 110, g = 200, b = 90 }
	local accent: Color = body
	local look = DinoLooks.looks[dinoId]
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
	return Color3.fromRGB(body.r, body.g, body.b), Color3.fromRGB(accent.r, accent.g, accent.b)
end

local function lockedText(skin: Skin): string
	local unlock = skin.unlock
	if unlock.kind == "reach" and unlock.stageId ~= nil then
		return string.format(Strings.collection.lockedReach, Strings.dinos[unlock.stageId] or unlock.stageId)
	elseif unlock.kind == "best" and unlock.points ~= nil then
		return string.format(Strings.collection.lockedBest, unlock.points)
	end
	return Strings.collection.lockedOther
end

-- Builds the list inside `parent` (the area below the window header). Returns functions
-- to show the skins of a dino, hide the list and refresh it.
function SkinList.create(parent: Instance, position: UDim2, size: UDim2)
	local player = Players.LocalPlayer
	local equipRemote = Remotes.event(Remotes.names.equipSkin)

	local list = Instance.new("ScrollingFrame")
	list.Name = "SkinList"
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

		local unlockedText = player:GetAttribute("UnlockedSkins")
		local equippedText = player:GetAttribute("EquippedSkins")
		local unlocked = CollectionView.decodeReached(if typeof(unlockedText) == "string" then unlockedText else "")
		local equipped = SkinView.decodeEquipped(if typeof(equippedText) == "string" then equippedText else "")

		for index, row in SkinView.rows(SkinConfig.skins, dinoId, unlocked, equipped[dinoId]) do
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

			local body, accent = previewColors(dinoId, row.skin)
			for chipIndex, color in { body, accent } do
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
			name.Text = Strings.skins[row.skin.id] or row.skin.id
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
				status.Text = Strings.collection.skinEquipped
				status.TextColor3 = UiTheme.good
			elseif row.status == "available" then
				status.Text = Strings.collection.skinEquip
			else
				status.Text = lockedText(row.skin)
				status.TextColor3 = UiTheme.lockedText
				name.TextColor3 = UiTheme.lockedText
			end

			local skinId = row.skin.id
			button.Activated:Connect(function()
				if row.status == "available" then
					equipRemote:FireServer(skinId)
				end
			end)
		end
	end

	for _, attribute in { "UnlockedSkins", "EquippedSkins" } do
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

return SkinList
