--!strict
-- Bots that fill the arena while few real players are in it. A bot is a small model (a Humanoid
-- on a transparent root) with the dino look of its stage; the server walks it with MoveTo. It
-- eats food, grows up to a low stage, flees from bigger dinos and hunts smaller ones. The
-- EatingService treats bots like players (they can eat and be eaten). Every player who enters the
-- arena takes the place of one bot: the smallest one leaves. Bots keep all their state here, they
-- are not Players. Only checkable in Roblox Studio.

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Avoidance = require(Shared:WaitForChild("Avoidance"))
local BotBrain = require(Shared:WaitForChild("BotBrain"))
local Growth = require(Shared:WaitForChild("Growth"))
local Log = require(Shared:WaitForChild("Log"))
local Strings = require(Shared:WaitForChild("Strings"))
local ArenaConfig = require(Shared:WaitForChild("Config"):WaitForChild("Arena"))
local BotsConfig = require(Shared:WaitForChild("Config"):WaitForChild("Bots"))
local CollisionConfig = require(Shared:WaitForChild("Config"):WaitForChild("Collision"))
local Dinos = require(Shared:WaitForChild("Config"):WaitForChild("Dinos"))
local GrowthConfig = require(Shared:WaitForChild("Config"):WaitForChild("Growth"))

local AppearanceService = require(script.Parent:WaitForChild("AppearanceService"))
local ArenaService = require(script.Parent:WaitForChild("ArenaService"))
local FoodService = require(script.Parent:WaitForChild("FoodService"))
local PlayerCollision = require(script.Parent:WaitForChild("PlayerCollision"))
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local SceneryService = require(script.Parent:WaitForChild("SceneryService"))
local ServerClock = require(script.Parent:WaitForChild("ServerClock"))

type Bot = {
	id: number,
	name: string,
	state: Growth.State,
	alive: boolean,
	model: Model?,
	humanoid: Humanoid?,
	root: BasePart?,
	protectedUntil: number,
	-- Server time at which a dead bot comes back (0 while it is alive).
	respawnAt: number,
	appliedScale: number,
	wander: BotBrain.Point,
	wanderUntil: number,
}

-- What the EatingService needs to know about a living bot.
export type Combatant = {
	id: number,
	x: number,
	z: number,
	scale: number,
	points: number,
	protectedUntil: number,
	alive: boolean,
}

export type Info = { name: string, points: number, stageIndex: number, scale: number }

-- Size of the invisible root (the same as the root of a player character).
local ROOT_SIZE = Vector3.new(2, 2, 1)
-- Seconds the cloud of a bot that was eaten or left stays before its model is removed.
local REMOVE_DELAY = 1.5
-- A bot below this height fell out of the arena.
local LOWEST_Y = -50
local MODEL_NAME = "Bot"
-- Model attribute with the size of the bot, for the name tag on the clients.
local POINTS_ATTRIBUTE = "Points"
-- Model attribute with the (negative) id of the bot, for the leaderboard on the clients.
local ID_ATTRIBUTE = "BotId"
local FOLDER_NAME = "Bots"

local log = Log.new("BotService")
local random = Random.new()

local bots: { [number]: Bot } = {}
local folder: Folder? = nil
-- Bot ids are negative, so they never clash with the user ids of players.
local lastId = 0

-- How far from the middle a bot may walk on each axis.
local limit = ArenaConfig.radius - BotsConfig.wallMargin

local brainConfig: BotBrain.Config = {
	fleeRange = BotsConfig.fleeRange,
	huntRange = BotsConfig.huntRange,
	fleeStep = BotsConfig.fleeStep,
	foodDistanceBias = BotsConfig.foodDistanceBias,
}

local BotService = {}

