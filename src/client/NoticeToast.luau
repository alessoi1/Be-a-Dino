--!strict
-- Shows one short message at a time: when the player eats someone, is eaten or turns
-- into the next dino. The server only sends the kind, the other name and the points
-- (and publishes the stage as attributes); display only. Only checkable in Roblox Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local NumberFormat = require(Shared:WaitForChild("NumberFormat"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Strings = require(Shared:WaitForChild("Strings"))
local Ui = require(Shared:WaitForChild("Config"):WaitForChild("Ui"))

local UiKit = require(script.Parent:WaitForChild("UiKit"))
local UiTheme = require(script.Parent:WaitForChild("UiTheme"))

local WIDTH = 320
local HEIGHT = 56
-- Vertical position as a share of the screen height (upper third, clear of the panels).
local TOP_SHARE = 0.22

local NoticeToast = {}

function NoticeToast.start()
	local player = Players.LocalPlayer
	local remote = Remotes.event(Remotes.names.notice)
	local gui = UiKit.newGui("NoticeToast")

	local box = UiKit.newPanel(gui)
	box.AnchorPoint = Vector2.new(0.5, 0)
	box.Position = UDim2.fromScale(0.5, TOP_SHARE)
	box.Size = UDim2.fromOffset(WIDTH, HEIGHT)
	box.Visible = false
	UiKit.addScale(box)

	local label = UiKit.newLabel(box, UiTheme.bodySize)
	label.Size = UDim2.fromScale(1, 1)
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextWrapped = true
	label.TextTruncate = Enum.TextTruncate.None

	-- Only the newest message is shown; an older timer must not hide it.
	local shown = 0
	local function show(text: string)
		shown += 1
		local mine = shown
		label.Text = text
		box.Visible = true
		task.delay(Ui.noticeSeconds, function()
			if shown == mine then
				box.Visible = false
			end
		end)
	end

	remote.OnClientEvent:Connect(function(kind: any, otherName: any, points: any, coins: any, bounty: any)
		if typeof(kind) ~= "string" or typeof(otherName) ~= "string" or typeof(points) ~= "number" then
			return
		end
		if kind == "ate" then
			if typeof(coins) == "number" and coins > 0 then
				local text = if bounty == true then Strings.notice.ateBounty else Strings.notice.ateCoins
				show(string.format(text, otherName, NumberFormat.compact(points), NumberFormat.compact(coins)))
			else
				show(string.format(Strings.notice.ate, otherName, NumberFormat.compact(points)))
			end
		elseif kind == "eaten" then
			show(string.format(Strings.notice.eaten, otherName))
		elseif kind == "revived" then
			show(Strings.notice.revived)
		elseif kind == "reviveFailed" then
			show(Strings.notice.reviveFailed)
		elseif kind == "bountyPlaced" then
			show(string.format(Strings.notice.bountyPlaced, otherName))
		elseif kind == "bountyFailed" then
			show(string.format(Strings.notice.bountyFailed, otherName))
		elseif kind == "potion" then
			show(string.format(Strings.notice.potion, Strings.potions.names[otherName] or otherName))
		elseif kind == "potionEnded" then
			show(string.format(Strings.notice.potionEnded, Strings.potions.names[otherName] or otherName))
		end
	end)

	-- The profile could not be loaded: tell the player once that nothing is saved.
	local function showGuest()
		if player:GetAttribute("DataGuest") == true then
			show(Strings.data.guest)
		end
	end
	player:GetAttributeChangedSignal("DataGuest"):Connect(showGuest)
	showGuest()

	-- Turning into a bigger dino (not the restart after being eaten, where the index drops).
	local lastIndex = player:GetAttribute("StageIndex")
	player:GetAttributeChangedSignal("StageIndex"):Connect(function()
		local index = player:GetAttribute("StageIndex")
		local stage = player:GetAttribute("Stage")
		if typeof(index) == "number" and typeof(lastIndex) == "number" and index > lastIndex then
			if typeof(stage) == "string" then
				show(string.format(Strings.notice.evolved, Strings.dinos[stage] or stage))
			end
		end
		lastIndex = index
	end)
end

return NoticeToast
