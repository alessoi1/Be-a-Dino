--!strict
-- The global leaderboards: three boards on the north wall of the lobby (most kills, biggest size,
-- longest playtime). Each list is a sorted DataStore; the profile stays the source of the
-- numbers. Every player with a loaded profile is written to the lists from time to time (and when
-- leaving), and the top entries are read again and shown on the boards. A failing DataStore only
-- leaves the boards as they are. In Studio the stores get a suffix, so tests do not touch the real
-- lists. Only checkable in Roblox Studio.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GlobalBoard = require(Shared:WaitForChild("GlobalBoard"))
local Log = require(Shared:WaitForChild("Log"))
local NumberFormat = require(Shared:WaitForChild("NumberFormat"))
local Strings = require(Shared:WaitForChild("Strings"))
local TimeFormat = require(Shared:WaitForChild("TimeFormat"))
local BoardConfig = require(Shared:WaitForChild("Config"):WaitForChild("Leaderboards"))
local Lobby = require(Shared:WaitForChild("Config"):WaitForChild("Lobby"))

local DataService = require(script.Parent:WaitForChild("DataService"))

type Category = { id: string, storeName: string }

-- Same shape as GlobalBoard.Raw (the module is loaded by path, so its types are not visible here).
type Raw = { key: string, value: number }

type BoardViews = {
	title: TextLabel,
	ranks: { TextLabel },
	names: { TextLabel },
	values: { TextLabel },
}

-- Looks of the boards (no game values): canvas size in pixels per stud and the row layout.
local PIXELS_PER_STUD = 20
local TITLE_HEIGHT = 50
local ROW_HEIGHT = 30
local RANK_WIDTH = 50
local VALUE_WIDTH = 170
local BOARD_THICKNESS = 0.5
local BOARD_COLOR = Color3.fromRGB(25, 30, 45)
local TITLE_COLOR = Color3.fromRGB(255, 215, 90)
local TEXT_COLOR = Color3.fromRGB(255, 255, 255)

local log = Log.new("LeaderboardService")

local stores: { [string]: OrderedDataStore } = {}
local boards: { [string]: BoardViews } = {}
local loaded: { [string]: boolean } = {}
local names: { [number]: string } = {}
-- The numbers written last per player and list (only changed numbers are written).
local lastWritten: { [number]: { [string]: number } } = {}

local LeaderboardService = {}

local function storeNameFor(category: Category): string
	if RunService:IsStudio() then
		return category.storeName .. BoardConfig.studioSuffix
	end
	return category.storeName
end

local function newLabel(parent: Instance, x: number, y: number, width: number, align: Enum.TextXAlignment): TextLabel
	local label = Instance.new("TextLabel")
	label.Position = UDim2.fromOffset(x, y)
	label.Size = UDim2.fromOffset(width, ROW_HEIGHT)
	label.BackgroundTransparency = 1
	label.FontFace = Font.fromEnum(Enum.Font.FredokaOne)
	label.TextScaled = true
	label.TextColor3 = TEXT_COLOR
	label.TextXAlignment = align
	label.Text = ""
	label.Parent = parent
	return label
end

local function buildBoard(folder: Instance, category: Category, centerX: number): BoardViews
	local width = BoardConfig.board.width
	local height = BoardConfig.board.height
	local y = Lobby.height + BoardConfig.board.middleHeight
	-- On the far side of the lobby (away from the window), so they do not block the view.
	local z = Lobby.centerZ + Lobby.size / 2 - BoardConfig.board.inset
	local position = Vector3.new(Lobby.centerX + centerX, y, z)

	local part = Instance.new("Part")
	part.Name = "Board_" .. category.id
	part.Size = Vector3.new(width, height, BOARD_THICKNESS)
	-- The front side (the one with the text) looks toward the middle of the lobby and the window.
	part.CFrame = CFrame.lookAt(position, position + Vector3.new(0, 0, -1))
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Color = BOARD_COLOR
	part.Material = Enum.Material.SmoothPlastic
	part.Parent = folder

	local canvasWidth = width * PIXELS_PER_STUD
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = PIXELS_PER_STUD
	gui.Parent = part

	local title = newLabel(gui, 0, 0, canvasWidth, Enum.TextXAlignment.Center)
	title.Size = UDim2.fromOffset(canvasWidth, TITLE_HEIGHT)
	title.TextColor3 = TITLE_COLOR
	title.Text = Strings.boards[category.id] or category.id

	local views: BoardViews = { title = title, ranks = {}, names = {}, values = {} }
	for row = 1, BoardConfig.rows do
		local top = TITLE_HEIGHT + (row - 1) * ROW_HEIGHT
		table.insert(views.ranks, newLabel(gui, 0, top, RANK_WIDTH, Enum.TextXAlignment.Center))
		table.insert(
			views.names,
			newLabel(gui, RANK_WIDTH, top, canvasWidth - RANK_WIDTH - VALUE_WIDTH, Enum.TextXAlignment.Left)
		)
		table.insert(
			views.values,
			newLabel(gui, canvasWidth - VALUE_WIDTH, top, VALUE_WIDTH, Enum.TextXAlignment.Right)
		)
	end
	return views
