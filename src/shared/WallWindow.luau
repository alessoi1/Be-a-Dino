--!strict
-- Pure helper for the viewing window in the wall ring: which wall pieces are glass, and whether a
-- direction (seen from the arena center) looks through the window. The window is centered on
-- `centerDegrees` (0 = +X, 90 = +Z) and `windowSegments` pieces wide (best an even number, so
-- the window is symmetrical). No Roblox services, no logging.

local TWO_PI = math.pi * 2
local EPSILON = 1e-9

local WallWindow = {}

-- The angle between two directions, between -pi and pi.
local function difference(angle: number, center: number): number
	local diff = (angle - center) % TWO_PI
	if diff > math.pi then
		diff -= TWO_PI
	end
	return diff
end

-- Whether piece `index` (1 to `count`) of the wall ring is part of the window.
function WallWindow.isWindowPiece(index: number, count: number, centerDegrees: number, windowSegments: number): boolean
	if count <= 0 or windowSegments <= 0 then
		return false
	end
	local angle = (index - 0.5) / count * TWO_PI
	local half = windowSegments / 2 * (TWO_PI / count)
	return math.abs(difference(angle, math.rad(centerDegrees))) < half - EPSILON
end

-- Whether a direction (radians) lies in the window or within `extraSegments` pieces beside it.
-- Used to keep the rocks in front of the wall away from the window.
function WallWindow.looksThrough(
	angle: number,
	count: number,
	centerDegrees: number,
	windowSegments: number,
	extraSegments: number
): boolean
	if count <= 0 or windowSegments <= 0 then
		return false
	end
	local half = (windowSegments / 2 + math.max(0, extraSegments)) * (TWO_PI / count)
	return math.abs(difference(angle, math.rad(centerDegrees))) < half
end

return WallWindow
