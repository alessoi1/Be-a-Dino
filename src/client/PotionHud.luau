--!strict
-- Small list of the running potions with the time left, in the arena below the coin counter.
-- Reads the `Potions` attribute the server publishes (display only). Only checkable in Roblox
-- Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Offers = require(Shared:WaitForChild("Offers"))
local Strings = require(Shared:WaitForChild("Strings"))
local TimeFormat = require(Shared:WaitForChild("TimeFormat"))
local OfferConfig = require(Shared:WaitForChild("Config"):WaitForChild("Offers"))

local UiKit = require(script.Parent:WaitForChild("UiKit"))
local UiTheme = require(script.Parent:WaitForChild("UiTheme"))

-- Base sizes in pixels.
local WIDTH = 210
local LINE_HEIGHT = 24
local PADDING = 8
-- Height of the coin counter above (see CoinDisplay).
local COIN_DISPLAY_HEIGHT = 36

local PotionHud = {}

function PotionHud.start()
	local player = Players.LocalPlayer
	local gui = UiKit.newGui("PotionHud")
	UiKit.showOnlyInMode(gui, "playing")

	local panel = UiKit.newPanel(gui)
	panel.Position = UDim2.fromOffset(
		UiTheme.margin,
		UiTheme.margin * 4 + UiTheme.statusPanelHeight + UiTheme.lobbyButtonHeight + COIN_DISPLAY_HEIGHT
	)
	panel.Visible = false
	UiKit.addScale(panel)

	local label = UiKit.newLabel(panel, UiTheme.bodySize)
	label.Position = UDim2.fromOffset(PADDING, PADDING / 2)
	label.TextColor3 = UiTheme.good
	label.TextYAlignment = Enum.TextYAlignment.Top

	local function refresh()
		local attribute = player:GetAttribute("Potions")
		local running = Offers.decodePotions(if typeof(attribute) == "string" then attribute else "")
		local lines: { string } = {}
		for _, potionId in OfferConfig.potionOrder do
			local left = running[potionId]
			if left ~= nil then
				table.insert(lines, Strings.potions.names[potionId] .. " " .. TimeFormat.compact(left))
			end
		end
		panel.Visible = #lines > 0
		label.Text = table.concat(lines, "\n")
		panel.Size = UDim2.fromOffset(WIDTH, #lines * LINE_HEIGHT + PADDING)
		label.Size = UDim2.new(1, -PADDING * 2, 1, -PADDING)
	end
	player:GetAttributeChangedSignal("Potions"):Connect(refresh)
	refresh()
end

return PotionHud
