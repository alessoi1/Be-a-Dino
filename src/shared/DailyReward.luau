--!strict
-- Pure rules of the daily reward: which day it is, whether a gift can be claimed and what the
-- streak is then. No Roblox services; the DailyRewardService applies the result.

local DailyReward = {}

export type Status = {
	-- True when no gift was claimed today yet.
	canClaim: boolean,
	-- The streak day a claim would make (1 after a missed day or the first claim).
	nextStreak: number,
}

local function isFinite(value: any): boolean
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

-- The day number of a server time in seconds (0 for invalid input).
function DailyReward.dayOf(now: number, secondsPerDay: number): number
	if not isFinite(now) or not isFinite(secondsPerDay) or now < 0 or secondsPerDay <= 0 then
		return 0
	end
	return math.floor(now / secondsPerDay)
end

-- `lastClaimDay` is the day of the last claim (0 = never), `streak` the streak day of that claim.
-- A claim on the day after the last one continues the streak; any other later day starts again.
-- Days that are not later than the last claim (also a clock that went back) give no gift.
function DailyReward.status(lastClaimDay: number, streak: number, today: number): Status
	if not isFinite(lastClaimDay) or not isFinite(streak) or not isFinite(today) or today < 1 then
		return { canClaim = false, nextStreak = 1 }
	end
	if lastClaimDay > 0 and today <= lastClaimDay then
		return { canClaim = false, nextStreak = math.max(1, math.floor(streak) + 1) }
	end
	if lastClaimDay > 0 and today == lastClaimDay + 1 then
		return { canClaim = true, nextStreak = math.max(1, math.floor(streak)) + 1 }
	end
	return { canClaim = true, nextStreak = 1 }
end

-- The position in the reward list (1 to count) for a streak: it cycles after the last entry.
function DailyReward.slot(streak: number, count: number): number
	if not isFinite(streak) or not isFinite(count) or streak < 1 or count < 1 then
		return 1
	end
	return (math.floor(streak) - 1) % math.floor(count) + 1
end

-- The coins for a streak day (0 for an empty list).
function DailyReward.reward(streak: number, rewards: { number }): number
	if #rewards == 0 then
		return 0
	end
	return rewards[DailyReward.slot(streak, #rewards)] or 0
end

-- Problems of the config (empty when fine).
function DailyReward.validate(config: { rewards: { number }, secondsPerDay: number }): { string }
	local errors: { string } = {}
	if #config.rewards == 0 then
		table.insert(errors, "rewards must not be empty")
	end
	for index, coins in config.rewards do
		if not isFinite(coins) or coins <= 0 or coins % 1 ~= 0 then
			table.insert(errors, "reward " .. index .. " must be a whole number above 0")
		end
	end
	if not isFinite(config.secondsPerDay) or config.secondsPerDay <= 0 then
		table.insert(errors, "secondsPerDay must be above 0")
	end
	return errors
end

return DailyReward
