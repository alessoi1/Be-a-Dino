--!strict
-- Studio-only helper: lets a tester grow without food (until step 3 exists).
-- Does nothing on live servers, the remote is not even created there.
-- Only checkable in Roblox Studio.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log = require(Shared:WaitForChild("Log"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Progression = require(Shared:WaitForChild("Progression"))
local DebugConfig = require(Shared:WaitForChild("Config"):WaitForChild("Debug"))
local Dinos = require(Shared:WaitForChild("Config"):WaitForChild("Dinos"))

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
	local remote = Remotes.event(Remotes.names.debugGrow)
	remote.OnServerEvent:Connect(function(player: Player)
		local now = ServerClock.now()
		local previous = lastCall[player.UserId]
		if previous ~= nil and now - previous < MIN_INTERVAL then
			limiter.reject(player.UserId, "DebugGrow", "rate_limited")
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
		local points = Progression.pointsForFraction(Dinos, state, DebugConfig.growFraction)
		PlayerState.addPoints(player, points)
		log.info("debug grow", { userId = player.UserId, points = points })
	end)
	log.warn("studio debug helper is active")
end

return DebugService
