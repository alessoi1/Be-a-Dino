--!strict
-- Pure helpers for the eating effects: how many particles a piece gives and a small rate limiter
-- so a crowd of eaters cannot flood the device with effects. No Roblox services, no logging.

export type Config = { emitBase: number, emitPerDoubling: number, emitMax: number }

-- State of the limiter: when the current second started and how many effects it already had.
export type Window = { startedAt: number, count: number }

local FoodEffect = {}

-- Number of particles for a piece of this value: more for more valuable food. Invalid values give
-- the base number.
function FoodEffect.emitCount(config: Config, value: number): number
	if value ~= value or value <= 1 or value == math.huge then
		return config.emitBase
	end
	local count = config.emitBase + config.emitPerDoubling * math.log(value, 2)
	return math.clamp(math.floor(count + 0.5), config.emitBase, config.emitMax)
end

function FoodEffect.newWindow(): Window
	return { startedAt = -math.huge, count = 0 }
end

-- Whether one more effect is allowed at time `now` (seconds): at most `maxPerSecond` within a
-- second. Counts the effect when it is allowed. A clock that goes backwards starts a new second.
function FoodEffect.allow(window: Window, now: number, maxPerSecond: number): boolean
	if now ~= now or maxPerSecond <= 0 then
		return false
	end
	if now - window.startedAt >= 1 or now < window.startedAt then
		window.startedAt = now
		window.count = 0
	end
	if window.count >= maxPerSecond then
		return false
	end
	window.count += 1
	return true
end

return FoodEffect
