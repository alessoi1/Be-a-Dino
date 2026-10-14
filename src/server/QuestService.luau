--!strict
-- The daily quests (see Config/Quests and Quests): three quests per day for all players. The
-- progress lives in the profile and is counted from server events only (food eaten, players eaten,
-- stages gained, best combo, seconds in the arena). The client sends the intention "claim quest X";
-- the server checks the day, the progress and that the coins were not taken yet, gives the coins
-- and saves before it confirms. The state is published as one attribute text (`Quests`) for the
-- window (display only). Guests and players whose profile is still loading get no quests. Coins
-- are never bought with Robux. Only checkable in Roblox Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log = require(Shared:WaitForChild("Log"))
local Quests = require(Shared:WaitForChild("Quests"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local QuestConfig = require(Shared:WaitForChild("Config"):WaitForChild("Quests"))

local CoinService = require(script.Parent:WaitForChild("CoinService"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local ServerClock = require(script.Parent:WaitForChild("ServerClock"))

type Limiter = { reject: (userId: number, remote: string, reason: string) -> (), forget: (userId: number) -> () }

local REMOTE_NAME = "ClaimQuest"
-- Seconds between two looks at all players (a day can change while somebody is online).
local REFRESH_SECONDS = 60
-- Seconds a player must wait between two claim requests (against spamming the remote).
local CLAIM_COOLDOWN_SECONDS = 1

local log = Log.new("QuestService")

local lastClaim: { [Player]: number } = {}

local QuestService = {}

local function today(): number
	return math.floor(os.time() / QuestConfig.secondsPerDay)
end

local function todaysQuests(): { Quests.Quest }
	return Quests.pick(today(), QuestConfig.pool, QuestConfig.perDay)
end

-- The state of the player for today (a new day starts a fresh one). Nil without a profile.
local function stateOf(player: Player): Quests.State?
	local data = DataService.getData(player)
	if data == nil then
		return nil
	end
	local state = Quests.sync(data.quests, today())
	data.quests = state
	return state
end

local function publish(player: Player)
	local state = stateOf(player)
	if state == nil then
		player:SetAttribute("Quests", "")
		return
	end
	player:SetAttribute("Quests", Quests.encode(state, todaysQuests()))
end

-- Counts something that happened for the player (see the kinds in Config/Quests). Used by the
-- other services.
function QuestService.record(player: Player, kind: string, amount: number)
	local state = stateOf(player)
	if state == nil then
		return
	end
	if Quests.record(state, todaysQuests(), kind, amount) then
		publish(player)
	end
end

local function claim(player: Player, questId: any, limiter: Limiter)
	local userId = player.UserId
	local now = ServerClock.now()
	local last = lastClaim[player]
	if last ~= nil and now - last < CLAIM_COOLDOWN_SECONDS then
		limiter.reject(userId, REMOTE_NAME, "rate_limited")
		return
	end
	lastClaim[player] = now

	if typeof(questId) ~= "string" or #questId > 64 then
		limiter.reject(userId, REMOTE_NAME, "bad_argument")
		return
	end
	local state = stateOf(player)
	if state == nil then
		limiter.reject(userId, REMOTE_NAME, "no_profile")
		return
	end
	local quest: Quests.Quest? = nil
	for _, candidate in todaysQuests() do
		if candidate.id == questId then
			quest = candidate
		end
	end
	if quest == nil then
		limiter.reject(userId, REMOTE_NAME, "not_today")
		return
	end
	local coins = Quests.claim(state, quest)
	if coins <= 0 then
		limiter.reject(userId, REMOTE_NAME, "not_claimable")
		return
	end
	CoinService.add(player, coins)
	log.info("quest claimed", { userId = userId, quest = quest.id, coins = coins })
	-- Save before the reward is shown, so a reward the player saw is not lost.
	if not DataService.saveNow(player) then
		log.warn("quest reward not saved yet", { userId = userId })
	end
	publish(player)
end

function QuestService.start(limiter: Limiter)
	local problems = Quests.validate(QuestConfig.pool, QuestConfig.perDay)
	if #problems > 0 then
		log.error("quest config invalid", { problems = table.concat(problems, "; ") })
	end

	Remotes.event(Remotes.names.claimQuest).OnServerEvent:Connect(function(player: Player, questId: any)
		local ok, err = pcall(claim, player, questId, limiter)
		if not ok then
			log.error("quest claim failed", { userId = player.UserId, error = tostring(err) })
		end
	end)

	DataService.onLoaded(function(player: Player)
		publish(player)
	end)

	PlayerState.onGrow(function(player: Player, fromIndex: number, toIndex: number)
		QuestService.record(player, "grow", toIndex - fromIndex)
	end)

	task.spawn(function()
		while true do
			task.wait(REFRESH_SECONDS)
			for _, player in Players:GetPlayers() do
				local ok, err = pcall(publish, player)
				if not ok then
					log.error("quest refresh failed", { userId = player.UserId, error = tostring(err) })
				end
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		lastClaim[player] = nil
	end)

	log.info("started", { perDay = QuestConfig.perDay, pool = #QuestConfig.pool })
end

return QuestService
