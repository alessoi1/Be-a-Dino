--!strict
-- Client entry point. Starts the interface; the client holds no game values.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log = require(Shared:WaitForChild("Log"))

local CameraController = require(script.Parent:WaitForChild("CameraController"))
local SprintControl = require(script.Parent:WaitForChild("SprintControl"))
local StatusDisplay = require(script.Parent:WaitForChild("StatusDisplay"))
local NoticeToast = require(script.Parent:WaitForChild("NoticeToast"))
local DebugInput = require(script.Parent:WaitForChild("DebugInput"))

local log = Log.new("Client")
log.info("client started")

CameraController.start()
SprintControl.start()
StatusDisplay.start()
NoticeToast.start()
DebugInput.start()
