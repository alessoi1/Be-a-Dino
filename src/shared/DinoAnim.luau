--!strict
-- Pure walk animation of the dino limbs: how far a leg or the tail is turned at a given time and
-- speed. The client turns the joints with these angles. No Roblox services, no logging.

export type Config = {
	strideLength: number,
	maxCyclesPerSecond: number,
	fullSpeed: number,
	standSpeed: number,
	legSwing: number,
	quadLegSwing: number,
	tailSwing: number,
	tailIdleSwing: number,
	tailIdleSeconds: number,
	breathLift: number,
	bobLift: number,
	walkLean: number,
	eatPitch: number,
	eatDip: number,
	eatSeconds: number,
	eatReach: number,
}

-- `phase` runs through one full step cycle in 2 pi; `idle` counts seconds for the slow sway.
export type State = { phase: number, idle: number }

-- How the whole body of a dino is moved: `pitch` (radians, negative = nose down) and `lift` (studs at
-- scale 1, positive = up) at the middle of the figure.
export type Pose = { pitch: number, lift: number }

export type Limb = "legLeft" | "legRight" | "legFrontLeft" | "legFrontRight" | "legBackLeft" | "legBackRight" | "tail"

local TWO_PI = 2 * math.pi

local DinoAnim = {}

DinoAnim.LIMBS = {
	legLeft = true,
	legRight = true,
	legFrontLeft = true,
	legFrontRight = true,
	legBackLeft = true,
	legBackRight = true,
	tail = true,
	-- The joint of the whole body (see AppearanceService), moved by bodyPose.
	body = true,
}

function DinoAnim.newState(): State
	return { phase = 0, idle = 0 }
end

local function isFinite(value: number): boolean
	return value == value and value ~= math.huge and value ~= -math.huge
end

-- 0 when standing, 1 at full speed: how much the limbs swing. Invalid or negative speed is 0.
function DinoAnim.amount(config: Config, speed: number): number
	if not isFinite(speed) or speed <= config.standSpeed then
		return 0
	end
	return math.clamp(speed / config.fullSpeed, 0, 1)
end

-- The next state after `dt` seconds at `speed` for a dino of the given scale. The step cycle
-- advances with the distance walked (a bigger dino takes longer steps), so the feet do not slide,
-- but never faster than `maxCyclesPerSecond`: running faster takes longer strides.
function DinoAnim.step(config: Config, state: State, speed: number, scale: number, dt: number): State
	if not isFinite(dt) or dt <= 0 or not isFinite(scale) or scale <= 0 then
		return state
	end
	local cycles = 0
	if isFinite(speed) and speed > config.standSpeed then
		cycles = math.min(speed / (config.strideLength * scale), config.maxCyclesPerSecond)
	end
	local phase = (state.phase + TWO_PI * cycles * dt) % TWO_PI
	local idle = (state.idle + dt) % config.tailIdleSeconds
	return { phase = phase, idle = idle }
end

-- The angle of a limb in radians. Legs turn around the sideways axis (positive swings the foot
-- forward), the tail around the vertical axis. The legs swing against each other; the tail sways
-- once per step cycle while walking and slowly when standing.
function DinoAnim.angle(config: Config, state: State, limb: string, amount: number): number
	local moving = math.clamp(amount, 0, 1)
	if limb == "legLeft" then
		return math.sin(state.phase) * config.legSwing * moving
	elseif limb == "legRight" then
		return math.sin(state.phase + math.pi) * config.legSwing * moving
	elseif limb == "legFrontLeft" or limb == "legBackRight" then
		-- The four-legged walk: the legs that are diagonal to each other swing together.
		return math.sin(state.phase) * config.quadLegSwing * moving
	elseif limb == "legFrontRight" or limb == "legBackLeft" then
		return math.sin(state.phase + math.pi) * config.quadLegSwing * moving
	elseif limb == "tail" then
		local walking = math.sin(state.phase) * config.tailSwing * moving
		local standing = math.sin(state.idle / config.tailIdleSeconds * TWO_PI) * config.tailIdleSwing * (1 - moving)
		return walking + standing
	end
	return 0
end

-- How far the munch has come at time `now`: 0 at the start, 1 at the end, nil when it is over (or
-- never began, or the clock is invalid).
function DinoAnim.eatProgress(config: Config, startedAt: number?, now: number): number?
	if startedAt == nil or not isFinite(startedAt) or not isFinite(now) or config.eatSeconds <= 0 then
		return nil
	end
	local progress = (now - startedAt) / config.eatSeconds
	if progress < 0 or progress >= 1 then
		return nil
	end
	return progress
end

-- The movement of the whole body. Standing it breathes (rises and falls slowly); walking it bobs
-- twice per step and leans forward a little; while munching (`eating` = progress from eatProgress,
-- nil when not) it nods down and dips, smoothly in and out.
function DinoAnim.bodyPose(config: Config, state: State, amount: number, eating: number?): Pose
	local moving = math.clamp(amount, 0, 1)
	local breath = math.sin(state.idle / config.tailIdleSeconds * TWO_PI) * config.breathLift * (1 - moving)
	local bob = math.cos(state.phase * 2) * config.bobLift * moving
	local pitch = -config.walkLean * moving
	local lift = breath + bob
	if eating ~= nil then
		local pulse = math.sin(math.clamp(eating, 0, 1) * math.pi)
		pitch -= config.eatPitch * pulse
		lift -= config.eatDip * pulse
	end
	return { pitch = pitch, lift = lift }
end

-- Returns a list of problems (empty when the values are usable).
function DinoAnim.validate(config: Config): { string }
	local errors: { string } = {}
	for _, key in { "strideLength", "maxCyclesPerSecond", "fullSpeed", "tailIdleSeconds" } do
		local value = (config :: any)[key]
		if not isFinite(value) or value <= 0 then
			table.insert(errors, key .. " must be above 0")
		end
	end
	for _, key in { "eatSeconds", "eatReach" } do
		local value = (config :: any)[key]
		if not isFinite(value) or value <= 0 then
			table.insert(errors, key .. " must be above 0")
		end
	end
	for _, key in { "breathLift", "bobLift", "walkLean", "eatPitch", "eatDip" } do
		local value = (config :: any)[key]
		if not isFinite(value) or value < 0 then
			table.insert(errors, key .. " must be 0 or more")
		end
	end
	if isFinite(config.eatPitch) and config.eatPitch > math.pi / 2 then
		table.insert(errors, "eatPitch is too large")
	end
	for _, key in { "standSpeed", "legSwing", "quadLegSwing", "tailSwing", "tailIdleSwing" } do
		local value = (config :: any)[key]
		if not isFinite(value) or value < 0 then
			table.insert(errors, key .. " must be 0 or more")
		end
	end
	for _, key in { "legSwing", "quadLegSwing" } do
		local value = (config :: any)[key]
		if isFinite(value) and value > math.pi / 2 then
			table.insert(errors, key .. " is too large")
		end
	end
	return errors
end

return DinoAnim
