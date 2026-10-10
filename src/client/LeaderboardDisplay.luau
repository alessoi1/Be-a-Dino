--!strict
-- Leaderboard at the top right: the best players of this server by points, plus the own
-- row when it is not among them. Built from the attributes the server publishes
-- (display only). Only checkable in Roblox Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Leaderboard = require(Shared:WaitForChild("Leaderboard"))
local Log = require(Shared:WaitForChild("Log"))
local NumberFormat = require(Shared:WaitForChild("NumberFormat"))
local Strings = require(Shared:WaitForChild("Strings"))
local Ui = require(Shared:WaitForChild("Config"):WaitForChild("Ui"))

local UiKit = require(script.Parent:WaitForChild("UiKit"))
local UiTheme = require(script.Parent:WaitForChild("UiTheme"))

local PANEL_WIDTH = 150
local PADDING = 8
local TITLE_HEIGHT = 24
local ROW_HEIGHT = 22
local POINTS_WIDTH = 48

local log = Log.new("Leaderboard")

local LeaderboardDisplay = {}

-- Same shape as Leaderboard.Entry (the module is loaded by path, so its types are not visible here).
type Entry = { id: number, name: string, points: number, stageId: string }

type RowViews = { row: Frame, name: TextLabel, points: TextLabel }

local function readEntry(player: Player): Entry
	local points = player:GetAttribute("Points")
	local stage = player:GetAttribute("Stage")
	return {
		id = player.UserId,
		name = player.DisplayName,
		points = if typeof(points) == "number" then points else 0,
		stageId = if typeof(stage) == "string" then stage else "",
	}
end

function LeaderboardDisplay.start()
	local localPlayer = Players.LocalPlayer
	local gui = UiKit.newGui("Leaderboard")
	UiKit.showOnlyInMode(gui, "playing")

	-- One row more than the list size, for the own row below the list.
	local maxRows = Ui.leaderboardSize + 1

	local panel = UiKit.newPanel(gui)
	panel.AnchorPoint = Vector2.new(1, 0)
	panel.Position = UDim2.new(1, -UiTheme.margin, 0, UiTheme.margin)
	panel.Size = UDim2.fromOffset(PANEL_WIDTH, PADDING * 2 + TITLE_HEIGHT + ROW_HEIGHT * maxRows)
	UiKit.addScale(panel)

	local title = UiKit.newLabel(panel, UiTheme.titleSize)
	title.Text = Strings.leaderboard.title
	title.Position = UDim2.fromOffset(PADDING, PADDING)
	title.Size = UDim2.new(1, -PADDING * 2, 0, TITLE_HEIGHT)

	local views: { RowViews } = {}
	for index = 1, maxRows do
		local row = Instance.new("Frame")
		row.BackgroundTransparency = 1
		row.Position = UDim2.fromOffset(PADDING, PADDING + TITLE_HEIGHT + ROW_HEIGHT * (index - 1))
		row.Size = UDim2.new(1, -PADDING * 2, 0, ROW_HEIGHT)
		row.Visible = false
		row.Parent = panel

		local name = UiKit.newLabel(row, UiTheme.bodySize)
		name.Size = UDim2.new(1, -POINTS_WIDTH, 1, 0)

		local points = UiKit.newLabel(row, UiTheme.bodySize)
		points.AnchorPoint = Vector2.new(1, 0)
		points.Position = UDim2.fromScale(1, 0)
		points.Size = UDim2.new(0, POINTS_WIDTH, 1, 0)
		points.TextXAlignment = Enum.TextXAlignment.Right

		table.insert(views, { row = row, name = name, points = points })
	end

	local function render()
		local entries: { Entry } = {}
		for _, player in Players:GetPlayers() do
			-- Only the players in the arena are ranked here (the lobby has its own lists later).
			if player:GetAttribute("Mode") == "playing" then
				table.insert(entries, readEntry(player))
			end
		end
		local rows = Leaderboard.rank(entries, Ui.leaderboardSize, localPlayer.UserId)
		for index, view in views do
			local data = rows[index]
			if data == nil then
				view.row.Visible = false
				continue
			end
			view.row.Visible = true
			view.name.Text = string.format("%d. %s", data.rank, data.name)
			view.points.Text = NumberFormat.compact(data.points)
			local color = if data.isOwn then UiTheme.own else UiTheme.text
			view.name.TextColor3 = color
			view.points.TextColor3 = color
		end
	end

	-- Changes only mark the list as outdated; the refresh below runs at a fixed pace.
	local dirty = true
	local function markDirty()
		dirty = true
	end
	local function watch(player: Player)
		player:GetAttributeChangedSignal("Points"):Connect(markDirty)
		player:GetAttributeChangedSignal("Mode"):Connect(markDirty)
		markDirty()
	end
	Players.PlayerAdded:Connect(watch)
	Players.PlayerRemoving:Connect(markDirty)
	for _, player in Players:GetPlayers() do
		watch(player)
	end

	task.spawn(function()
		while true do
			if dirty then
				dirty = false
				local ok, err = pcall(render)
				if not ok then
					log.error("refresh failed", { error = tostring(err) })
				end
			end
			task.wait(Ui.leaderboardRefreshSeconds)
		end
	end)
end

return LeaderboardDisplay
