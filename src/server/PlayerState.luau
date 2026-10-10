--!strict
-- Holds the growth state of every player in memory (server authority) and applies
-- the dino scale to the character. A new character always starts as the smallest dino.
-- Only checkable in Roblox Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log = require(Shared:WaitForChild("Log"))
local Growth = require(Shared:WaitForChild("Growth"))
local Dinos = require(Shared:WaitForChild("Config"):WaitForChild("Dinos"))

type GrowthState = { points: number, stageIndex: number, highestStageIndex: number }

local log = Log.new("PlayerState")

local states: { [number]: GrowthState } = {}

local PlayerState = {}

local function applyScale(player: Player, state: GrowthState)
	local character = player.Character
	if character == nil then
		return
	end
	local ok, err = pcall(function()
		character:ScaleTo(Growth.scaleFor(Dinos, state))
	end)
	if not ok then
		log.error("scale failed", { userId = player.UserId, error = tostring(err) })
	end
end

function PlayerState.get(player: Player): GrowthState?
	return states[player.UserId]
end

-- Speed of the current dino stage (without sprint).
function PlayerState.speedFor(player: Player): number
	local state = states[player.UserId]
	if state == nil then
		return Dinos[1].speed
	end
	return Growth.speedFor(Dinos, state)
end

function PlayerState.addPoints(player: Player, amount: number)
	local state = states[player.UserId]
	if state == nil then
		log.warn("addPoints without state", { userId = player.UserId })
		return
	end
	local newState, changed = Growth.addPoints(Dinos, state, amount)
	states[player.UserId] = newState
	log.debug("points added", { userId = player.UserId, amount = amount, points = newState.points })
	if changed then
		applyScale(player, newState)
		log.info(
			"stage changed",
			{ userId = player.UserId, stage = Dinos[newState.stageIndex].id, points = newState.points }
		)
	end
end

local function reset(player: Player)
	states[player.UserId] = Growth.newState()
	log.info("state reset", { userId = player.UserId })
end

local function onPlayerAdded(player: Player)
	log.info("player joined", { userId = player.UserId })
	reset(player)
	player.CharacterAdded:Connect(function()
		-- A fresh character has scale 1 already, so only the state is reset.
		reset(player)
	end)
end

function PlayerState.start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	Players.PlayerRemoving:Connect(function(player: Player)
		log.info("player left", { userId = player.UserId })
		states[player.UserId] = nil
	end)
	log.info("started")
end

return PlayerState
