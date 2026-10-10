--!strict
-- Collection menu (the dinodex): standing in the dinodex circle of the lobby opens a window
-- with one card per dino (reached or still unknown), the best round and, behind a tap on a
-- reached dino, the skin list of that dino. Reads the attributes the server publishes (display
-- only).
-- Only checkable in Roblox Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CollectionView = require(Shared:WaitForChild("CollectionView"))
local Strings = require(Shared:WaitForChild("Strings"))
local Dinos = require(Shared:WaitForChild("Config"):WaitForChild("Dinos"))
local DinoLooks = require(Shared:WaitForChild("Config"):WaitForChild("DinoLooks"))

local SkinList = require(script.Parent:WaitForChild("SkinList"))
local UiKit = require(script.Parent:WaitForChild("UiKit"))
local UiTheme = require(script.Parent:WaitForChild("UiTheme"))

-- Window and cards (base sizes in pixels).
local WINDOW_WIDTH = 360
local WINDOW_HEIGHT = 340
local PADDING = 8
local HEADER_HEIGHT = 60
local INFO_HEIGHT = 22
local CARD_WIDTH = 160
local CARD_HEIGHT = 120
local CARD_GAP = 8
local CARD_NAME_HEIGHT = 30
local CARD_HINT_HEIGHT = 22
local CLOSE_SIZE = 60
-- Color of the card of a dino that has no look to take the color from.
local FALLBACK_COLOR = Color3.fromRGB(110, 200, 90)

local CollectionMenu = {}

type CardViews = { card: TextButton, name: TextLabel, hint: TextLabel }

local function lookColor(stageId: string): Color3
	local look = DinoLooks.looks[stageId]
	local part = look and look.parts[1]
	if part == nil then
		return FALLBACK_COLOR
	end
	return Color3.fromRGB(part.color.r, part.color.g, part.color.b)
end

local function newHeaderButton(parent: Instance, text: string): TextButton
	local button = Instance.new("TextButton")
	button.Text = text
	button.FontFace = UiTheme.font
	button.TextSize = UiTheme.titleSize
	button.TextColor3 = UiTheme.text
	button.BackgroundColor3 = UiTheme.panel
	button.Size = UDim2.fromOffset(CLOSE_SIZE, CLOSE_SIZE)
	button.Parent = parent
	local corner = Instance.new("UICorner")
	corner.Parent = button
	return button
end