end

local function showMessage(views: BoardViews, text: string)
	for index = 1, BoardConfig.rows do
		views.ranks[index].Text = ""
		views.values[index].Text = ""
		views.names[index].Text = if index == 1 then text else ""
	end
end

-- The name of a user: the name of a player who is here, otherwise one request (kept afterwards).
local function nameFor(userId: number): string
	local cached = names[userId]
	if cached ~= nil then
		return cached
	end
	local online = Players:GetPlayerByUserId(userId)
	if online ~= nil then
		names[userId] = online.Name
		return online.Name
	end
	local ok, result = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	if ok and type(result) == "string" then
		names[userId] = result
		return result
	end
	log.debug("name not found", { userId = userId })
	return Strings.boards.unknownName
end

local function formatValue(categoryId: string, value: number): string
	if categoryId == "time" then
		return TimeFormat.compact(value)
	end
	return NumberFormat.compact(value)
end

local function refreshBoard(category: Category)
	local store = stores[category.id]
	local views = boards[category.id]
	if store == nil or views == nil then
		return
	end
	local ok, result = pcall(function()
		local pages = store:GetSortedAsync(false, BoardConfig.rows)
		local raw: { Raw } = {}
		for _, entry in pages:GetCurrentPage() do
			table.insert(raw, { key = tostring(entry.key), value = entry.value })
		end
		return raw
	end)
	if not ok then
		log.warn("board read failed", { category = category.id, error = tostring(result) })
		if not loaded[category.id] then
			showMessage(views, Strings.boards.unavailable)
		end
		return
	end

	loaded[category.id] = true
	local rows = GlobalBoard.rows(result, BoardConfig.rows)
	if #rows == 0 then
		showMessage(views, Strings.boards.empty)
		return
	end
	for index = 1, BoardConfig.rows do
		local row = rows[index]
		if row == nil then
			views.ranks[index].Text = ""
			views.names[index].Text = ""
			views.values[index].Text = ""
		else
			views.ranks[index].Text = tostring(row.rank)
			views.names[index].Text = nameFor(row.userId)
			views.values[index].Text = formatValue(category.id, row.value)
		end
	end
end

-- Writes the numbers of a player that changed since the last write.
local function writeNumbers(userId: number, numbers: { [string]: number })
	local last = lastWritten[userId]
	if last == nil then
		last = {}
		lastWritten[userId] = last
	end
	for _, category in BoardConfig.categories do
		local value = numbers[category.id] or 0
		local store = stores[category.id]
		if store ~= nil and GlobalBoard.shouldWrite(last[category.id], value) then
			local ok, err = pcall(function()
				store:SetAsync(tostring(userId), value)
			end)
			if ok then
				last[category.id] = value
				log.debug("board number written", { userId = userId, category = category.id, value = value })
			else
				log.warn("board write failed", { userId = userId, category = category.id, error = tostring(err) })
			end
		end
	end
end

local function numbersOf(data: any): { [string]: number }
	local numbers: { [string]: number } = {}
	for _, category in BoardConfig.categories do
		numbers[category.id] = GlobalBoard.valueFor(category.id, data, BoardConfig.maxValue)
	end
	return numbers
end

function LeaderboardService.start()
	for _, category in BoardConfig.categories do
		local ok, store = pcall(function()
			return DataStoreService:GetOrderedDataStore(storeNameFor(category))
		end)
		if ok then
			stores[category.id] = store
		else
			log.error("board store not available", { category = category.id, error = tostring(store) })
		end
	end

	local folder = Instance.new("Folder")
	folder.Name = "LeaderboardBoards"
	for index, category in BoardConfig.categories do
		local centerX = BoardConfig.board.centers[index]
		if centerX ~= nil then
			boards[category.id] = buildBoard(folder, category, centerX)
			showMessage(boards[category.id], Strings.boards.loading)
		end
	end
	folder.Parent = workspace

	-- A player who leaves is written one last time (the numbers are copied before the profile
	-- goes away, the write itself may wait for the DataStore).
	DataService.onLeaving(function(player: Player, data: any)
		local userId = player.UserId
		local numbers = numbersOf(data)
		task.spawn(writeNumbers, userId, numbers)
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		-- Keep the written numbers a little longer than the profile: the last write may still run.
		task.delay(BoardConfig.writeSeconds, function()
			lastWritten[player.UserId] = nil
		end)
	end)

	task.spawn(function()
		while true do
			for _, player in Players:GetPlayers() do
				local data = DataService.getData(player)
				if data ~= nil then
					writeNumbers(player.UserId, numbersOf(data))
					task.wait(BoardConfig.writeSpacingSeconds)
				end
			end
			task.wait(BoardConfig.writeSeconds)
		end
	end)

	task.spawn(function()
		while true do
			for _, category in BoardConfig.categories do
				local ok, err = pcall(refreshBoard, category)
				if not ok then
					log.error("board refresh failed", { category = category.id, error = tostring(err) })
				end
			end
			task.wait(BoardConfig.readSeconds)
		end
	end)

	log.info("started", { studio = RunService:IsStudio() })
end

return LeaderboardService
