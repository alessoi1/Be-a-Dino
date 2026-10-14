--!strict
-- The daily gift window: a row of seven gift days (coins per day), the day of today's gift
-- highlighted, and one big button to claim it. It opens in the lobby when a gift is ready (the
-- server publishes `DailyAvailable`, `DailyStreak` and `DailyReward`; display only) and the
-- client only sends the intention "claim". Closing it hides it until the next visit.
-- Only checkable in Roblox Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local DailyReward = require(Shared:WaitForChild("DailyReward"))
local NumberFormat = require(Shared:WaitForChild("NumberFormat"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Strings = require(Shared:WaitForChild("Strings"))
local DailyConfig = require(Shared:WaitForChild("Config"):WaitForChild("Daily"))

local MenuState = require(script.Parent:WaitForChild("MenuState"))
local UiKit = require(script.Parent:WaitForChild("UiKit"))
local UiTheme = require(script.Parent:WaitForChild("UiTheme"))

-- Base sizes in pixels.
local PADDING = 14
local TITLE_HEIGHT = 56
local TITLE_SIZE = 44
local COLUMNS = 4
local TILE_WIDTH = 72
local TILE_HEIGHT = 92
local TILE_GAP = 8
local DAY_SIZE = 14
local BUTTON_HEIGHT = 64
-- Share of the screen height of the window center.
local CENTER_SHARE = 0.5

local DailyRewardWindow = {}

type Tile = { frame: Frame, day: TextLabel, coins: TextLabel, mark: TextLabel }

function DailyRewardWindow.start()
	local player = Players.LocalPlayer
	local remote = Remotes.event(Remotes.names.claimDaily)
	local gui = UiKit.newGui("DailyRewardWindow")

	local count = #DailyConfig.rewards
	local rows = math.ceil(count / COLUMNS)
	local width = PADDING * 2 + COLUMNS * TILE_WIDTH + (COLUMNS - 1) * TILE_GAP
	local gridHeight = rows * TILE_HEIGHT + (rows - 1) * TILE_GAP
	local height = PADDING + TITLE_HEIGHT + gridHeight + PADDING + BUTTON_HEIGHT + PADDING

	local window = UiKit.newPanel(gui)
	window.Name = "Window_daily"
	window.AnchorPoint = Vector2.new(0.5, 0.5)
	window.Position = UDim2.fromScale(0.5, CENTER_SHARE)
	window.Size = UDim2.fromOffset(width, height)
	window.Visible = false
	MenuState.registerOverlay(window)
	UiKit.addScale(window)

	local title = UiKit.newLabel(window, TITLE_SIZE)
	title.Text = UiKit.glyph("gift")
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Position = UDim2.fromOffset(PADDING, PADDING)
	title.Size = UDim2.new(1, -PADDING * 2, 0, TITLE_HEIGHT)

	local tiles: { Tile } = {}
	for index, coins in DailyConfig.rewards do
		local column = (index - 1) % COLUMNS
		local row = math.floor((index - 1) / COLUMNS)
		local frame = Instance.new("Frame")
		frame.Position = UDim2.fromOffset(
			PADDING + column * (TILE_WIDTH + TILE_GAP),
			PADDING + TITLE_HEIGHT + row * (TILE_HEIGHT + TILE_GAP)
		)
		frame.Size = UDim2.fromOffset(TILE_WIDTH, TILE_HEIGHT)
		frame.BorderSizePixel = 0
		frame.Parent = window
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.15, 0)
		corner.Parent = frame
		UiKit.addGloss(frame)

		local day = UiKit.newLabel(frame, DAY_SIZE)
		day.Text = string.format(Strings.daily.day, index)
		day.TextXAlignment = Enum.TextXAlignment.Center
		day.Position = UDim2.fromOffset(0, 4)
		day.Size = UDim2.new(1, 0, 0, 20)

		local mark = UiKit.newLabel(frame, 30)
		mark.Text = UiKit.glyph("coin")
		mark.TextXAlignment = Enum.TextXAlignment.Center
		mark.Position = UDim2.fromOffset(0, 24)
		mark.Size = UDim2.new(1, 0, 0, 36)

		local amount = UiKit.newLabel(frame, UiTheme.bodySize)
		amount.Text = NumberFormat.compact(coins)
		amount.TextXAlignment = Enum.TextXAlignment.Center
		amount.Position = UDim2.new(0, 0, 1, -28)
		amount.Size = UDim2.new(1, 0, 0, 24)

		table.insert(tiles, { frame = frame, day = day, coins = amount, mark = mark })
	end

	local button = Instance.new("TextButton")
	button.AnchorPoint = Vector2.new(0.5, 1)
	button.Position = UDim2.new(0.5, 0, 1, -PADDING)
	button.Size = UDim2.new(1, -PADDING * 2, 0, BUTTON_HEIGHT)
	button.Text = UiKit.withIcon("gift", Strings.daily.claim)
	button.FontFace = UiTheme.font
	button.TextSize = TITLE_SIZE / 1.5
	button.TextColor3 = UiTheme.text
	button.TextStrokeTransparency = 0.2
	button.TextStrokeColor3 = UiTheme.outline
	button.Parent = window
	UiKit.styleBubble(button, UiTheme.good)
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0.25, 0)
	buttonCorner.Parent = button

	local dismissed = false
	local function refresh()
		local streak = player:GetAttribute("DailyStreak")
		local current = DailyReward.slot(if typeof(streak) == "number" then streak else 1, count)
		for index, tile in tiles do
			if index < current then
				tile.frame.BackgroundColor3 = UiTheme.good
				tile.mark.Text = UiKit.glyph("on")
			elseif index == current then
				tile.frame.BackgroundColor3 = UiTheme.accent
				tile.mark.Text = UiKit.glyph("gift")
			else
				tile.frame.BackgroundColor3 = UiTheme.lockedCard
				tile.mark.Text = UiKit.glyph("coin")
			end
		end
		local available = player:GetAttribute("DailyAvailable") == true
		window.Visible = available and not dismissed and player:GetAttribute("Mode") == "lobby"
	end
	for _, name in { "DailyAvailable", "DailyStreak", "Mode" } do
		player:GetAttributeChangedSignal(name):Connect(refresh)
	end

	button.Activated:Connect(function()
		remote:FireServer()
	end)
	UiKit.addCloseButton(window, function()
		dismissed = true
		window.Visible = false
	end)
	refresh()
end

return DailyRewardWindow
