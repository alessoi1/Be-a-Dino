--!strict
-- Small coin counter at the top left, in the lobby and in the arena. In the arena it sits
-- below the status panel, in the lobby at the corner. Reads the `Coins` attribute the server
-- publishes (display only). Only checkable in Roblox Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local NumberFormat = require(Shared:WaitForChild("NumberFormat"))
local Strings = require(Shared:WaitForChild("Strings"))

local UiKit = require(script.Parent:WaitForChild("UiKit"))
local UiMetrics = require(script.Parent:WaitForChild("UiMetrics"))
local UiTheme = require(script.Parent:WaitForChild("UiTheme"))

-- Base sizes in pixels.
local WIDTH = 210
local HEIGHT = 36
local PADDING = 8
local ICON_SIZE = 24
local ICON_GAP = 4

local CoinDisplay = {}

function CoinDisplay.start()
	local player = Players.LocalPlayer
	local gui = UiKit.newGui("CoinDisplay")

	local panel = UiKit.newPanel(gui)
	panel.Size = UDim2.fromOffset(WIDTH, HEIGHT)
	UiKit.addScale(panel)

	local coinIcon = UiKit.newIcon(panel, "coin", UDim2.fromOffset(ICON_SIZE, ICON_SIZE))
	coinIcon.AnchorPoint = Vector2.new(0, 0.5)
	coinIcon.Position = UDim2.new(0, PADDING, 0.5, 0)

	local label = UiKit.newLabel(panel, UiTheme.bodySize)
	label.Position = UDim2.fromOffset(PADDING + ICON_SIZE + ICON_GAP, 0)
	label.Size = UDim2.new(1, -PADDING * 2 - ICON_SIZE - ICON_GAP, 1, 0)
	label.TextColor3 = UiTheme.own
	label.TextSize = UiTheme.titleSize

	local function refresh()
		local coins = player:GetAttribute("Coins")
		label.Text =
			string.format(Strings.coins.label, NumberFormat.compact(if typeof(coins) == "number" then coins else 0))

		-- Below the status panel in the arena, at the corner in the lobby.
		local top = UiTheme.margin
		if player:GetAttribute("Mode") == "playing" then
			-- Under the status panel and the lobby button (both grow with the screen scale).
			top = UiTheme.margin * 3 + (UiTheme.statusPanelHeight + UiTheme.lobbyButtonHeight) * UiMetrics.scale()
		end
		panel.Position = UDim2.fromOffset(UiTheme.margin, top)
	end
	UiMetrics.watch(refresh)

	player:GetAttributeChangedSignal("Coins"):Connect(refresh)
	player:GetAttributeChangedSignal("Mode"):Connect(refresh)
	refresh()
end

return CoinDisplay
