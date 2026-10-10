--!strict
-- Server entry point. Starts the services and checks the config (log on errors).
-- Only checkable in Roblox Studio.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log = require(Shared:WaitForChild("Log"))
local Movement = require(Shared:WaitForChild("Config"):WaitForChild("Movement"))

local RejectLimiter = require(script.Parent:WaitForChild("RejectLimiter"))
local ServerClock = require(script.Parent:WaitForChild("ServerClock"))
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local ArenaService = require(script.Parent:WaitForChild("ArenaService"))
local MovementService = require(script.Parent:WaitForChild("MovementService"))
local AppearanceService = require(script.Parent:WaitForChild("AppearanceService"))
local PlayerCollision = require(script.Parent:WaitForChild("PlayerCollision"))
local EatingService = require(script.Parent:WaitForChild("EatingService"))
local FoodService = require(script.Parent:WaitForChild("FoodService"))
local DebugService = require(script.Parent:WaitForChild("DebugService"))

local log = Log.new("Main")
log.info("server started")

local limiter = RejectLimiter.new(Log.new("Remotes"), Movement.rejectLogIntervalSeconds, ServerClock.now)

-- PlayerState first: it must know a player before the other services react to them.
PlayerState.start()
ArenaService.start()
AppearanceService.start()
MovementService.start(limiter)
FoodService.start()
PlayerCollision.start()
EatingService.start()
DebugService.start(limiter)
