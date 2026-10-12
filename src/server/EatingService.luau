--!strict
-- Eating between players. One server tick builds the list of living players from the
-- server state (never from client data), asks EatRules who eats whom and carries it out:
-- cloud, victim removed, points for the eater, notices, logs. The victim respawns as the
-- smallest dino after the respawn time. Only checkable in Roblox Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log = require(Shared:WaitForChild("Log"))
local EatRules = require(Shared:WaitForChild("EatRules"))
local Coins = require(Shared:WaitForChild("Coins"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Arena = require(Shared:WaitForChild("Config"):WaitForChild("Arena"))
local CoinConfig = require(Shared:WaitForChild("Config"):WaitForChild("Coins"))

local AppearanceService = require(script.Parent:WaitForChild("AppearanceService"))
local BountyService = require(script.Parent:WaitForChild("BountyService"))
local CoinService = require(script.Parent:WaitForChild("CoinService"))
local DeathService = require(script.Parent:WaitForChild("DeathService"))
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local StatsService = require(script.Parent:WaitForChild("StatsService"))
local ServerClock = require(script.Parent:WaitForChild("ServerClock"))

type Combatant = {
	id: number,
	x: number,
	z: number,
	scale: number,
	protectedUntil: number,
	alive: boolean,
}

type Eat = { eaterId: number, victimId: number, distance: number }

local log = Log.new("EatingService")

local noticeRemote: RemoteEvent? = nil

local EatingService = {}

local function livingParts(player: Player): (Humanoid?, BasePart?)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if humanoid == nil or root == nil or not root:IsA("BasePart") or humanoid.Health <= 0 then
		return nil, nil
	end
	return humanoid, root
end

local function notice(player: Player, kind: string, otherName: string, points: number, coins: number?, bounty: boolean?)
	if noticeRemote ~= nil then
		noticeRemote:FireClient(player, kind, otherName, points, coins, bounty)
	end
end

local function execute(eat: Eat, byId: { [number]: Player })
	local eater = byId[eat.eaterId]
	local victim = byId[eat.victimId]
	if eater == nil or victim == nil then
		return
	end
	local humanoid = livingParts(victim)
	local victimState = PlayerState.get(victim)
	local eaterState = PlayerState.get(eater)
	if humanoid == nil or victimState == nil or eaterState == nil then
		return
	end

	local gained = EatRules.pointsGained(Arena.eatPointsShare, victimState.points)
	-- Coins for the kill: more for a higher victim, and more with a bounty on the victim.
	local multiplier = BountyService.claimMultiplier(victim)
	local coins = Coins.forKill(victimState.stageIndex, CoinConfig.perKillFactor, multiplier)
	log.info("player eaten", {
		victimId = victim.UserId,
		eaterId = eater.UserId,
		victimPoints = victimState.points,
		eaterPoints = eaterState.points,
		victimScale = PlayerState.scaleOf(victim),
		eaterScale = PlayerState.scaleOf(eater),
		distance = eat.distance,
		gained = gained,
		coins = coins,
		bounty = multiplier > 1,
	})

	local character = victim.Character
	if character ~= nil then
		AppearanceService.playCloud(character)
		AppearanceService.removeLook(character)
	end
	-- Joints stay intact (see prepareCharacter), so the invisible body just stops;
	-- the character comes back as the smallest dino after Players.RespawnTime.
	humanoid.Health = 0
	-- Display only: the client counts down to this server time.
	victim:SetAttribute("RespawnAt", ServerClock.now() + Arena.respawnSeconds)

	PlayerState.addPoints(eater, gained)
	StatsService.addKill(eater)
	local earned = 0
	if coins > 0 then
		earned = CoinService.addEarned(eater, coins)
	end
	DeathService.open(victim, eater, victimState.points)
	notice(eater, "ate", victim.DisplayName, gained, earned, multiplier > 1)
	notice(victim, "eaten", eater.DisplayName, 0)
end

local function tick()
	local now = ServerClock.now()
	local combatants: { Combatant } = {}
	local byId: { [number]: Player } = {}
	for _, player in Players:GetPlayers() do
		local humanoid, root = livingParts(player)
		if
			humanoid ~= nil
			and root ~= nil
			and PlayerState.get(player) ~= nil
			and PlayerState.getMode(player) == "playing"
		then
			local position = root.Position
			table.insert(combatants, {
				id = player.UserId,
				x = position.X,
				z = position.Z,
				scale = PlayerState.scaleOf(player),
				protectedUntil = PlayerState.protectedUntil(player),
				alive = true,
			})
			byId[player.UserId] = player
		end
	end

	for _, eat in EatRules.findEats(Arena, combatants, now) do
		local ok, err = pcall(execute, eat, byId)
		if not ok then
			log.error("eat failed", { eaterId = eat.eaterId, victimId = eat.victimId, error = tostring(err) })
		end
	end
end

local function prepareCharacter(character: Model)
	local humanoid = character:WaitForChild("Humanoid", 5)
	if humanoid ~= nil and humanoid:IsA("Humanoid") then
		humanoid.BreakJointsOnDeath = false
	end
end

function EatingService.start()
	noticeRemote = Remotes.event(Remotes.names.notice)
	Players.RespawnTime = Arena.respawnSeconds

	local function watch(player: Player)
		player.CharacterAdded:Connect(function(character: Model)
			task.spawn(prepareCharacter, character)
		end)
		if player.Character ~= nil then
			task.spawn(prepareCharacter, player.Character)
		end
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end

	local lastTick = ServerClock.now()
	RunService.Heartbeat:Connect(function()
		local now = ServerClock.now()
		if now - lastTick < Arena.eatCheckInterval then
			return
		end
		lastTick = now
		local ok, err = pcall(tick)
		if not ok then
			log.error("eating tick failed", { error = tostring(err) })
		end
	end)
	log.info("started")
end

return EatingService
