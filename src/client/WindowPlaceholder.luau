--!strict
-- Simple "coming soon" windows for the shop and the boosters. Each one is open while the
-- player stands in its circle in the lobby (the server publishes the zone). They get their
-- real content in later steps. Only checkable in Roblox Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Strings = require(Shared:WaitForChild("Strings"))

local UiKit = require(script.Parent:WaitForChild("UiKit"))
local UiTheme = require(script.Parent:WaitForChild("UiTheme"))

-- Base sizes in pixels.
local WINDOW_WIDTH = 320
local WINDOW_HEIGHT = 180
local PADDING = 12
local TITLE_HEIGHT = 40
local TEXT_HEIGHT = 30

local WindowPlaceholder = {}

local function create(gui: ScreenGui, zoneId: string, titleText: string)
	local player = Players.LocalPlayer

	local window = UiKit.newPanel(gui)
	window.Name = "Window_" .. zoneId
	window.AnchorPoint = Vector2.new(0.5, 0.5)
	window.Position = UDim2.fromScale(0.5, 0.5)
	window.Size = UDim2.fromOffset(WINDOW_WIDTH, WINDOW_HEIGHT)
	window.Visible = false
	UiKit.addScale(window)

	local title = UiKit.newLabel(window, UiTheme.titleSize)
	title.Text = titleText
	title.Position = UDim2.fromOffset(PADDING, PADDING)
	title.Size = UDim2.new(1, -PADDING * 2, 0, TITLE_HEIGHT)

	local text = UiKit.newLabel(window, UiTheme.bodySize)
	text.Text = Strings.lobby.comingSoon
	text.TextColor3 = UiTheme.lockedText
	text.Position = UDim2.fromOffset(PADDING, PADDING * 2 + TITLE_HEIGHT)
	text.Size = UDim2.new(1, -PADDING * 2, 0, TEXT_HEIGHT)

	local function applyZone()
		window.Visible = player:GetAttribute("ZoneId") == zoneId
	end
	player:GetAttributeChangedSignal("ZoneId"):Connect(applyZone)
	applyZone()
end

function WindowPlaceholder.start()
	local gui = UiKit.newGui("LobbyWindows")
	create(gui, "shop", Strings.lobby.shopTitle)
	create(gui, "boost", Strings.lobby.boostTitle)
end

return WindowPlaceholder
