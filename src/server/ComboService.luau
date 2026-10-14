--!strict
-- The eating combo of the players: every piece of food eaten within a few seconds of the last one
-- raises a count that is published as player attributes (`ComboCount`, `ComboUntil` in server time)
-- for the display. It gives no points or coins (see Config/Combo). Only checkable in Roblox Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Combo = require(Shared:WaitForChild("Combo"))
local ComboConfig = require(Shared:WaitForChild("Config"):WaitForChild("Combo"))

local states: { [Player]: Combo.State } = {}

local ComboService = {}

-- A piece of food was eaten by the player at server time `now`.
function ComboService.hit(player: Player, now: number)
	local state = Combo.bump(states[player], now, ComboConfig.windowSeconds)
	states[player] = state
	player:SetAttribute("ComboCount", state.count)
	player:SetAttribute("ComboUntil", now + ComboConfig.windowSeconds)
end

-- Ends the combo at once (the player died or left the arena).
function ComboService.reset(player: Player)
	states[player] = nil
	player:SetAttribute("ComboCount", 0)
end

function ComboService.start()
	Players.PlayerRemoving:Connect(function(player: Player)
		states[player] = nil
	end)
end

return ComboService