local function pickName(): string
	local used: { [string]: boolean } = {}
	for _, bot in bots do
		used[bot.name] = true
	end
	local free: { string } = {}
	for _, name in Strings.botNames do
		if not used[name] then
			table.insert(free, name)
		end
	end
	if #free > 0 then
		return free[random:NextInteger(1, #free)]
	end
	return Strings.botNames[random:NextInteger(1, #Strings.botNames)] .. " " .. tostring(-lastId)
end

local function newState(): Growth.State
	local points = BotBrain.startPoints(Dinos, BotsConfig.startStageMax, random:NextNumber())
	local state = Growth.newState()
	if points > 0 then
		state = Growth.addPoints(Dinos, state, points)
	end
	return state
end

-- Takes the body of a bot out of the arena (eaten, or it leaves the server).
local function removeBody(bot: Bot, withCloud: boolean)
	local model = bot.model
	bot.alive = false
	bot.model = nil
	bot.humanoid = nil
	bot.root = nil
	if model == nil then
		return
	end
	if withCloud then
		AppearanceService.playCloud(model)
	end
	AppearanceService.removeLook(model)
	local root = model:FindFirstChild("HumanoidRootPart")
	if root ~= nil and root:IsA("BasePart") then
		root.Anchored = true
	end
	Debris:AddItem(model, REMOVE_DELAY)
end

local function spawnBody(bot: Bot)
	local now = ServerClock.now()
	local position = ArenaService.spawnPosition(nil)
	local scale = Growth.scaleFor(Dinos, bot.state)

	local model = Instance.new("Model")
	model.Name = MODEL_NAME

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = ROOT_SIZE
	root.Transparency = 1
	root.CanCollide = true
	root.Parent = model
	model.PrimaryPart = root

	local humanoid = Instance.new("Humanoid")
	humanoid.RigType = Enum.HumanoidRigType.R15
	humanoid.HipHeight = BotsConfig.hipHeight
	humanoid.DisplayName = bot.name
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	-- The own name tag (client, NameTags) replaces the one of Roblox.
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.UseJumpPower = true
	humanoid.JumpPower = 0
	humanoid.Parent = model

	model:SetAttribute(POINTS_ATTRIBUTE, math.floor(bot.state.points))
	model:SetAttribute(ID_ATTRIBUTE, bot.id)
	model:PivotTo(CFrame.new(position))
	model.Parent = folder
	-- The server walks the bot, so no player's device may take over its physics.
	local owned, ownerErr = pcall(function()
		root:SetNetworkOwner(nil)
	end)
	if not owned then
		log.warn("bot network owner not set", { id = bot.id, error = tostring(ownerErr) })
	end
	PlayerCollision.assign(model)
	model:ScaleTo(scale)
	task.spawn(AppearanceService.attachBotLook, model, Dinos[bot.state.stageIndex].id)

	bot.model = model
	bot.humanoid = humanoid
	bot.root = root
	bot.alive = true
	bot.respawnAt = 0
	bot.appliedScale = scale
	bot.protectedUntil = now + BotsConfig.protectionSeconds
	bot.wanderUntil = 0
	log.info("bot spawned", { id = bot.id, name = bot.name, stage = Dinos[bot.state.stageIndex].id })
end

local function addBot()
	lastId -= 1
	local bot: Bot = {
		id = lastId,
		name = pickName(),
		state = newState(),
		alive = false,
		model = nil,
		humanoid = nil,
		root = nil,
		protectedUntil = 0,
		respawnAt = 0,
		appliedScale = 1,
		wander = { x = 0, z = 0 },
		wanderUntil = 0,
	}
	bots[bot.id] = bot
	spawnBody(bot)
end

local function removeBot(bot: Bot, reason: string)
	removeBody(bot, true)
	bots[bot.id] = nil
	log.info("bot removed", { id = bot.id, name = bot.name, reason = reason })
end

-- Fills the arena up to the target with bots, or sends the smallest ones away.
local function reconcile()
	local want = BotBrain.targetCount(BotsConfig.fillTo, PlayerState.countPlaying())
	local list: { BotBrain.BotInfo } = {}
	for id, bot in bots do
		table.insert(list, { id = id, points = bot.state.points })
	end
	while #list > want do
		local leaverId = BotBrain.pickLeaver(list)
		if leaverId == nil then
			break
		end
		local leaver = bots[leaverId]
		if leaver ~= nil then
			removeBot(leaver, "player_entered")
		end
		for index, entry in list do
			if entry.id == leaverId then
				table.remove(list, index)
				break
			end
		end
	end
	for _ = #list + 1, want do
		local ok, err = pcall(addBot)
		if not ok then
			log.error("adding a bot failed", { error = tostring(err) })
			break
		end
	end
end

-- Position, scale and protection of the living players in the arena.
local function playerActors(): { BotBrain.Actor }
	local actors: { BotBrain.Actor } = {}
	for _, player in Players:GetPlayers() do
		local state = PlayerState.get(player)
		if state == nil or PlayerState.getMode(player) ~= "playing" then
			continue
		end
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid ~= nil and humanoid.Health > 0 and root ~= nil and root:IsA("BasePart") then
			table.insert(actors, {
				id = player.UserId,
				x = root.Position.X,
				z = root.Position.Z,
				scale = PlayerState.scaleOf(player),
				points = state.points,
				protectedUntil = PlayerState.protectedUntil(player),
			})
		end
	end
	return actors
end

local function botActor(bot: Bot): BotBrain.Actor?
	local root = bot.root
	if not bot.alive or root == nil then
		return nil
	end
	return {
		id = bot.id,
		x = root.Position.X,
		z = root.Position.Z,
		scale = Growth.scaleFor(Dinos, bot.state),
		points = bot.state.points,
		protectedUntil = bot.protectedUntil,
	}
end

-- Gives a living bot points (from food or from eating); bots stop growing at the maximum stage.
function BotService.addPoints(id: number, amount: number)
	local bot = bots[id]
	if bot == nil or not bot.alive or not BotBrain.mayGrow(bot.state.stageIndex, BotsConfig.maxStageIndex) then
		return
	end
	local updated, changed = Growth.addPoints(Dinos, bot.state, amount)
	bot.state = updated
	local model = bot.model
	if model == nil then
		return
	end
	model:SetAttribute(POINTS_ATTRIBUTE, math.floor(updated.points))
	local scale = Growth.scaleFor(Dinos, updated)
	if changed or math.abs(scale - bot.appliedScale) >= GrowthConfig.scaleApplyStep then
		bot.appliedScale = scale
		model:ScaleTo(scale)
	end
	if changed then
		task.spawn(AppearanceService.attachBotLook, model, Dinos[updated.stageIndex].id)
		AppearanceService.playCloud(model)
		log.info("bot stage changed", { id = id, stage = Dinos[updated.stageIndex].id, points = updated.points })
	end
end

local function think(bot: Bot, now: number, all: { BotBrain.Actor })
	local root = bot.root
	local humanoid = bot.humanoid
	if root == nil or humanoid == nil or root.Parent == nil or humanoid.Health <= 0 or root.Position.Y < LOWEST_Y then
		log.warn("bot lost its body", { id = bot.id })
		removeBody(bot, false)
		bot.respawnAt = now + BotsConfig.respawnSeconds
		return
	end

	local position = root.Position
	local scale = Growth.scaleFor(Dinos, bot.state)
	local gained = FoodService.collectAt(position.X, position.Z, scale, Dinos[bot.state.stageIndex].foodUnit)
	if gained > 0 then
		BotService.addPoints(bot.id, gained)
		scale = Growth.scaleFor(Dinos, bot.state)
	end

	local dx = bot.wander.x - position.X
	local dz = bot.wander.z - position.Z
	if now >= bot.wanderUntil or dx * dx + dz * dz < 25 then
		local angle = random:NextNumber() * math.pi * 2
		bot.wander = BotBrain.clampToArena(
			position.X + math.cos(angle) * BotsConfig.wanderStep,
			position.Z + math.sin(angle) * BotsConfig.wanderStep,
			limit
		)
		bot.wanderUntil = now + BotsConfig.wanderSeconds
	end

	local self: BotBrain.Actor = {
		id = bot.id,
		x = position.X,
		z = position.Z,
		scale = scale,
		points = bot.state.points,
		protectedUntil = bot.protectedUntil,
	}
	local food = FoodService.piecesNear(position.X, position.Z, BotsConfig.foodRange)
	local goal = BotBrain.choose(brainConfig, limit, self, all, food, now, bot.wander)
	humanoid.WalkSpeed = Growth.speedFor(Dinos, bot.state) * BotsConfig.speedFactor
	-- Walk around trees and rocks on the way (the body needs room in proportion to its scale).
	local waypoint = Avoidance.steer(
		{ x = position.X, z = position.Z },
		{ x = goal.x, z = goal.z },
		SceneryService.obstacles(),
		scale * CollisionConfig.bodyRadiusPerScale + CollisionConfig.margin,
		CollisionConfig.lookAhead,
		CollisionConfig.maxDetours
	)
	humanoid:MoveTo(Vector3.new(waypoint.x, position.Y, waypoint.z))
	log.debug("bot goal", { id = bot.id, kind = goal.kind })
end

local function tick()
	local now = ServerClock.now()
	local all = playerActors()
	for _, bot in bots do
		local actor = botActor(bot)
		if actor ~= nil then
			table.insert(all, actor)
		end
	end
	for _, bot in table.clone(bots) do
		if bots[bot.id] == nil then
			continue
		end
		local ok, err = pcall(function()
			if bot.alive then
				think(bot, now, all)
			elseif bot.respawnAt > 0 and now >= bot.respawnAt then
				bot.state = newState()
				if BotsConfig.renameOnRespawn then
					local oldName = bot.name
					bot.name = pickName()
					log.debug("bot renamed", { id = bot.id, oldName = oldName, name = bot.name })
				end
				spawnBody(bot)
			end
		end)
		if not ok then
			log.error("bot tick failed", { id = bot.id, error = tostring(err) })
		end
	end
end

-- The living bots as the EatingService needs them.
function BotService.combatants(): { Combatant }
	local list: { Combatant } = {}
	for _, bot in bots do
		local root = bot.root
		if bot.alive and root ~= nil then
			table.insert(list, {
				id = bot.id,
				x = root.Position.X,
				z = root.Position.Z,
				scale = Growth.scaleFor(Dinos, bot.state),
				points = bot.state.points,
				protectedUntil = bot.protectedUntil,
				alive = true,
			})
		end
	end
	return list
end

-- Name, points, stage and scale of a living bot (nil for an unknown or dead bot).
function BotService.info(id: number): Info?
	local bot = bots[id]
	if bot == nil or not bot.alive then
		return nil
	end
	return {
		name = bot.name,
		points = bot.state.points,
		stageIndex = bot.state.stageIndex,
		scale = Growth.scaleFor(Dinos, bot.state),
	}
end

-- A bot was eaten: its body goes away and it comes back (smaller) after a while.
function BotService.eaten(id: number)
	local bot = bots[id]
	if bot == nil or not bot.alive then
		return
	end
	removeBody(bot, true)
	bot.respawnAt = ServerClock.now() + BotsConfig.respawnSeconds
	log.info("bot eaten", { id = id, name = bot.name, respawnSeconds = BotsConfig.respawnSeconds })
end

function BotService.start()
	local botFolder = Instance.new("Folder")
	botFolder.Name = FOLDER_NAME
	botFolder.Parent = workspace
	folder = botFolder

	ArenaService.setBotPositions(function()
		local points: { { x: number, z: number } } = {}
		for _, bot in bots do
			local root = bot.root
			if bot.alive and root ~= nil then
				table.insert(points, { x = root.Position.X, z = root.Position.Z })
			end
		end
		return points
	end)

	reconcile()

	local lastThink = ServerClock.now()
	local lastReconcile = lastThink
	RunService.Heartbeat:Connect(function()
		local now = ServerClock.now()
		if now - lastReconcile >= BotsConfig.reconcileInterval then
			lastReconcile = now
			local ok, err = pcall(reconcile)
			if not ok then
				log.error("reconcile failed", { error = tostring(err) })
			end
		end
		if now - lastThink >= BotsConfig.thinkInterval then
			lastThink = now
			local ok, err = pcall(tick)
			if not ok then
				log.error("bot tick failed", { error = tostring(err) })
			end
		end
	end)
	log.info("started", { fillTo = BotsConfig.fillTo })
end

return BotService
