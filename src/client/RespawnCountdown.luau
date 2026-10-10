--!strict
-- Big countdown in the middle of the screen while the player waits to respawn.
-- The server publishes the server time of the respawn (display only).
-- Only checkable in Roblox Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Strings = require(Shared:WaitForChild("Strings"))

local UiKit = require(script.Parent:WaitForChild("UiKit"))
local UiTheme = require(script.Parent:WaitForChild("UiTheme"))

local WIDTH = 320
local HEIGHT = 64
local TEXT_SIZE = 32

local RespawnCountdown = {}

function RespawnCountdown.start()
	local player = Players.LocalPlayer
	local gui = UiKit.newGui("RespawnCountdown")

	local label = UiKit.newLabel(gui, TEXT_SIZE)
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.45)
	label.Size = UDim2.fromOffset(WIDTH, HEIGHT)
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextColor3 = UiTheme.own
	label.Visible = false
	UiKit.addScale(label)

	RunService.RenderStepped:Connect(function()
		local respawnAt = player:GetAttribute("RespawnAt")
		local remaining = if typeof(respawnAt) == "number" then respawnAt - workspace:GetServerTimeNow() else 0
		if remaining > 0 then
			label.Text = string.format(Strings.respawn.countdown, math.ceil(remaining))
			label.Visible = true
		else
			label.Visible = false
		end
	end)
end

return RespawnCountdown
