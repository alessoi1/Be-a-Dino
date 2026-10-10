--!strict
-- Keeps the collection up to date: the dinos a player has reached and the best round.
-- Every player has a session collection (for guests and while the profile is loading); a
-- loaded profile gets the same entries, and ProfileStore saves it. The values are also
-- published as player attributes for the collection menu (read only on the client).
-- Only checkable in Roblox Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log = require(Shared:WaitForChild("Log"))
local Collection = require(Shared:WaitForChild("Collection"))
local CollectionView = require(Shared:WaitForChild("CollectionView"))
local Dinos = require(Shared:WaitForChild("Config"):WaitForChild("Dinos"))

local DataService = require(script.Parent:WaitForChild("DataService"))
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))

type GrowthState = { points: number, stageIndex: number, highestStageIndex: number }
type CollectionData = { reachedStages: { [string]: boolean }, bestPoints: number }
type Published = { reached: string, best: number }

local log = Log.new("CollectionService")

type ChangedHandler = (player: Player) -> ()

local session: { [Player]: CollectionData } = {}
local changedHandlers: { ChangedHandler } = {}
local published: { [Player]: Published } = {}

local CollectionService = {}

-- Applies the running round to a collection. Returns how many dinos were new and
-- whether the best round improved.
local function apply(target: CollectionData, state: GrowthState): (number, boolean)
	local added = Collection.markUpTo(target, Dinos, state.highestStageIndex)
	local newBest = Collection.updateBest(target, state.points)
	return added, newBest
end

-- Sets the attributes only when something changed.
local function publish(player: Player, source: CollectionData)
	local reached = CollectionView.encodeReached(source.reachedStages, Dinos)
	local last = published[player]
	if last ~= nil and last.reached == reached and last.best == source.bestPoints then
		return
	end
	published[player] = { reached = reached, best = source.bestPoints }
	player:SetAttribute("Reached", reached)
	player:SetAttribute("BestPoints", source.bestPoints)
	for _, handler in changedHandlers do
		local ok, err = pcall(handler, player)
		if not ok then
			log.error("changed handler failed", { userId = player.UserId, error = tostring(err) })
		end
	end
end

-- Records the state in the session and, when there is one, in the live profile.
local function record(player: Player, state: GrowthState)
	local own = session[player]
	if own == nil then
		return
	end
	apply(own, state)

	local data = DataService.getData(player)
	if data == nil then
		publish(player, own)
		return
	end
	local added, newBest = apply(data, state)
	if added > 0 then
		log.info("dino reached", {
			userId = player.UserId,
			stage = Dinos[state.highestStageIndex].id,
			collected = Collection.reachedCount(data, Dinos),
		})
	end
	if newBest then
		log.debug("new best round", { userId = player.UserId, bestPoints = data.bestPoints })
	end
	publish(player, data)
end

local function onPlayerAdded(player: Player)
	session[player] = { reachedStages = {}, bestPoints = 0 }
	local state = PlayerState.get(player)
	if state ~= nil then
		record(player, state)
	end
end

-- The live profile of the player, or the session collection for guests and while loading.
function CollectionService.get(player: Player): CollectionData?
	local data = DataService.getData(player)
	if data ~= nil then
		return data
	end
	return session[player]
end

-- Registers a handler that runs after the collection of a player changed (reached dino or
-- best round). Runs rarely, except for the best round during a record round.
function CollectionService.onChanged(handler: ChangedHandler)
	table.insert(changedHandlers, handler)
end

function CollectionService.start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	Players.PlayerRemoving:Connect(function(player: Player)
		session[player] = nil
		published[player] = nil
	end)

	DataService.onLoaded(function(player: Player, data: any)
		-- What was reached while the profile loaded is added to the saved collection.
		local own = session[player]
		if own ~= nil then
			for stageId in own.reachedStages do
				Collection.markReached(data, stageId)
			end
			Collection.updateBest(data, own.bestPoints)
		end
		local state = PlayerState.get(player)
		if state ~= nil then
			record(player, state)
		else
			publish(player, data)
		end
	end)

	PlayerState.onPoints(function(player: Player, state: GrowthState)
		record(player, state)
	end)

	log.info("started")
end

return CollectionService
