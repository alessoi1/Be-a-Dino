--!strict
-- The menu bar in the lobby: round icon buttons at the right edge that open the shop, the dinodex
-- and the boosters without walking into the circles (tap again to close). Only in the lobby.
-- Only checkable in Roblox Studio.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log = require(Shared:WaitForChild("Log"))
local MenuBar = require(Shared:WaitForChild("MenuBar"))
local Strings = require(Shared:WaitForChild("Strings"))
local MenuConfig = require(Shared:WaitForChild("Config"):WaitForChild("Menu"))

local MenuState = require(script.Parent:WaitForChild("MenuState"))
local UiKit = require(script.Parent:WaitForChild("UiKit"))
local UiMetrics = require(script.Parent:WaitForChild("UiMetrics"))
local UiTheme = require(script.Parent:WaitForChild("UiTheme"))

-- Share of the button the icon fills, and of its height the label under the icon takes.
local ICON_SHARE = 0.5
local LABEL_SHARE = 0.26

local log = Log.new("MenuBar")

local MenuBarDisplay = {}

function MenuBarDisplay.start()
	local problems = MenuBar.validate(MenuConfig.entries)
	if #problems > 0 then
		log.error("menu config invalid, no menu bar", { problems = table.concat(problems, "; ") })
		return
	end

	local gui = UiKit.newGui("MenuBar")
	UiKit.showOnlyInMode(gui, "lobby")

	local buttons: { { id: string, button: TextButton } } = {}
	for _, entry in MenuConfig.entries do
		local button = Instance.new("TextButton")
		button.Name = "MenuButton_" .. entry.id
		button.AnchorPoint = Vector2.new(1, 0)
		button.Text = ""
		button.Parent = gui
		UiKit.styleBubble(button, UiTheme.lobbyButton)
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.25, 0)
		corner.Parent = button

		local icon = UiKit.newIcon(button, entry.icon, UDim2.fromScale(ICON_SHARE, ICON_SHARE))
		icon.AnchorPoint = Vector2.new(0.5, 0)
		icon.Position = UDim2.fromScale(0.5, 0.1)
		-- Taps go to the button, not to the icon.
		icon.Active = false

		local label = UiKit.newLabel(button, UiTheme.bodySize)
		label.AnchorPoint = Vector2.new(0.5, 1)
		label.Position = UDim2.fromScale(0.5, 0.97)
		label.Size = UDim2.fromScale(1, LABEL_SHARE)
		label.TextXAlignment = Enum.TextXAlignment.Center
		label.TextScaled = true
		label.Text = Strings.lobby.zones[entry.id] or entry.id

		button.Activated:Connect(function()
			MenuState.toggle(entry.id)
		end)
		table.insert(buttons, { id = entry.id, button = button })
	end

	-- The stack sits at the right edge, in the vertical middle.
	UiMetrics.watch(function()
		local scale = UiMetrics.scale()
		local size = UiMetrics.smallButtonSize()
		local gap = MenuConfig.gap * scale
		local total = #buttons * size + (#buttons - 1) * gap
		for index, entry in buttons do
			entry.button.Size = UDim2.fromOffset(size, size)
			entry.button.Position =
				UDim2.new(1, -MenuConfig.margin * scale, 0.5, -total / 2 + (index - 1) * (size + gap))
		end
	end)

	-- The open window's button is highlighted.
	local function refresh()
		local open = MenuState.get()
		for _, entry in buttons do
			entry.button.BackgroundColor3 = if open == entry.id then UiTheme.accent else UiTheme.lobbyButton
		end
	end
	MenuState.changed:Connect(refresh)
	refresh()
	log.info("started")
end

return MenuBarDisplay
