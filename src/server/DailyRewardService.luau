--!strict
-- The daily reward: one gift of coins per day, with a streak (see Config/Daily and DailyReward).
-- The day and the streak are saved in the profile and counted from the server time only. The
-- client sends the intention "claim"; the server checks the profile and the day, gives the coins,
-- saves, and publishes what is available as player attributes for the window (display only).
-- Guests and players whose profile is still loading get no gift. Coins are never bought with
-- Robux. Only checkable in Roblox Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local DailyReward = require(Shared:WaitForChild("DailyReward"))
local Log = require(Shared:WaitForChild("Log"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local DailyConfig = require(Shared:WaitForChild("Config"):WaitForChild("Daily"))
local ProfileConfig = require(Shared:WaitForChild("Config"):WaitForChild("Profile"))

local CoinService = require(script.Parent:WaitForChild("CoinService"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local ServerClock = require(script.Parent:WaitForChild("ServerClock"))

type Limiter = { reject: (userId: number, remote: string, reason: string) -> (), forget: (userId: number) -> () }

local REMOTE_NAME = "ClaimDaily"
-- Seconds between two looks at all players (a day can change while somebody is online).
local REFRESH_SECONDS = 60
-- Seconds a player must wait between two claim requests (against spamming the remote).
local CLAIM_COOLDOWN_SECONDS = 1

local log = Log.new("DailyRewardService")

local lastClaim: { [Player]: number } = {}

local DailyRewardService = {}

local function today(): number
	return DailyReward.dayOf(os.time(), DailyConfig.secondsPerDay)
end

-- Publishes what the window shows: whether a gift is ready, the streak day and the coins.
local function publish(player: Player)
	local data = DataService.getData(player)
	if data == nil then
		player:SetAttribute("DailyAvailable", false)
		return
	end
	local status = DailyReward.status(data.dailyClaimDay, data.dailyStreak, today())
	player:SetAttribute("DailyStreak", status.nextStreak)
	player:SetAttribute("DailyReward", DailyReward.reward(status.nextStreak, DailyConfig.rewards))
	player:SetAttribute("DailyAvailable", status.canClaim)
end

local function claim(player: Player, limiter: Limiter)
	local userId = player.UserId
	local now = ServerClock.now()
	local last = lastClaim[player]
	if last ~= nil and now - last < CLAIM_COOLDOWN_SECONDS then
		limiter.reject(userId, REMOTE_NAME, "rate_limited")
		return
	end
	lastClaim[player] = now

	local data = DataService.getData(player)
	if data == nil then
		limiter.reject(userId, REMOTE_NAME, "no_profile")
		return
	end
	local status = DailyReward.status(data.dailyClaimDay, data.dailyStreak, today())
	if not status.canClaim then
		limiter.reject(userId, REMOTE_NAME, "not_available")
		return
	end

	local coins = DailyReward.reward(status.nextStreak, DailyConfig.rewards)
	data.dailyClaimDay = today()
	data.dailyStreak = math.min(status.nextStreak, ProfileConfig.maxStat)
	CoinService.add(player, coins)
	log.info("daily reward claimed", { userId = userId, streak = status.nextStreak, coins = coins })

	-- Save before the gift is shown, so a reward the player saw is not lost.
	if not DataService.saveNow(player) then
		log.warn("daily reward not saved yet", { userId = userId })
	end
	publish(player)
	if player.Parent ~= nil then
		Remotes.event(Remotes.names.notice):FireClient(player, "daily", "", coins)
	end
end

function DailyRewardService.start(limiter: Limiter)
	local problems = DailyReward.validate(DailyConfig)
	if #problems > 0 then
		log.error("daily config invalid", { problems = table.concat(problems, "; ") })
	end

	Remotes.event(Remotes.names.claimDaily).OnServerEvent:Connect(function(player: Player)
		local ok, err = pcall(claim, player, limiter)
		if not ok then
			log.error("daily claim failed", { userId = player.UserId, error = tostring(err) })
		end
	end)

	DataService.onLoaded(function(player: Player)
		publish(player)
	end)

	task.spawn(function()
		while true do
			task.wait(REFRESH_SECONDS)
			for _, player in Players:GetPlayers() do
				local ok, err = pcall(publish, player)
				if not ok then
					log.error("daily refresh failed", { userId = player.UserId, error = tostring(err) })
				end
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		lastClaim[player] = nil
	end)

	log.info("started", { days = #DailyConfig.rewards })
end

return DailyRewardService
