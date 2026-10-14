--!strict
-- Pure camera math: distance from the dino scale and smooth following.
-- No Roblox services, no logging.

export type Config = {
	distancePerScale: number,
	minDistance: number,
	smoothing: number,
	deathHeight: number,
	deathRadius: number,
	deathTurnSpeed: number,
	deathBlendSeconds: number,
}

local CameraRig = {}

function CameraRig.distanceFor(config: Config, scale: number): number
	if scale ~= scale or scale <= 0 then
		return config.minDistance
	end
	return math.max(config.minDistance, config.distancePerScale * scale)
end

-- Moves `current` toward `target`; the step is frame-rate independent and never overshoots.
function CameraRig.smooth(config: Config, current: number, target: number, dt: number): number
	if dt ~= dt or dt < 0 or dt == math.huge then
		return current
	end
	local factor = 1 - math.exp(-config.smoothing * dt)
	return current + (target - current) * factor
end

-- Where the camera hovers over the arena `seconds` after the view started: high above the middle,
-- turning slowly around it. The arena middle is the origin; invalid time counts as 0.
function CameraRig.deathView(config: Config, seconds: number): (number, number, number)
	local time = if seconds ~= seconds or seconds == math.huge or seconds == -math.huge then 0 else seconds
	local angle = time * config.deathTurnSpeed
	return math.sin(angle) * config.deathRadius, config.deathHeight, math.cos(angle) * config.deathRadius
end

-- How far the camera is on its way to the death view (0 = at the dino, 1 = in the view), `seconds`
-- after the window opened (or closed, counting down). Smooth at both ends.
function CameraRig.blend(config: Config, seconds: number): number
	if seconds ~= seconds or config.deathBlendSeconds <= 0 then
		return 1
	end
	local share = math.clamp(seconds / config.deathBlendSeconds, 0, 1)
	return share * share * (3 - 2 * share)
end

return CameraRig
