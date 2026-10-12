--!strict
-- Studio-only helper: lets a tester grow without food (G: a bit, H: straight to the next dino).
-- Does nothing on live servers, the remote is not even created there.
-- Only checkable in Roblox Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Growth = require(Shared:WaitForChild("Growth"))
local Log = require(Shared:WaitForChild("Log"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Progression = require(Shared:WaitForChild("Progression"))
local DebugConfig = require(Shared:WaitForChild("Config"):WaitForChild("Debug"))
local Dinos = require(Shared:WaitForChild("Config"):WaitForChild("Dinos"))

local BountyService = require(script.Parent:WaitForChild("BountyService"))
local VariantService = require(script.Parent:WaitForChild("VariantService"))
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local ServerClock = require(script.Parent:WaitForChild("ServerClock"))

type Limiter = { reject: (userId: number, remote: string, reason: string) -> (), forget: (userId: number) -> () }

-- Seconds between two accepted debug calls per player.
local MIN_INTERVAL = 0.2

local log = Log.new("DebugService")

local DebugService = {}

function DebugService.start(limiter: Limiter)
	if not RunService:IsStudio() then
		return
	end
	local lastCall: { [number]: number } = {}

	-- Both keys share the limit and the checks; `pointsFor` says how much to add.
	local function connect(remoteName: string, label: string, pointsFor: (state: any) -> number)
		Remotes.event(remoteName).OnServerEvent:Connect(function(player: Player)
			local now = ServerClock.now()
			local previous = lastCall[player.UserId]
			if previous ~= nil and now - previous < MIN_INTERVAL then
				limiter.reject(player.UserId, label, "rate_limited")
				return
			end
			lastCall[player.UserId] = now
			if PlayerState.getMode(player) ~= "playing" then
				return
			end
			local state = PlayerState.get(player)
			if state == nil then
				return
			end
			local points = pointsFor(state)
			if points <= 0 then
				return
			end
			PlayerState.addPoints(player, points)
			log.info("debug grow", { userId = player.UserId, key = label, points = points })
		end)
	end

	connect(Remotes.names.debugGrow, "DebugGrow", function(state: any): number
		return Progression.pointsForFraction(Dinos, state, DebugConfig.growFraction)
	end)
	connect(Remotes.names.debugNextStage, "DebugNextStage", function(state: any): number
		local _, missing = Growth.pointsToNext(Dinos, state)
		return missing
	end)

	-- B: puts a bounty on every other player in the arena (to test the bounty without Robux).
	Remotes.event(Remotes.names.debugBounty).OnServerEvent:Connect(function(player: Player)
		local now = ServerClock.now()
		local previous = lastCall[player.UserId]
		if previous ~= nil and now - previous < MIN_INTERVAL then
			limiter.reject(player.UserId, "DebugBounty", "rate_limited")
			return
		end
		lastCall[player.UserId] = now
		if PlayerState.getMode(player) ~= "playing" then
			return
		end
		for _, other in Players:GetPlayers() do
			if other ~= player and PlayerState.getMode(other) == "playing" then
				BountyService.place(other)
			end
		end
	end)

	-- V: gives a variant of the dino the player is now and shows it (to test the looks).
	Remotes.event(Remotes.names.debugVariant).OnServerEvent:Connect(function(player: Player)
		local now = ServerClock.now()
		local previous = lastCall[player.UserId]
		if previous ~= nil and now - previous < MIN_INTERVAL then
			limiter.reject(player.UserId, "DebugVariant", "rate_limited")
			return
		end
		lastCall[player.UserId] = now
		if PlayerState.getMode(player) ~= "playing" then
			return
		end
		VariantService.debugGrant(player)
	end)
	log.warn("studio debug helper is active")
end

return DebugService
