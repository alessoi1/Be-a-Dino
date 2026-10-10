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
local UiTheme = require(script.Parent:WaitForChild("UiTheme"))

-- Base sizes in pixels.
local WIDTH = 210
local HEIGHT = 36
local PADDING = 8

local CoinDisplay = {}

function CoinDisplay.start()
	local player = Players.LocalPlayer
	local gui = UiKit.newGui("CoinDisplay")

	local panel = UiKit.newPanel(gui)
	panel.Size = UDim2.fromOffset(WIDTH, HEIGHT)
	UiKit.addScale(panel)

	local label = UiKit.newLabel(panel, UiTheme.bodySize)
	label.Position = UDim2.fromOffset(PADDING, 0)
	label.Size = UDim2.new(1, -PADDING * 2, 1, 0)
	label.TextColor3 = UiTheme.own

	local function refresh()
		local coins = player:GetAttribute("Coins")
		label.Text =
			string.format(Strings.coins.label, NumberFormat.compact(if typeof(coins) == "number" then coins else 0))

		-- Below the status panel in the arena, at the corner in the lobby.
		local top = UiTheme.margin
		if player:GetAttribute("Mode") == "playing" then
			top = UiTheme.margin * 2 + UiTheme.statusPanelHeight
		end
		panel.Position = UDim2.fromOffset(UiTheme.margin, top)
	end

	player:GetAttributeChangedSignal("Coins"):Connect(refresh)
	player:GetAttributeChangedSignal("Mode"):Connect(refresh)
	refresh()
end

return CoinDisplay
