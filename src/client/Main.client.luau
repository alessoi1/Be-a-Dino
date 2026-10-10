--!strict
-- Client entry point. Starts the interface; the client holds no game values.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log = require(Shared:WaitForChild("Log"))

local CameraController = require(script.Parent:WaitForChild("CameraController"))
local CoreGuiSetup = require(script.Parent:WaitForChild("CoreGuiSetup"))
local SprintControl = require(script.Parent:WaitForChild("SprintControl"))
local StatusDisplay = require(script.Parent:WaitForChild("StatusDisplay"))
local LeaderboardDisplay = require(script.Parent:WaitForChild("LeaderboardDisplay"))
local CollectionMenu = require(script.Parent:WaitForChild("CollectionMenu"))
local NoticeToast = require(script.Parent:WaitForChild("NoticeToast"))
local RespawnCountdown = require(script.Parent:WaitForChild("RespawnCountdown"))
local DebugInput = require(script.Parent:WaitForChild("DebugInput"))

local log = Log.new("Client")
log.info("client started")

CoreGuiSetup.start()
CameraController.start()
SprintControl.start()
StatusDisplay.start()
LeaderboardDisplay.start()
CollectionMenu.start()
NoticeToast.start()
RespawnCountdown.start()
DebugInput.start()
