--!strict
-- Shows one short message at a time when the player eats someone or is eaten.
-- The server only sends the kind, the other name and the points; display only.
-- Only checkable in Roblox Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local Strings = require(Shared:WaitForChild("Strings"))

local SHOW_SECONDS = 3
local TOP = 64
local WIDTH = 0.7
local MAX_WIDTH = 420
local HEIGHT = 36

local NoticeToast = {}

function NoticeToast.start()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local remote = Remotes.event(Remotes.names.notice)

	local gui = Instance.new("ScreenGui")
	gui.Name = "NoticeToast"
	gui.ResetOnSpawn = false
	gui.Parent = playerGui

	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Position = UDim2.new(0.5, 0, 0, TOP)
	label.Size = UDim2.new(WIDTH, 0, 0, HEIGHT)
	label.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	label.BackgroundTransparency = 0.35
	label.BorderSizePixel = 0
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Visible = false
	label.Parent = gui
	local constraint = Instance.new("UISizeConstraint")
	constraint.MaxSize = Vector2.new(MAX_WIDTH, HEIGHT)
	constraint.Parent = label
	local corner = Instance.new("UICorner")
	corner.Parent = label

	-- Only the newest message is shown; an older timer must not hide it.
	local shown = 0

	remote.OnClientEvent:Connect(function(kind: any, otherName: any, points: any)
		if typeof(kind) ~= "string" or typeof(otherName) ~= "string" or typeof(points) ~= "number" then
			return
		end
		local text: string
		if kind == "ate" then
			text = string.format(Strings.notice.ate, otherName, points)
		elseif kind == "eaten" then
			text = string.format(Strings.notice.eaten, otherName)
		else
			return
		end
		shown += 1
		local mine = shown
		label.Text = text
		label.Visible = true
		task.delay(SHOW_SECONDS, function()
			if shown == mine then
				label.Visible = false
			end
		end)
	end)
end

return NoticeToast
