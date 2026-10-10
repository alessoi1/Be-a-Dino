--!strict
-- Keeps the saved collection up to date: the dinos a player has reached and the best round.
-- It writes into the live profile (ProfileStore saves it). Guests and players whose profile
-- is still loading are skipped; when the profile arrives it catches up with the current
-- round. Only checkable in Roblox Studio.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log = require(Shared:WaitForChild("Log"))
local Collection = require(Shared:WaitForChild("Collection"))
local Dinos = require(Shared:WaitForChild("Config"):WaitForChild("Dinos"))

local DataService = require(script.Parent:WaitForChild("DataService"))
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))

type GrowthState = { points: number, stageIndex: number, highestStageIndex: number }

local log = Log.new("CollectionService")

local CollectionService = {}

-- Applies the state of the running round to the profile. Returns true on news worth a log.
local function record(player: Player, data: any, state: GrowthState)
	local added = Collection.markUpTo(data, Dinos, state.highestStageIndex)
	local newBest = Collection.updateBest(data, state.points)
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
end

function CollectionService.start()
	DataService.onLoaded(function(player: Player, data: any)
		local state = PlayerState.get(player)
		if state ~= nil then
			record(player, data, state)
		end
	end)

	PlayerState.onPoints(function(player: Player, state: GrowthState)
		local data = DataService.getData(player)
		if data ~= nil then
			record(player, data, state)
		end
	end)

	log.info("started")
end

return CollectionService
