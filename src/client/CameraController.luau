--!strict
-- Keeps the camera distance in step with the size of the dino. Uses the default
-- Roblox camera (touch and mouse controls stay as they are) and pins its zoom range. While the
-- death window is open (the server publishes `DeathUntil`), the camera flies up and shows the
-- arena from above, turning slowly, so the player can watch the game while choosing.
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

-- The camera of the death window: from where the camera was to the view over the arena.
local function startDeathCamera(player: Player)
	local startCFrame: CFrame? = nil
	local elapsed = 0
	local active = false
	RunService:BindToRenderStep("BeDinoDeathCamera", Enum.RenderPriority.Camera.Value + 1, function(dt: number)
		local camera = workspace.CurrentCamera
		if camera == nil then
			return
		end
		local until_ = player:GetAttribute("DeathUntil")
		local dead = typeof(until_) == "number" and until_ > workspace:GetServerTimeNow()
		if not dead then
			if active then
				active = false
				camera.CameraType = Enum.CameraType.Custom
				local humanoid = if player.Character ~= nil
					then player.Character:FindFirstChildOfClass("Humanoid")
					else nil
				if humanoid ~= nil then
					camera.CameraSubject = humanoid
				end
			end
			return
		end
		if not active then
			active = true
			elapsed = 0
			startCFrame = camera.CFrame
			camera.CameraType = Enum.CameraType.Scriptable
		end
		elapsed += dt
		local x, y, z = CameraRig.deathView(CameraConfig, elapsed)
		local view = CFrame.lookAt(Vector3.new(x, y, z), Vector3.zero)
		local from = startCFrame or view
		camera.CFrame = from:Lerp(view, CameraRig.blend(CameraConfig, elapsed))
	end)
end

function CameraController.start()
	local player = Players.LocalPlayer
	local current = CameraRig.distanceFor(CameraConfig, 1)
	setZoom(player, current)
	startDeathCamera(player)

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
