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

local UiKit = require(script.Parent:WaitForChild("UiKit"))
local UiTheme = require(script.Parent:WaitForChild("UiTheme"))

-- Base sizes in pixels.
local HINT_WIDTH = 420
local HINT_HEIGHT = 40
local HINT_BOTTOM = 24
local LEAVE_WIDTH = 240
local LEAVE_HEIGHT = 60
-- Lifts the button above the stamina bar at the bottom center.
local LEAVE_BOTTOM = 70
-- The home icon in the leave button: size, gap to the text and distance to the left edge.
local LEAVE_ICON_SIZE = 30
local LEAVE_ICON_GAP = 6
local LEAVE_ICON_INSET = 14

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

	local leave = Instance.new("TextButton")
	leave.Name = "LeaveButton"
	leave.AnchorPoint = Vector2.new(0.5, 1)
	leave.Position = UDim2.new(0.5, 0, 1, -LEAVE_BOTTOM)
	leave.Size = UDim2.fromOffset(LEAVE_WIDTH, LEAVE_HEIGHT)
	leave.FontFace = UiTheme.font
	leave.TextSize = UiTheme.bodySize
	leave.TextColor3 = UiTheme.text
	leave.BackgroundColor3 = UiTheme.panel
	leave.BackgroundTransparency = UiTheme.panelTransparency
	leave.AutoButtonColor = true
	leave.Visible = false
	leave.Parent = gui
	-- The text starts right of the home icon.
	leave.TextXAlignment = Enum.TextXAlignment.Center
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, LEAVE_ICON_SIZE + LEAVE_ICON_GAP)
	padding.Parent = leave
	local homeIcon = UiKit.newIcon(leave, "lobby", UDim2.fromOffset(LEAVE_ICON_SIZE, LEAVE_ICON_SIZE))
	homeIcon.AnchorPoint = Vector2.new(0, 0.5)
	homeIcon.Position = UDim2.new(0, -(LEAVE_ICON_SIZE + LEAVE_ICON_GAP) + LEAVE_ICON_INSET, 0.5, 0)
	local corner = Instance.new("UICorner")
	corner.Parent = leave
	UiKit.addScale(leave)

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
			-- No hint while a window is open (shop, dinodex, boosters).
			local windowOpen = zone == "shop" or zone == "dex" or zone == "boost"
			hint.Visible = not windowOpen
			if zone == "play" and player:GetAttribute("ArenaFull") == true then
				hint.Text = Strings.lobby.full
			elseif zone == "play" and secondsLeft(player:GetAttribute("ZoneUntil")) > 0 then
				hint.Text =
					string.format(Strings.lobby.entering, math.ceil(secondsLeft(player:GetAttribute("ZoneUntil"))))
			else
				hint.Text = Strings.lobby.hint
			end
		elseif mode == "playing" then
			hint.Visible = false
			leave.Visible = true
			local left = secondsLeft(player:GetAttribute("LeaveAt"))
			if left > 0 then
				leave.Text = string.format(Strings.lobby.leaving, math.ceil(left))
			else
				leave.Text = Strings.lobby.leave
			end
		else
			hint.Visible = false
			leave.Visible = false
		end
	end)
end

return LobbyHud
