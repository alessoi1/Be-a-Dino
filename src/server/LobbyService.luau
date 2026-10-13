--!strict
-- The lobby beside the dome: builds the platform and the glowing circles, puts every new
-- character into the lobby, lets players join the arena by standing in the play circle, and
-- lets them go back with a short wait. The client only gets the zone as a player attribute
-- (to open the windows); everything is decided here. Only checkable in Roblox Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log = require(Shared:WaitForChild("Log"))
local PlayMode = require(Shared:WaitForChild("PlayMode"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Strings = require(Shared:WaitForChild("Strings"))
local Zones = require(Shared:WaitForChild("Zones"))
local ArenaConfig = require(Shared:WaitForChild("Config"):WaitForChild("Arena"))
local Lobby = require(Shared:WaitForChild("Config"):WaitForChild("Lobby"))
local DeathConfig = require(Shared:WaitForChild("Config"):WaitForChild("Death"))

local ArenaService = require(script.Parent:WaitForChild("ArenaService"))
local Build = require(script.Parent:WaitForChild("Build"))
local LobbyDecor = require(script.Parent:WaitForChild("LobbyDecor"))
local MovementService = require(script.Parent:WaitForChild("MovementService"))
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local ServerClock = require(script.Parent:WaitForChild("ServerClock"))

type Limiter = { reject: (userId: number, remote: string, reason: string) -> (), forget: (userId: number) -> () }
type Published = { zone: string, zoneUntil: number, full: boolean, leaveAt: number }

-- Height above the lobby floor at which characters appear (they drop to the floor).
local SPAWN_HEIGHT = 4
-- Tries to find a spawn spot that is clear of the circles before the fallback is used.
local SPAWN_TRIES = 20
-- Looks of the platform and the circles (no game values).
local DISC_THICKNESS = 0.3
local LABEL_HEIGHT = 8
local LABEL_WIDTH = 220
local LABEL_HEIGHT_PIXELS = 60
local LABEL_MAX_DISTANCE = 160
local FLOOR_COLOR = Color3.fromRGB(58, 66, 72)
local FRAME_COLOR = Color3.fromRGB(66, 84, 82)
-- How far the side railings stay clear of the wall at their north end (studs).
local RAIL_WALL_GAP = 1
local RAILING_COLOR = Color3.fromRGB(180, 220, 255)
local RAILING_TRANSPARENCY = 0.6
-- Minimum seconds between two leave requests of one player.
local LEAVE_MIN_INTERVAL = 0.3
-- Seconds between two checks while a revive waits for the new character.
local REVIVE_POLL_SECONDS = 0.2

local log = Log.new("LobbyService")
local random = Random.new()

local zoneKinds: { [string]: string } = {}
-- The circles in world coordinates (the config has them relative to the middle of the platform).
local worldZones: { Zones.Zone } = {}
-- What the decoration takes up on the floor (set when the lobby is built); nobody spawns there.
local decorCircles: { Zones.Zone } = {}
for _, zone in Lobby.zones do
	zoneKinds[zone.id] = zone.kind
	table.insert(worldZones, {
		id = zone.id,
		x = zone.x + Lobby.centerX,
		z = zone.z + Lobby.centerZ,
		radius = zone.radius,
		dwell = zone.dwell,
	})
end

local dwell: { [Player]: Zones.Dwell } = {}
local leaveAt: { [Player]: number } = {}
local lastLeaveCall: { [Player]: number } = {}
local published: { [Player]: Published } = {}

local LobbyService = {}

local function lobbyCenterY(): number
	return Lobby.height
end

local function buildLabel(folder: Instance, zone: Zones.Zone)
	local anchor = Instance.new("Part")
	anchor.Name = "Label_" .. zone.id
	anchor.Size = Vector3.one
	anchor.Position = Vector3.new(zone.x, lobbyCenterY() + LABEL_HEIGHT, zone.z)
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanTouch = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Parent = folder

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(LABEL_WIDTH, LABEL_HEIGHT_PIXELS)
	gui.MaxDistance = LABEL_MAX_DISTANCE
	gui.AlwaysOnTop = false
	gui.Parent = anchor

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.FontFace = Font.fromEnum(Enum.Font.FredokaOne)
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.4
	label.Text = Strings.lobby.zones[zone.id] or zone.id
	label.Parent = gui
end

local function build()
	local existing = workspace:FindFirstChild("Lobby")
	if existing ~= nil then
		existing:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "Lobby"

	local size = Lobby.size
	local height = lobbyCenterY()
	Build.block(
		folder,
		"Floor",
		Vector3.new(size, Lobby.floorThickness, size),
		Vector3.new(Lobby.centerX, height - Lobby.floorThickness / 2, Lobby.centerZ),
		FLOOR_COLOR,
		Enum.Material.DiamondPlate,
		0,
		true
	)

	-- Glass railings on the east, west and south side so nobody falls off. The north side is the
	-- dome wall with the viewing window. The side railings start at the wall.
	local rail = Lobby.railingHeight
	local thick = Lobby.railingThickness
	local half = size / 2
	local offset = half + thick / 2
	local length = size + 2 * thick
	local railY = height + rail / 2
	local outer = ArenaConfig.radius + ArenaConfig.wallThickness
	local railNorthZ = math.sqrt(math.max(0, outer * outer - (half + thick) ^ 2)) + RAIL_WALL_GAP
	local railSouthZ = Lobby.centerZ + half
	local sideLength = math.max(0, railSouthZ - railNorthZ)
	local sideCenterZ = (railNorthZ + railSouthZ) / 2
	Build.block(
		folder,
		"RailSouth",
		Vector3.new(length, rail, thick),
		Vector3.new(Lobby.centerX, railY, Lobby.centerZ + offset),
		RAILING_COLOR,
		Enum.Material.Glass,
		RAILING_TRANSPARENCY,
		true
	)
	for _, side in { -1, 1 } do
		Build.block(
			folder,
			if side < 0 then "RailWest" else "RailEast",
			Vector3.new(thick, rail, sideLength),
			Vector3.new(Lobby.centerX + side * offset, railY, sideCenterZ),
			RAILING_COLOR,
			Enum.Material.Glass,
			RAILING_TRANSPARENCY,
			true
		)
		-- A metal post at the corner, the same metal as the frame of the dome.
		Build.block(
			folder,
			"Post",
			Vector3.new(thick * 2, rail * 1.4, thick * 2),
			Vector3.new(Lobby.centerX + side * offset, height + rail * 0.7, railSouthZ + thick / 2),
			FRAME_COLOR,
			Enum.Material.Metal,
			0,
			false
		)
	end

	for index, zone in worldZones do
		-- Same order as the config: the colors come from there.
		local tint = Lobby.zones[index].color
		Build.cylinder(
			folder,
			"Zone_" .. zone.id,
			DISC_THICKNESS,
			zone.radius * 2,
			height,
			zone.x,
			zone.z,
			Color3.fromRGB(tint.r, tint.g, tint.b),
			Enum.Material.Neon,
			0.2
		)
		buildLabel(folder, zone)
	end

	-- The research station look; its circles keep the spawn clear.
	decorCircles = LobbyDecor.build(folder)

	folder.Parent = workspace
	log.info("lobby built", { size = size, height = height, zones = #Lobby.zones })
end

-- A random spot on the visible part of the platform (not under the arena wall) that is clear of
-- the circles.
local function lobbySpawn(): Vector3
	local half = Lobby.size / 2
	local minZ = Lobby.centerZ - half + Lobby.northInset + Lobby.spawnMargin
	local maxZ = Lobby.centerZ + half - Lobby.spawnMargin
	local reach = half - Lobby.spawnMargin
	for _ = 1, SPAWN_TRIES do
		local x = Lobby.centerX + (random:NextNumber() * 2 - 1) * reach
		local z = minZ + random:NextNumber() * (maxZ - minZ)
		if Zones.isClear(worldZones, x, z, Lobby.spawnClearance) and Zones.isClear(decorCircles, x, z, 1) then
			return Vector3.new(x, lobbyCenterY() + SPAWN_HEIGHT, z)
		end
	end
	return Vector3.new(Lobby.centerX, lobbyCenterY() + SPAWN_HEIGHT, maxZ)
end

local function placeInLobby(player: Player): boolean
	local character = player.Character
	if character == nil then
		return false
	end
	local position = lobbySpawn()
	local ok, err = pcall(function()
		character:PivotTo(CFrame.new(position))
	end)
	if not ok then
		log.error("lobby placement failed", { userId = player.UserId, error = tostring(err) })
		return false
	end
	MovementService.noteTeleport(player)
	return true
end

local function setPublished(player: Player, zone: string, zoneUntil: number, full: boolean, leave: number)
	local last = published[player]
	if last == nil or last.zone ~= zone then
		player:SetAttribute("ZoneId", zone)
	end
	if last == nil or last.zoneUntil ~= zoneUntil then
		player:SetAttribute("ZoneUntil", zoneUntil)
	end
	if last == nil or last.full ~= full then
		player:SetAttribute("ArenaFull", full)
	end
	if last == nil or last.leaveAt ~= leave then
		player:SetAttribute("LeaveAt", leave)
	end
	published[player] = { zone = zone, zoneUntil = zoneUntil, full = full, leaveAt = leave }
end

-- Tries to put the player into the arena. Returns whether it worked.
local function enterArena(player: Player, startPoints: number?): boolean
	local playing = PlayerState.countPlaying()
	local ok, reason = PlayMode.canEnter(playing, Lobby.maxPlaying)
	if not ok then
		log.info("arena entry refused", { userId = player.UserId, reason = reason, playing = playing })
		return false
	end
	if not ArenaService.placeInArena(player) then
		return false
	end
	PlayerState.beginRound(player, startPoints)
	MovementService.noteTeleport(player)
	log.info("entered the arena", { userId = player.UserId, playing = playing + 1 })
	return true
end

local function leaveArena(player: Player)
	leaveAt[player] = nil
	PlayerState.endRound(player)
	placeInLobby(player)
	log.info("back in the lobby", { userId = player.UserId })
end

local function livingRoot(player: Player): BasePart?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if humanoid == nil or root == nil or not root:IsA("BasePart") or humanoid.Health <= 0 then
		return nil
	end
	return root
end

local function checkLobbyPlayer(player: Player, root: BasePart, now: number)
	leaveAt[player] = nil
	if root.Position.Y < lobbyCenterY() - Lobby.fallTolerance then
		log.warn("lobby player below the platform, placed back", { userId = player.UserId })
		placeInLobby(player)
		return
	end

	local zone = Zones.zoneAt(worldZones, root.Position.X, root.Position.Z)
	local state, fired = Zones.step(dwell[player] or Zones.newDwell(), zone, now)
	dwell[player] = state

	local full = false
	if fired and zone ~= nil and zoneKinds[zone.id] == "play" then
		if enterArena(player) then
			dwell[player] = Zones.newDwell()
			setPublished(player, "", 0, false, 0)
			return
		end
		-- Standing on in the full circle tries again after the dwell time.
		dwell[player] = Zones.newDwell()
		full = true
	end

	local remaining = Zones.remaining(dwell[player] or state, zone, now)
	local zoneUntil = if zone ~= nil and zoneKinds[zone.id] == "play" and remaining > 0 then now + remaining else 0
	local wasFull = published[player] ~= nil and published[player].full
	setPublished(player, if zone ~= nil then zone.id else "", zoneUntil, full or (wasFull and zone ~= nil), 0)
end

local function checkPlayingPlayer(player: Player, now: number)
	dwell[player] = nil
	local at = leaveAt[player] or 0
	if at > 0 and now >= at then
		leaveArena(player)
		setPublished(player, "", 0, false, 0)
		return
	end
	setPublished(player, "", 0, false, at)
end

local function tick()
	local now = ServerClock.now()
	for _, player in Players:GetPlayers() do
		local ok, err = pcall(function()
			local mode = PlayerState.getMode(player)
			local root = livingRoot(player)
			if mode == "playing" then
				checkPlayingPlayer(player, now)
			elseif root ~= nil then
				checkLobbyPlayer(player, root, now)
			end
		end)
		if not ok then
			log.error("lobby check failed", { userId = player.UserId, error = tostring(err) })
		end
	end
end

local function onLeaveRequest(player: Player, active: any, limiter: Limiter)
	local userId = player.UserId
	if type(active) ~= "boolean" then
		limiter.reject(userId, "LeaveArena", "bad_type")
		return
	end
	local now = ServerClock.now()
	local last = lastLeaveCall[player]
	if last ~= nil and now - last < LEAVE_MIN_INTERVAL then
		limiter.reject(userId, "LeaveArena", "rate_limited")
		return
	end
	lastLeaveCall[player] = now
	if PlayerState.getMode(player) ~= "playing" then
		limiter.reject(userId, "LeaveArena", "not_playing")
		return
	end
	if active then
		if leaveAt[player] == nil then
			leaveAt[player] = now + Lobby.leaveSeconds
			log.info("leave requested", { userId = userId })
		end
	else
		leaveAt[player] = nil
	end
end

local function onPlayerAdded(player: Player)
	setPublished(player, "", 0, false, 0)
	player.CharacterAdded:Connect(function()
		-- Every new character (joining, or back after being eaten) starts in the lobby.
		placeInLobby(player)
	end)
	if player.Character ~= nil then
		placeInLobby(player)
	end
end

-- A revive: waits for the new character in the lobby, then puts the player back into the arena
-- with the points they had (same dino, protected for a few seconds). Returns false when it is not
-- possible (no character in time, arena full). Called by the DeathService after a paid revive.
function LobbyService.revive(player: Player, points: number): boolean
	local deadline = ServerClock.now() + DeathConfig.reviveWaitSeconds
	while player.Parent ~= nil and (livingRoot(player) == nil or PlayerState.getMode(player) ~= "lobby") do
		if ServerClock.now() >= deadline then
			log.warn("revive timed out", { userId = player.UserId })
			return false
		end
		task.wait(REVIVE_POLL_SECONDS)
	end
	if player.Parent == nil then
		return false
	end
	-- The lobby spawn of the new character must be done before the player is moved again.
	task.wait(DeathConfig.reviveSettleSeconds)
	if livingRoot(player) == nil or PlayerState.getMode(player) ~= "lobby" then
		return false
	end
	return enterArena(player, points)
end

function LobbyService.start(limiter: Limiter)
	local problems = Zones.validate(Lobby.zones, Lobby.size, Lobby.spawnMargin)
	for _, problem in problems do
		log.error("lobby config invalid", { problem = problem })
	end

	build()

	Remotes.event(Remotes.names.leaveArena).OnServerEvent:Connect(function(player: Player, active: any)
		onLeaveRequest(player, active, limiter)
	end)

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	Players.PlayerRemoving:Connect(function(player: Player)
		dwell[player] = nil
		leaveAt[player] = nil
		lastLeaveCall[player] = nil
		published[player] = nil
	end)

	local lastTick = ServerClock.now()
	RunService.Heartbeat:Connect(function()
		local now = ServerClock.now()
		if now - lastTick < Lobby.checkInterval then
			return
		end
		lastTick = now
		tick()
	end)
	log.info("started")
end

return LobbyService
