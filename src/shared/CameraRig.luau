--!strict
-- Pure camera math: distance from the dino scale and smooth following.
-- No Roblox services, no logging.

export type Config = {
	distancePerScale: number,
	minDistance: number,
	smoothing: number,
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

return CameraRig
