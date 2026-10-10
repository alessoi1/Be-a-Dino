--!strict
-- Studio-only helper: lets a tester grow without food (until step 3 exists).
-- Does nothing on live servers, the remote is not even created there.
-- Only checkable in Roblox Studio.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log = require(Shared:WaitForChild("Log"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local DebugConfig = require(Shared:WaitForChild("Config"):WaitForChild("Debug"))

local PlayerState = require(script.Parent:WaitForChild("PlayerState"))

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
		local now = os.clock()
		local previous = lastCall[player.UserId]
		if previous ~= nil and now - previous < MIN_INTERVAL then
			limiter.reject(player.UserId, "DebugGrow", "rate_limited")
			return
		end
		lastCall[player.UserId] = now
		PlayerState.addPoints(player, DebugConfig.growPoints)
		log.info("debug grow", { userId = player.UserId, points = DebugConfig.growPoints })
	end)
	log.warn("studio debug helper is active")
end

return DebugService
