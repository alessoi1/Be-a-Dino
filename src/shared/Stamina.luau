--!strict
-- Pure stamina logic for sprinting. No Roblox services, no logging.

export type Config = {
	staminaMax: number,
	staminaDrainPerSecond: number,
	staminaRegenPerSecond: number,
	staminaRegenDelay: number,
	staminaMinToStart: number,
}

export type State = {
	value: number,
	-- Seconds since the player stopped sprinting.
	idle: number,
	sprinting: boolean,
}

local Stamina = {}

function Stamina.new(config: Config): State
	return { value = config.staminaMax, idle = 0, sprinting = false }
end

-- Advances the state by `dt` seconds. Returns the new state (the old one is not
-- changed) and whether the player is sprinting now. Invalid `dt` changes nothing.
function Stamina.step(config: Config, state: State, wantsSprint: boolean, dt: number): (State, boolean)
	if dt ~= dt or dt < 0 or dt == math.huge then
		return state, state.sprinting
	end

	local canSprint = wantsSprint and state.value > 0 and (state.sprinting or state.value >= config.staminaMinToStart)
	if canSprint then
		local value = state.value - config.staminaDrainPerSecond * dt
		if value <= 0 then
			return { value = 0, idle = 0, sprinting = false }, false
		end
		return { value = value, idle = 0, sprinting = true }, true
	end

	local idle = state.idle + dt
	local regenSeconds = math.max(0, idle - math.max(state.idle, config.staminaRegenDelay))
	local value = math.min(config.staminaMax, state.value + config.staminaRegenPerSecond * regenSeconds)
	return { value = value, idle = idle, sprinting = false }, false
end

-- Stamina as a share between 0 and 1 (for the display).
function Stamina.fraction(config: Config, state: State): number
	return math.clamp(state.value / config.staminaMax, 0, 1)
end

return Stamina
