--!strict
-- Pure schedule of the food frenzy: from the seconds since the server start it tells whether a
-- frenzy runs and how long it still lasts or how long until the next one. No Roblox services.

local Frenzy = {}

export type Config = {
	calmSeconds: number,
	durationSeconds: number,
	firstCalmSeconds: number,
	pointsFactor: number,
}

export type Phase = {
	active: boolean,
	-- Seconds until the running frenzy ends (0 when none runs).
	secondsLeft: number,
	-- Seconds until the next frenzy starts (0 while one runs).
	secondsToNext: number,
}

local function isFinite(value: any): boolean
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

-- `elapsed` is the time since the server start. The first frenzy starts after `firstCalmSeconds`;
-- after each frenzy comes a calm period of `calmSeconds`. Invalid input gives "no frenzy".
function Frenzy.phase(elapsed: number, config: Config): Phase
	local calm = { active = false, secondsLeft = 0, secondsToNext = math.max(0, config.firstCalmSeconds) }
	if not isFinite(elapsed) or elapsed < 0 or config.durationSeconds <= 0 or config.calmSeconds <= 0 then
		return calm
	end
	if elapsed < config.firstCalmSeconds then
		calm.secondsToNext = config.firstCalmSeconds - elapsed
		return calm
	end
	local cycle = config.durationSeconds + config.calmSeconds
	local into = (elapsed - config.firstCalmSeconds) % cycle
	if into < config.durationSeconds then
		return { active = true, secondsLeft = config.durationSeconds - into, secondsToNext = 0 }
	end
	return { active = false, secondsLeft = 0, secondsToNext = cycle - into }
end

-- The factor for points from food: the config factor while a frenzy runs, otherwise 1.
function Frenzy.factor(phase: Phase, config: Config): number
	if phase.active and isFinite(config.pointsFactor) and config.pointsFactor > 1 then
		return config.pointsFactor
	end
	return 1
end

-- Problems of the config (empty when fine).
function Frenzy.validate(config: Config): { string }
	local errors: { string } = {}
	for _, field in { "calmSeconds", "durationSeconds" } do
		local value = (config :: any)[field]
		if not isFinite(value) or value <= 0 then
			table.insert(errors, field .. " must be above 0")
		end
	end
	if not isFinite(config.firstCalmSeconds) or config.firstCalmSeconds < 0 then
		table.insert(errors, "firstCalmSeconds must be 0 or more")
	end
	if not isFinite(config.pointsFactor) or config.pointsFactor < 1 then
		table.insert(errors, "pointsFactor must be at least 1")
	end
	return errors
end

return Frenzy
