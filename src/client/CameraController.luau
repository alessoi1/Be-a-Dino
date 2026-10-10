--!strict
-- Keeps the camera distance in step with the size of the dino. Uses the default
-- Roblox camera (touch and mouse controls stay as they are) and pins its zoom range.
-- Display only: the client holds no game values. Only checkable in Roblox Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CameraRig = require(Shared:WaitForChild("CameraRig"))
local CameraConfig = require(Shared:WaitForChild("Config"):WaitForChild("Camera"))

local CameraController = {}

local function setZoom(player: Player, distance: number)
	-- Min must never exceed max, so the order depends on the direction.
	if distance > player.CameraMaxZoomDistance then
		player.CameraMaxZoomDistance = distance
		player.CameraMinZoomDistance = distance
	else
		player.CameraMinZoomDistance = distance
		player.CameraMaxZoomDistance = distance
	end
end

function CameraController.start()
	local player = Players.LocalPlayer
	local current = CameraRig.distanceFor(CameraConfig, 1)
	setZoom(player, current)

	RunService.RenderStepped:Connect(function(dt: number)
		local character = player.Character
		if character == nil then
			return
		end
		local target = CameraRig.distanceFor(CameraConfig, character:GetScale())
		current = CameraRig.smooth(CameraConfig, current, target, dt)
		setZoom(player, current)
	end)
end

return CameraController
