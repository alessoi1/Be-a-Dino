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
local BotService = require(script.Parent:WaitForChild("BotService"))
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

-- Who is eating or being eaten: a player or a bot, with what the rules need.
type Party = { player: Player?, name: string, points: number, stageIndex: number, scale: number }

local function partyOf(id: number, byId: { [number]: Player }): Party?
	local player = byId[id]
	if player ~= nil then
		local state = PlayerState.get(player)
		if state == nil then
			return nil
		end
		return {
			player = player,
			name = player.DisplayName,
			points = state.points,
			stageIndex = state.stageIndex,
			scale = PlayerState.scaleOf(player),
		}
	end
	local info = BotService.info(id)
	if info == nil then
		return nil
	end
	return { player = nil, name = info.name, points = info.points, stageIndex = info.stageIndex, scale = info.scale }
end

local function execute(eat: Eat, byId: { [number]: Player })
	local eater = partyOf(eat.eaterId, byId)
	local victim = partyOf(eat.victimId, byId)
	if eater == nil or victim == nil then
		return
	end
	local eaterPlayer = eater.player
	local victimPlayer = victim.player
	if victimPlayer ~= nil and livingParts(victimPlayer) == nil then
		return
	end

	local gained = EatRules.pointsGained(Arena.eatPointsShare, victim.points)
	-- Coins for the kill: more for a higher victim, and more with a bounty on the victim (only
	-- players have bounties).
	local multiplier = if victimPlayer ~= nil then BountyService.claimMultiplier(victimPlayer) else 1
	local coins = Coins.forKill(victim.stageIndex, CoinConfig.perKillFactor, multiplier)
	log.info("player eaten", {
		victimId = eat.victimId,
		eaterId = eat.eaterId,
		victimBot = victimPlayer == nil,
		eaterBot = eaterPlayer == nil,
		victimPoints = victim.points,
		eaterPoints = eater.points,
		victimScale = victim.scale,
		eaterScale = eater.scale,
		distance = eat.distance,
		gained = gained,
		coins = coins,
		bounty = multiplier > 1,
	})

	if victimPlayer ~= nil then
		local character = victimPlayer.Character
		if character ~= nil then
			AppearanceService.playCloud(character)
			AppearanceService.removeLook(character)
		end
		-- Joints stay intact (see prepareCharacter), so the invisible body just stops;
		-- the character comes back as the smallest dino after Players.RespawnTime.
		local humanoid = livingParts(victimPlayer)
		if humanoid ~= nil then
			humanoid.Health = 0
		end
		-- Display only: the client counts down to this server time.
		victimPlayer:SetAttribute("RespawnAt", ServerClock.now() + Arena.respawnSeconds)
		if eaterPlayer ~= nil then
			DeathService.open(victimPlayer, eaterPlayer, victim.points)
		else
			DeathService.openByBot(victimPlayer, eater.name, victim.points)
		end
		notice(victimPlayer, "eaten", eater.name, 0)
	else
		BotService.eaten(eat.victimId)
	end

	if eaterPlayer ~= nil then
		PlayerState.addPoints(eaterPlayer, gained)
		StatsService.addKill(eaterPlayer)
		local earned = 0
		if coins > 0 then
			earned = CoinService.addEarned(eaterPlayer, coins)
		end
		notice(eaterPlayer, "ate", victim.name, gained, earned, multiplier > 1)
	else
		BotService.addPoints(eat.eaterId, gained)
	end
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
	-- Bots have negative ids, so they never clash with the user ids of players.
	for _, bot in BotService.combatants() do
		table.insert(combatants, bot)
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
