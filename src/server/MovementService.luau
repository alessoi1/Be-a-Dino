--!strict
-- Server-side movement: sprint intention from the client, stamina, walk speed and
-- the plausibility check of the position (rubberband on teleport or speed hacks).
-- The client only says "sprint held or not"; everything else is decided here.
-- Only checkable in Roblox Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log = require(Shared:WaitForChild("Log"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Stamina = require(Shared:WaitForChild("Stamina"))
local MoveCheck = require(Shared:WaitForChild("MoveCheck"))
local Movement = require(Shared:WaitForChild("Config"):WaitForChild("Movement"))

local OfferService = require(script.Parent:WaitForChild("OfferService"))
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local ServerClock = require(script.Parent:WaitForChild("ServerClock"))

type Point = { x: number, z: number }
type StaminaState = { value: number, idle: number, sprinting: boolean }
type Limiter = { reject: (userId: number, remote: string, reason: string) -> (), forget: (userId: number) -> () }

type PlayerData = {
	stamina: StaminaState,
	wantsSprint: boolean,
	lastSprintCall: number,
	character: Model?,
	lastPos: Point?,
	lastSpeed: number,
	sentFraction: number,
	lastRubberbandLog: number,
}

local log = Log.new("MovementService")

local datas: { [number]: PlayerData } = {}

local MovementService = {}

local function newData(): PlayerData
	return {
		stamina = Stamina.new(Movement),
		wantsSprint = false,
		lastSprintCall = 0,
		character = nil,
		lastPos = nil,
		lastSpeed = 0,
		sentFraction = 1,
		lastRubberbandLog = -math.huge,
	}
end

local function prepareCharacter(humanoid: Humanoid)
	-- The arena is flat and the position check works on the ground plane, so no jumping.
	humanoid.UseJumpPower = true
	humanoid.JumpPower = 0
end

local function rubberband(player: Player, data: PlayerData, root: BasePart, current: Point, dt: number)
	local last = data.lastPos
	if last == nil then
		-- Invalid position and nowhere to go back to: reset the character.
		log.error("invalid position without fallback", { userId = player.UserId })
		local humanoid = root.Parent and root.Parent:FindFirstChildOfClass("Humanoid")
		if humanoid ~= nil then
			humanoid.Health = 0
		end
		return
	end
	root.AssemblyLinearVelocity = Vector3.zero
	root.CFrame = CFrame.new(last.x, root.Position.Y, last.z) * (root.CFrame - root.CFrame.Position)

	local now = ServerClock.now()
	if now - data.lastRubberbandLog >= Movement.rejectLogIntervalSeconds then
		data.lastRubberbandLog = now
		log.warn("movement rejected", {
			userId = player.UserId,
			reason = "too_fast",
			dx = current.x - last.x,
			dz = current.z - last.z,
			dt = dt,
		})
	end
end

local function processPlayer(player: Player, data: PlayerData, dt: number)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if humanoid == nil or root == nil or not root:IsA("BasePart") or humanoid.Health <= 0 then
		data.lastPos = nil
		return
	end

	if data.character ~= character then
		data.character = character
		data.lastPos = nil
		data.lastSpeed = 0
		prepareCharacter(humanoid)
	end

	local newStamina, sprinting = Stamina.step(Movement, data.stamina, data.wantsSprint, dt)
	data.stamina = newStamina

	local baseSpeed = PlayerState.speedFor(player) * OfferService.speedFactor(player)
	local speed = if sprinting then baseSpeed * Movement.sprintFactor else baseSpeed
	humanoid.WalkSpeed = speed

	local position = root.Position
	local current: Point = { x = position.X, z = position.Z }
	-- Use the faster of the old and new speed so a sprint that just ended is not punished.
	local result = MoveCheck.check(Movement, data.lastPos, current, dt, math.max(speed, data.lastSpeed))
	data.lastSpeed = speed
	if result == "rubberband" then
		rubberband(player, data, root, current, dt)
	else
		data.lastPos = current
	end

	local fraction = Stamina.fraction(Movement, newStamina)
	if math.abs(fraction - data.sentFraction) >= 0.01 then
		data.sentFraction = fraction
		player:SetAttribute("Stamina", fraction)
	end
end

local function onPlayerAdded(player: Player)
	datas[player.UserId] = newData()
	player:SetAttribute("Stamina", 1)
end

-- Call after the server moved a character on purpose (lobby to arena and back), so the
-- plausibility check does not take the jump for a teleport hack.
function MovementService.noteTeleport(player: Player)
	local data = datas[player.UserId]
	if data ~= nil then
		data.lastPos = nil
	end
end

function MovementService.start(limiter: Limiter)
	local sprintRemote = Remotes.event(Remotes.names.sprint)
	sprintRemote.OnServerEvent:Connect(function(player: Player, active: any)
		local userId = player.UserId
		local data = datas[userId]
		if data == nil then
			limiter.reject(userId, "Sprint", "no_data")
			return
		end
		if typeof(active) ~= "boolean" then
			limiter.reject(userId, "Sprint", "bad_type")
			return
		end
		-- Setting a boolean is cheap, so a too fast call is still applied (a dropped
		-- release would leave the sprint stuck), but it is logged as rejected.
		local now = ServerClock.now()
		if now - data.lastSprintCall < Movement.sprintRemoteMinInterval then
			limiter.reject(userId, "Sprint", "rate_limited")
		end
		data.lastSprintCall = now
		data.wantsSprint = active
	end)

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	Players.PlayerRemoving:Connect(function(player: Player)
		datas[player.UserId] = nil
		limiter.forget(player.UserId)
	end)

	local lastTick = ServerClock.now()
	RunService.Heartbeat:Connect(function()
		local now = ServerClock.now()
		local dt = now - lastTick
		if dt < Movement.checkInterval then
			return
		end
		lastTick = now
		for _, player in Players:GetPlayers() do
			local data = datas[player.UserId]
			if data ~= nil then
				local ok, err = pcall(processPlayer, player, data, dt)
				if not ok then
					log.error("movement tick failed", { userId = player.UserId, error = tostring(err) })
				end
			end
		end
	end)
	log.info("started")
end

return MovementService
