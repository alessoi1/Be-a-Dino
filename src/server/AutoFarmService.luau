--!strict
-- The autofarm switch: the player asks to turn it on or off, the server decides. It works only in
-- the arena, ends after a few minutes (the player taps again to continue) and ends when the
-- player dies, leaves or starts a new round. The server publishes the result as the player
-- attributes `AutoFarm` and `AutoFarmEndsAt`; the client walks only while `AutoFarm` is true. The
-- walking itself is the client's (it owns the character), and all server rules (speed check,
-- food pickup, coins) apply as for any player. Autofarm time counts like playing time.
-- Only checkable in Roblox Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AutoFarm = require(Shared:WaitForChild("AutoFarm"))
local Log = require(Shared:WaitForChild("Log"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local AutoFarmConfig = require(Shared:WaitForChild("Config"):WaitForChild("AutoFarm"))

local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local ServerClock = require(script.Parent:WaitForChild("ServerClock"))

type Limiter = { reject: (userId: number, remote: string, reason: string) -> (), forget: (userId: number) -> () }

-- Minimum seconds between two requests of one player.
local MIN_INTERVAL = 0.3
-- Seconds between two checks for sessions that ran out.
local SWEEP_INTERVAL = 1

local log = Log.new("AutoFarmService")

-- Server time at which the session of a player started.
local startedAt: { [Player]: number } = {}
local lastRequest: { [Player]: number } = {}

local AutoFarmService = {}

local function publish(player: Player)
	local started = startedAt[player]
	player:SetAttribute("AutoFarm", started ~= nil)
	player:SetAttribute("AutoFarmEndsAt", if started ~= nil then started + AutoFarmConfig.maxSessionSeconds else 0)
end

local function stop(player: Player, reason: string)
	if startedAt[player] == nil then
		return
	end
	startedAt[player] = nil
	publish(player)
	log.info("autofarm stopped", { userId = player.UserId, reason = reason })
end

function AutoFarmService.isActive(player: Player): boolean
	return startedAt[player] ~= nil
end

local function onRequest(player: Player, active: any, limiter: Limiter)
	local userId = player.UserId
	if type(active) ~= "boolean" then
		limiter.reject(userId, "AutoFarm", "bad_type")
		return
	end
	local now = ServerClock.now()
	local last = lastRequest[player]
	if last ~= nil and now - last < MIN_INTERVAL then
		limiter.reject(userId, "AutoFarm", "rate_limited")
		return
	end
	lastRequest[player] = now

	if not active then
		stop(player, "player")
		return
	end
	if PlayerState.getMode(player) ~= "playing" then
		limiter.reject(userId, "AutoFarm", "not_playing")
		return
	end
	if startedAt[player] == nil then
		startedAt[player] = now
		publish(player)
		log.info("autofarm started", { userId = userId })
	end
end

function AutoFarmService.start(limiter: Limiter)
	Remotes.event(Remotes.names.autoFarm).OnServerEvent:Connect(function(player: Player, active: any)
		onRequest(player, active, limiter)
	end)

	-- A new round, going back to the lobby or a new character ends the session.
	PlayerState.onStage(function(player: Player, _stageId: string, reason: string)
		if reason == "round" or reason == "reset" then
			stop(player, reason)
		end
	end)

	local function onPlayerAdded(player: Player)
		publish(player)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	Players.PlayerRemoving:Connect(function(player: Player)
		startedAt[player] = nil
		lastRequest[player] = nil
	end)

	local lastSweep = ServerClock.now()
	RunService.Heartbeat:Connect(function()
		local now = ServerClock.now()
		if now - lastSweep < SWEEP_INTERVAL then
			return
		end
		lastSweep = now
		for player, started in startedAt do
			if not AutoFarm.sessionActive(started, now, AutoFarmConfig.maxSessionSeconds) then
				stop(player, "time_over")
			end
		end
	end)

	log.info("started")
end

return AutoFarmService
