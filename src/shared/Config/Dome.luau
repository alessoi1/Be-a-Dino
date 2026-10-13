--!strict
-- Look of the glass dome over the arena (frame and glass), to be tuned by eye in Studio. Colors are
-- 0 to 255. Sizes are in studs. The frame is built from straight beams (see DomeShape); fewer
-- beams are cheaper on phones.

export type RGB = { r: number, g: number, b: number }

local function rgb(r: number, g: number, b: number): RGB
	return { r = r, g = g, b = b }
end

return {
	-- The glass: one big transparent half sphere, seen from outside (from the inside Roblox does not
	-- draw it, so the players look through the frame at the sky).
	glass = {
		color = rgb(170, 214, 224),
		transparency = 0.86,
		reflectance = 0.12,
		material = "SmoothPlastic",
	},
	frame = {
		color = rgb(66, 84, 82),
		material = "Metal",
		-- Thickness of a beam.
		thickness = 2.4,
		-- Ribs from the foot to the top and the beams each is cut into.
		ribs = 12,
		ribSegments = 10,
		-- Rings (angle above the floor in degrees), the lowest sits above the wall.
		ringElevations = { 8, 28, 48, 68, 82 },
		-- Beams of a ring: the most at the foot, the fewest at the top.
		ringMaxSegments = 48,
		ringMinSegments = 16,
	},
}
