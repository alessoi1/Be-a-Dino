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
local Arena = require(Shared:WaitForChild("Config"):WaitForChild("Arena"))
local GrowthConfig = require(Shared:WaitForChild("Config"):WaitForChild("Growth"))

local ServerClock = require(script.Parent:WaitForChild("ServerClock"))

type GrowthState = { points: number, stageIndex: number, highestStageIndex: number }

local log = Log.new("PlayerState")

type StageHandler = (player: Player, stageId: string, reason: "reset" | "grow") -> ()
type PointsHandler = (player: Player, state: GrowthState) -> ()

local states: { [number]: GrowthState } = {}
local stageHandlers: { StageHandler } = {}
local pointsHandlers: { PointsHandler } = {}
-- Server time until which a player cannot be eaten (set at every respawn).
local protectedUntil: { [number]: number } = {}
-- The scale last applied to the character, to skip tiny rescales.
local appliedScale: { [number]: number } = {}

local PlayerState = {}

local function notifyStage(player: Player, stageId: string, reason: "reset" | "grow")
	for _, handler in stageHandlers do
		local ok, err = pcall(handler, player, stageId, reason)
		if not ok then
			log.error("stage handler failed", { userId = player.UserId, error = tostring(err) })
		end
	end
end

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

-- Display values for the client (read only there; the server is the only writer).
local function publish(player: Player, state: GrowthState)
	player:SetAttribute("Points", math.floor(state.points))
	player:SetAttribute("Stage", Dinos[state.stageIndex].id)
	player:SetAttribute("StageIndex", state.stageIndex)
	player:SetAttribute("StageProgress", math.floor(Growth.progress(Dinos, state) * 100) / 100)
	player:SetAttribute("Scale", math.floor(Growth.scaleFor(Dinos, state) * 100) / 100)
	local nextIndex, missing = Growth.pointsToNext(Dinos, state)
	player:SetAttribute("NextStage", if nextIndex ~= nil then Dinos[nextIndex].id else "")
	player:SetAttribute("PointsToNext", missing)
end

-- Registers a handler that is called with the new stage id when a player turns into
-- another dino ("grow") and when the state starts over ("reset", also without a character yet).
function PlayerState.onStage(handler: StageHandler)
	table.insert(stageHandlers, handler)
end

-- Registers a handler that is called with the new state after every change of the points.
-- It runs often (every piece of food), so it must be cheap.
function PlayerState.onPoints(handler: PointsHandler)
	table.insert(pointsHandlers, handler)
end

function PlayerState.get(player: Player): GrowthState?
	return states[player.UserId]
end

function PlayerState.protectedUntil(player: Player): number
	return protectedUntil[player.UserId] or 0
end

-- Current scale from the growth state (not from the character, which the client moves).
function PlayerState.scaleOf(player: Player): number
	local state = states[player.UserId]
	if state == nil then
		return Dinos[1].scale
	end
	return Growth.scaleFor(Dinos, state)
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
	publish(player, newState)
	for _, handler in pointsHandlers do
		local ok, err = pcall(handler, player, newState)
		if not ok then
			log.error("points handler failed", { userId = player.UserId, error = tostring(err) })
		end
	end
	local scale = Growth.scaleFor(Dinos, newState)
	local scaleStepped = math.abs(scale - (appliedScale[player.UserId] or 1)) >= GrowthConfig.scaleApplyStep
	if changed or scaleStepped then
		appliedScale[player.UserId] = scale
		applyScale(player, newState)
	end
	if changed then
		notifyStage(player, Dinos[newState.stageIndex].id, "grow")
		log.info(
			"stage changed",
			{ userId = player.UserId, stage = Dinos[newState.stageIndex].id, points = newState.points }
		)
	end
end

local function reset(player: Player)
	local state = Growth.newState()
	states[player.UserId] = state
	appliedScale[player.UserId] = Growth.scaleFor(Dinos, state)
	protectedUntil[player.UserId] = ServerClock.now() + Arena.spawnProtectionSeconds
	publish(player, state)
	-- The respawn countdown (set when eaten) is over once the state starts over.
	player:SetAttribute("RespawnAt", 0)
	notifyStage(player, Dinos[state.stageIndex].id, "reset")
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
		protectedUntil[player.UserId] = nil
		appliedScale[player.UserId] = nil
	end)
	log.info("started")
end

return PlayerState
