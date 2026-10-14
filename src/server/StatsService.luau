--!strict
-- The statistics of the players for the global leaderboards: how many players they ate and how
-- many seconds they spent in the arena (autofarm counts). The numbers live in the profile;
-- guests and players whose profile is still loading count in a session counter that is moved
-- into the profile when it arrives. Only checkable in Roblox Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log = require(Shared:WaitForChild("Log"))
local Stats = require(Shared:WaitForChild("Stats"))
local BoardConfig = require(Shared:WaitForChild("Config"):WaitForChild("Leaderboards"))
local ProfileConfig = require(Shared:WaitForChild("Config"):WaitForChild("Profile"))

local DataService = require(script.Parent:WaitForChild("DataService"))
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local QuestService = require(script.Parent:WaitForChild("QuestService"))
local ServerClock = require(script.Parent:WaitForChild("ServerClock"))

type Counters = { kills: number, playSeconds: number }

local log = Log.new("StatsService")

-- Counters of players without a loaded profile.
local session: { [Player]: Counters } = {}
-- The part of a second that was not counted yet.
local rest: { [Player]: number } = {}

local StatsService = {}

-- The counters to change: the live profile when there is one, otherwise the session.
local function target(player: Player): Counters?
	local data = DataService.getData(player)
	if data ~= nil then
		return data
	end
	return session[player]
end

-- A player ate another player.
function StatsService.addKill(player: Player)
	local counters = target(player)
	if counters == nil then
		return
	end
	counters.kills = Stats.add(counters.kills, 1, ProfileConfig.maxStat)
	QuestService.record(player, "kill", 1)
	log.debug("kill counted", { userId = player.UserId, kills = counters.kills })
end

function StatsService.start()
	local function onPlayerAdded(player: Player)
		session[player] = { kills = 0, playSeconds = 0 }
		rest[player] = 0
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	Players.PlayerRemoving:Connect(function(player: Player)
		session[player] = nil
		rest[player] = nil
	end)

	DataService.onLoaded(function(player: Player, data: any)
		-- What was counted while the profile loaded is added to the saved numbers.
		local own = session[player]
		if own == nil then
			return
		end
		data.kills = Stats.add(data.kills, own.kills, ProfileConfig.maxStat)
		data.playSeconds = Stats.add(data.playSeconds, own.playSeconds, ProfileConfig.maxStat)
		own.kills = 0
		own.playSeconds = 0
	end)

	-- Counts the time in the arena once per tick.
	local lastTick = ServerClock.now()
	RunService.Heartbeat:Connect(function()
		local now = ServerClock.now()
		local dt = now - lastTick
		if dt < BoardConfig.statsTickSeconds then
			return
		end
		lastTick = now
		for _, player in Players:GetPlayers() do
			if PlayerState.getMode(player) == "playing" then
				local whole, remainder = Stats.tick(rest[player] or 0, dt, BoardConfig.statsMaxStepSeconds)
				rest[player] = remainder
				local counters = target(player)
				if whole > 0 and counters ~= nil then
					counters.playSeconds = Stats.add(counters.playSeconds, whole, ProfileConfig.maxStat)
					QuestService.record(player, "play", whole)
				end
			end
		end
	end)

	log.info("started")
end

return StatsService