function CollectionMenu.start()
	local player = Players.LocalPlayer
	local gui = UiKit.newGui("CollectionMenu")

	local window = UiKit.newPanel(gui)
	window.Name = "CollectionWindow"
	window.AnchorPoint = Vector2.new(0.5, 0.5)
	window.Position = UDim2.fromScale(0.5, 0.5)
	window.Size = UDim2.fromOffset(WINDOW_WIDTH, WINDOW_HEIGHT)
	window.Visible = false
	UiKit.addScale(window)

	local title = UiKit.newLabel(window, UiTheme.titleSize)
	title.Text = Strings.collection.title
	title.Position = UDim2.fromOffset(PADDING * 2, PADDING)
	title.Size = UDim2.new(1, -(CLOSE_SIZE + PADDING * 3), 0, HEADER_HEIGHT)

	local close = newHeaderButton(window, Strings.collection.close)
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -PADDING, 0, PADDING)

	local back = newHeaderButton(window, Strings.collection.back)
	back.Position = UDim2.fromOffset(PADDING, PADDING)
	back.Visible = false

	local countLabel = UiKit.newLabel(window, UiTheme.bodySize)
	countLabel.Position = UDim2.fromOffset(PADDING * 2, PADDING + HEADER_HEIGHT)
	countLabel.Size = UDim2.new(1, -PADDING * 4, 0, INFO_HEIGHT)

	local bestLabel = UiKit.newLabel(window, UiTheme.bodySize)
	bestLabel.Position = UDim2.fromOffset(PADDING * 2, PADDING + HEADER_HEIGHT + INFO_HEIGHT)
	bestLabel.Size = UDim2.new(1, -PADDING * 4, 0, INFO_HEIGHT)

	-- Notice for guests, otherwise a hint that the cards can be tapped.
	local noteLabel = UiKit.newLabel(window, UiTheme.bodySize)
	noteLabel.Position = UDim2.fromOffset(PADDING * 2, PADDING + HEADER_HEIGHT + INFO_HEIGHT * 2)
	noteLabel.Size = UDim2.new(1, -PADDING * 4, 0, INFO_HEIGHT)

	local listTop = PADDING + HEADER_HEIGHT + INFO_HEIGHT * 3
	local listPosition = UDim2.fromOffset(PADDING, listTop)
	local listSize = UDim2.new(1, -PADDING * 2, 1, -(listTop + PADDING))

	local list = Instance.new("ScrollingFrame")
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.Position = listPosition
	list.Size = listSize
	list.CanvasSize = UDim2.new()
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.ScrollBarThickness = 4
	list.Parent = window
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(CARD_WIDTH, CARD_HEIGHT)
	grid.CellPadding = UDim2.fromOffset(CARD_GAP, CARD_GAP)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	grid.Parent = list

	local skinList = SkinList.create(window, listPosition, listSize)

	local reachedSet: { [string]: boolean } = {}

	local function showCards()
		skinList.hide()
		list.Visible = true
		back.Visible = false
		title.Text = Strings.collection.title
		title.Position = UDim2.fromOffset(PADDING * 2, PADDING)
		countLabel.Visible = true
		bestLabel.Visible = true
		noteLabel.Visible = true
	end

	local function showSkins(dinoId: string)
		list.Visible = false
		back.Visible = true
		title.Text = Strings.dinos[dinoId] or dinoId
		title.Position = UDim2.fromOffset(CLOSE_SIZE + PADDING * 2, PADDING)
		countLabel.Visible = false
		bestLabel.Visible = false
		noteLabel.Visible = false
		skinList.show(dinoId)
	end

	local views: { CardViews } = {}
	for index, stage in Dinos do
		local card = Instance.new("TextButton")
		card.LayoutOrder = index
		card.BorderSizePixel = 0
		card.Text = ""
		card.AutoButtonColor = false
		card.Parent = list
		local cardCorner = Instance.new("UICorner")
		cardCorner.Parent = card

		local name = UiKit.newLabel(card, UiTheme.titleSize)
		name.Position = UDim2.fromOffset(PADDING, PADDING)
		name.Size = UDim2.new(1, -PADDING * 2, 0, CARD_NAME_HEIGHT)

		local hint = UiKit.newLabel(card, UiTheme.bodySize)
		hint.Position = UDim2.new(0, PADDING, 1, -(PADDING + CARD_HINT_HEIGHT))
		hint.Size = UDim2.new(1, -PADDING * 2, 0, CARD_HINT_HEIGHT)

		card.Activated:Connect(function()
			if reachedSet[stage.id] then
				showSkins(stage.id)
			end
		end)

		table.insert(views, { card = card, name = name, hint = hint })
	end

	local function refresh()
		local reachedText = player:GetAttribute("Reached")
		local best = player:GetAttribute("BestPoints")
		reachedSet = CollectionView.decodeReached(if typeof(reachedText) == "string" then reachedText else "")
		local cards = CollectionView.cards(Dinos, reachedSet)

		local reached, total = CollectionView.summary(cards)
		countLabel.Text = string.format(Strings.collection.count, reached, total)
		bestLabel.Text = string.format(Strings.collection.best, if typeof(best) == "number" then best else 0)
		if player:GetAttribute("DataGuest") == true then
			noteLabel.Text = Strings.collection.guest
			noteLabel.TextColor3 = UiTheme.own
		else
			noteLabel.Text = Strings.collection.skinsHint
			noteLabel.TextColor3 = UiTheme.lockedText
		end

		for index, view in views do
			local data = cards[index]
			if data == nil then
				view.card.Visible = false
				continue
			end
			view.card.Visible = true
			if data.reached then
				view.card.BackgroundColor3 = lookColor(data.id)
				view.name.Text = Strings.dinos[data.id] or data.id
				view.name.TextColor3 = UiTheme.text
				view.hint.Text = ""
			else
				view.card.BackgroundColor3 = UiTheme.lockedCard
				view.name.Text = Strings.collection.locked
				view.name.TextColor3 = UiTheme.lockedText
				view.hint.Text = string.format(Strings.collection.hint, data.minPoints)
				view.hint.TextColor3 = UiTheme.lockedText
			end
		end
	end

	for _, attribute in { "Reached", "BestPoints", "DataGuest" } do
		player:GetAttributeChangedSignal(attribute):Connect(refresh)
	end
	refresh()

	-- The window is open while the player stands in the dinodex circle (the server decides
	-- the zone); the X button closes it until the circle is entered again.
	local function applyZone()
		local inside = player:GetAttribute("ZoneId") == "dex"
		if inside and not window.Visible then
			showCards()
		end
		window.Visible = inside
	end
	player:GetAttributeChangedSignal("ZoneId"):Connect(applyZone)
	applyZone()
	close.Activated:Connect(function()
		window.Visible = false
	end)
	back.Activated:Connect(showCards)
end

return CollectionMenu
