--!strict
-- Pure coin rules: what a newly reached stage gives and how coins are added with an upper
-- limit. Coins are earned by growing and never bought with Robux. No Roblox services.

local Coins = {}

local function isFinite(value: any): boolean
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

-- Coins for reaching the stage with this number (stage 1 is where everyone starts, so it gives 0).
function Coins.forStage(stageIndex: number, factor: number): number
	if not isFinite(stageIndex) or not isFinite(factor) or stageIndex <= 1 or factor <= 0 then
		return 0
	end
	return math.floor(stageIndex) * math.floor(factor)
end

-- Coins for all stages above `fromIndex` up to and including `toIndex` (skipped stages count).
function Coins.forStages(fromIndex: number, toIndex: number, factor: number): number
	if not isFinite(fromIndex) or not isFinite(toIndex) or toIndex <= fromIndex then
		return 0
	end
	local total = 0
	for index = math.floor(fromIndex) + 1, math.floor(toIndex) do
		total += Coins.forStage(index, factor)
	end
	return total
end

-- Coins for eating a player who was on the given stage. `multiplier` is 1 normally and higher
-- for a player with a bounty.
function Coins.forKill(victimStageIndex: number, factor: number, multiplier: number): number
	if
		not isFinite(victimStageIndex)
		or not isFinite(factor)
		or not isFinite(multiplier)
		or victimStageIndex < 1
		or factor <= 0
		or multiplier <= 0
	then
		return 0
	end
	return math.floor(math.floor(victimStageIndex) * factor * multiplier)
end

-- Returns the new amount: `coins` plus `amount`, never above `max`. Invalid or non-positive
-- amounts change nothing.
function Coins.add(coins: number, amount: number, max: number): number
	if not isFinite(coins) or coins < 0 then
		return 0
	end
	if not isFinite(amount) or amount <= 0 then
		return math.min(coins, max)
	end
	return math.min(max, math.floor(coins + amount))
end

return Coins
