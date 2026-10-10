--!strict
-- Client entry point. Starts the interface; the client holds no game values.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log = require(Shared:WaitForChild("Log"))

local CameraController = require(script.Parent:WaitForChild("CameraController"))
local SprintControl = require(script.Parent:WaitForChild("SprintControl"))
local DebugInput = require(script.Parent:WaitForChild("DebugInput"))

local log = Log.new("Client")
log.info("client started")

CameraController.start()
SprintControl.start()
DebugInput.start()
