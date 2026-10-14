--!strict
-- The lobby hints and the way back: in the lobby a hint says what to do (and counts down
-- while the player stands in the play circle); in the arena a button goes back to the lobby
-- after a short wait. The server decides everything and publishes the values as player
-- attributes. Only checkable in Roblox Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local Strings = require(Shared:WaitForChild("Strings"))

local MenuState = require(script.Parent:WaitForChild("MenuState"))
local UiKit = require(script.Parent:WaitForChild("UiKit"))
local UiMetrics = require(script.Parent:WaitForChild("UiMetrics"))
local UiTheme = require(script.Parent:WaitForChild("UiTheme"))

-- Base sizes in pixels.
local HINT_WIDTH = 460
local HINT_HEIGHT = 44
local HINT_BOTTOM = 24
-- The home icon in the leave button: size, gap to the text and distance to the left edge.
local LEAVE_ICON_SIZE = 30
local LEAVE_ICON_GAP = 4
local LEAVE_ICON_INSET = 8

local LobbyHud = {}

local function secondsLeft(value: any): number
	if typeof(value) ~= "number" then
		return 0
	end
	return value - workspace:GetServerTimeNow()
end

function LobbyHud.start()
	local player = Players.LocalPlayer
	local leaveRemote = Remotes.event(Remotes.names.leaveArena)
	local gui = UiKit.newGui("LobbyHud")

	local hint = UiKit.newLabel(gui, UiTheme.titleSize)
	hint.AnchorPoint = Vector2.new(0.5, 1)
	hint.Position = UDim2.new(0.5, 0, 1, -HINT_BOTTOM)
	hint.Size = UDim2.fromOffset(HINT_WIDTH, HINT_HEIGHT)
	hint.TextXAlignment = Enum.TextXAlignment.Center
	hint.Visible = false
	UiKit.addScale(hint)

	-- The way back sits under the status panel at the top left (only in the arena).
	local leave = Instance.new("TextButton")
	leave.Name = "LeaveButton"
	leave.AnchorPoint = Vector2.new(0, 0)
	leave.Size = UDim2.fromOffset(UiTheme.lobbyButtonWidth, UiTheme.lobbyButtonHeight)
	leave.FontFace = UiTheme.font
	leave.TextSize = UiTheme.bodySize
	leave.TextColor3 = UiTheme.text
	leave.TextStrokeTransparency = 0.2
	leave.TextStrokeColor3 = UiTheme.outline
	leave.Visible = false
	leave.Parent = gui
	UiKit.styleBubble(leave, UiTheme.lobbyButton)
	-- The text starts right of the home icon.
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, LEAVE_ICON_SIZE + LEAVE_ICON_GAP)
	padding.Parent = leave
	local homeIcon = UiKit.newIcon(leave, "lobby", UDim2.fromOffset(LEAVE_ICON_SIZE, LEAVE_ICON_SIZE))
	homeIcon.AnchorPoint = Vector2.new(0, 0.5)
	homeIcon.Position = UDim2.new(0, -(LEAVE_ICON_SIZE + LEAVE_ICON_GAP) + LEAVE_ICON_INSET, 0.5, 0)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.3, 0)
	corner.Parent = leave
	UiKit.addScale(leave)
	-- Under the status panel, which grows with the screen scale (a scaled panel keeps its offset).
	UiMetrics.watch(function()
		leave.Position =
			UDim2.fromOffset(UiTheme.margin, UiTheme.margin * 2 + UiTheme.statusPanelHeight * UiMetrics.scale())
	end)

	-- Tapping asks the server to start the wait, or to cancel it while it runs.
	leave.Activated:Connect(function()
		local waiting = secondsLeft(player:GetAttribute("LeaveAt")) > 0
		leaveRemote:FireServer(not waiting)
	end)

	RunService.RenderStepped:Connect(function()
		local mode = player:GetAttribute("Mode")
		local zone = player:GetAttribute("ZoneId")

		if mode == "lobby" then
			leave.Visible = false
			-- No hint while any window is open (shop, dinodex, boosters, daily gift, quests).
			local windowOpen = zone == "shop"
				or zone == "dex"
				or zone == "boost"
				or MenuState.get() ~= nil
				or MenuState.overlayOpen()
			hint.Visible = not windowOpen
			if zone == "play" and player:GetAttribute("ArenaFull") == true then
				hint.Text = UiKit.withIcon("locked", Strings.lobby.full)
			elseif zone == "play" and secondsLeft(player:GetAttribute("ZoneUntil")) > 0 then
				hint.Text = UiKit.withIcon(
					"timer",
					string.format(Strings.lobby.entering, math.ceil(secondsLeft(player:GetAttribute("ZoneUntil"))))
				)
			else
				hint.Text = UiKit.withIcon("step", Strings.lobby.hint)
			end
		elseif mode == "playing" then
			hint.Visible = false
			leave.Visible = true
			local left = secondsLeft(player:GetAttribute("LeaveAt"))
			if left > 0 then
				-- Only the seconds; tapping again cancels.
				leave.Text = tostring(math.ceil(left))
			else
				leave.Text = ""
			end
		else
			hint.Visible = false
			leave.Visible = false
		end
	end)
end

return LobbyHud
