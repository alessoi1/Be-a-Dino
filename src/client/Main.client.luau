--!strict
-- Client entry point. Starts the interface; the client holds no game values.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log = require(Shared:WaitForChild("Log"))

local log = Log.new("Client")
log.info("client started")
