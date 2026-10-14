--!strict
-- The daily quests: a round clipboard button in the lobby (with a gift mark while a finished quest
-- waits to be claimed) opens a window with today's three quests. Each row shows a symbol for what
-- counts, a name, a progress bar and a button that gives the coins once the goal is reached. The
-- server publishes the state as one attribute text (`Quests`) and checks every claim; the client
-- only sends the intention. Only checkable in Roblox Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local NumberFormat = require(Shared:WaitForChild("NumberFormat"))
local Quests = require(Shared:WaitForChild("Quests"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Strings = require(Shared:WaitForChild("Strings"))
local QuestConfig = require(Shared:WaitForChild("Config"):WaitForChild("Quests"))

local UiKit = require(script.Parent:WaitForChild("UiKit"))
local UiMetrics = require(script.Parent:WaitForChild("UiMetrics"))
local UiTheme = require(script.Parent:WaitForChild("UiTheme"))

-- Base sizes in pixels.
local WIDTH = 360
local PADDING = 14
local TITLE_HEIGHT = 48
local ROW_HEIGHT = 84
local ROW_GAP = 8
local KIND_ICON = 40
local CLAIM_WIDTH = 84
local BAR_HEIGHT = 14
local BUTTON_MARGIN = 12
local BADGE_SHARE = 0.4

-- The symbol for what a quest counts (icon names of Config/Icons).
local KIND_ICONS: { [string]: string } = {
	food = "food",
	kill = "ate",
	grow = "size",
	combo = "combo",
	play = "timer",
}

local QuestWindow = {}

type RowViews = {
	frame: Frame,
	icon: TextLabel,
	name: TextLabel,
	count: TextLabel,
	fill: Frame,
	claim: TextButton,
}

function QuestWindow.start()
	local player = Players.LocalPlayer
	local remote = Remotes.event(Remotes.names.claimQuest)
	local gui = UiKit.newGui("QuestWindow")
	UiKit.showOnlyInMode(gui, "lobby")

	local height = PADDING + TITLE_HEIGHT + (ROW_HEIGHT + ROW_GAP) * QuestConfig.perDay + PADDING - ROW_GAP

	local window = UiKit.newPanel(gui)
	window.Name = "Window_quests"
	window.AnchorPoint = Vector2.new(0.5, 0.5)
	window.Position = UDim2.fromScale(0.5, 0.5)
	window.Size = UDim2.fromOffset(WIDTH, height)
	window.Visible = false
	UiKit.addScale(window)

	local title = UiKit.newLabel(window, UiTheme.titleSize)
	title.Text = UiKit.withIcon("quest", Strings.quests.title)
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Position = UDim2.fromOffset(PADDING, PADDING)
	title.Size = UDim2.new(1, -PADDING * 2, 0, TITLE_HEIGHT)

	local rows: { RowViews } = {}
	for index = 1, QuestConfig.perDay do
		local frame = Instance.new("Frame")
		frame.Position = UDim2.fromOffset(PADDING, PADDING + TITLE_HEIGHT + (index - 1) * (ROW_HEIGHT + ROW_GAP))
		frame.Size = UDim2.new(1, -PADDING * 2, 0, ROW_HEIGHT)
		frame.BackgroundColor3 = UiTheme.panel
		frame.BackgroundTransparency = 0.3
		frame.BorderSizePixel = 0
		frame.Visible = false
		frame.Parent = window
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.15, 0)
		corner.Parent = frame

		local icon = UiKit.newLabel(frame, KIND_ICON)
		icon.TextXAlignment = Enum.TextXAlignment.Center
		icon.Position = UDim2.fromOffset(6, 0)
		icon.Size = UDim2.new(0, KIND_ICON + 8, 1, 0)

		local textLeft = KIND_ICON + 18
		local textWidth = UDim2.new(1, -textLeft - CLAIM_WIDTH - 16, 0, 24)
		local name = UiKit.newLabel(frame, UiTheme.bodySize)
		name.Position = UDim2.fromOffset(textLeft, 8)
		name.Size = textWidth

		local barTrack, fill = UiKit.newBar(frame, UiTheme.good)
		barTrack.Position = UDim2.fromOffset(textLeft, 40)
		barTrack.Size = UDim2.new(1, -textLeft - CLAIM_WIDTH - 16, 0, BAR_HEIGHT)

		local count = UiKit.newLabel(frame, UiTheme.bodySize)
		count.Position = UDim2.fromOffset(textLeft, 58)
		count.Size = textWidth
		count.TextColor3 = UiTheme.lockedText

		local claim = Instance.new("TextButton")
		claim.AnchorPoint = Vector2.new(1, 0.5)
		claim.Position = UDim2.new(1, -8, 0.5, 0)
		claim.Size = UDim2.fromOffset(CLAIM_WIDTH, ROW_HEIGHT - 24)
		claim.FontFace = UiTheme.font
		claim.TextSize = UiTheme.titleSize
		claim.TextColor3 = UiTheme.text
		claim.TextWrapped = true
		claim.Parent = frame
		UiKit.styleBubble(claim, UiTheme.lockedCard)
		local claimCorner = Instance.new("UICorner")
		claimCorner.CornerRadius = UDim.new(0.25, 0)
		claimCorner.Parent = claim

		table.insert(rows, { frame = frame, icon = icon, name = name, count = count, fill = fill, claim = claim })
	end

	-- Which quest each row shows (set by refresh), so a tap claims the right one.
	local rowQuestIds: { string } = {}
	for index, row in rows do
		row.claim.Activated:Connect(function()
			local questId = rowQuestIds[index]
			if questId ~= nil and row.claim.Active then
				remote:FireServer(questId)
			end
		end)
	end

	-- The button in the lobby, left edge in the middle (the bottom left is where the thumbstick is).
	local button = Instance.new("TextButton")
	button.Name = "QuestButton"
	button.AnchorPoint = Vector2.new(0, 0.5)
	button.Text = ""
	button.Parent = gui
	UiKit.styleBubble(button, UiTheme.lobbyButton)
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0.25, 0)
	buttonCorner.Parent = button
	local buttonIcon = UiKit.newIcon(button, "quest", UDim2.fromScale(0.64, 0.64))
	buttonIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	buttonIcon.Position = UDim2.fromScale(0.5, 0.5)
	buttonIcon.Active = false
	local badge = UiKit.newCaption(button, UiKit.glyph("gift"), UDim2.fromScale(BADGE_SHARE, BADGE_SHARE))
	badge.AnchorPoint = Vector2.new(1, 0)
	badge.Position = UDim2.fromScale(1.1, -0.1)
	badge.Visible = false

	UiMetrics.watch(function()
		local scale = UiMetrics.scale()
		local size = UiMetrics.smallButtonSize()
		button.Size = UDim2.fromOffset(size, size)
		button.Position = UDim2.new(0, BUTTON_MARGIN * scale, 0.5, 0)
	end)
	button.Activated:Connect(function()
		window.Visible = not window.Visible
	end)
	UiKit.addCloseButton(window, function()
		window.Visible = false
	end)

	local function refresh()
		local attribute = player:GetAttribute("Quests")
		local views = Quests.decode(if typeof(attribute) == "string" then attribute else "")
		local anyReady = false
		for index, row in rows do
			local view = views[index]
			if view == nil then
				row.frame.Visible = false
				rowQuestIds[index] = nil
				continue
			end
			rowQuestIds[index] = view.id
			row.frame.Visible = true
			local pool = QuestConfig.pool
			local kind = "food"
			for _, quest in pool do
				if quest.id == view.id then
					kind = quest.kind
				end
			end
			row.icon.Text = UiKit.glyph(KIND_ICONS[kind] or "food")
			row.name.Text = Strings.quests.names[view.id] or view.id
			row.count.Text =
				string.format("%s / %s", NumberFormat.compact(view.progress), NumberFormat.compact(view.target))
			row.fill.Size = UDim2.fromScale(math.clamp(view.progress / math.max(view.target, 1), 0, 1), 1)
			local done = view.progress >= view.target
			if view.claimed then
				row.claim.Text = UiKit.glyph("on")
				row.claim.Active = false
				row.claim.AutoButtonColor = false
				row.claim.BackgroundColor3 = UiTheme.lockedCard
			elseif done then
				row.claim.Text = UiKit.withIcon("coin", NumberFormat.compact(view.coins))
				row.claim.Active = true
				row.claim.AutoButtonColor = true
				row.claim.BackgroundColor3 = UiTheme.accent
				anyReady = true
			else
				row.claim.Text = UiKit.withIcon("coin", NumberFormat.compact(view.coins))
				row.claim.Active = false
				row.claim.AutoButtonColor = false
				row.claim.BackgroundColor3 = UiTheme.lockedCard
			end
		end
		badge.Visible = anyReady
	end
	player:GetAttributeChangedSignal("Quests"):Connect(refresh)
	refresh()
end

return QuestWindow
