--!strict
-- The research station look of the lobby: roof, pillars, walls, lamps, benches, planters and the
-- fossil skeleton. To be tuned by eye in Studio. Positions (x, z) are relative to the middle of the
-- platform (Config/Lobby), x to the east and z to the south (the dome and its window lie at the
-- north, z about -46 at the wall). Sizes and heights are in studs; heights count from the floor.

export type RGB = { r: number, g: number, b: number }
export type Spot = { x: number, z: number }

local function rgb(r: number, g: number, b: number): RGB
	return { r = r, g = g, b = b }
end

return {
	colors = {
		metal = rgb(66, 84, 82),
		darkMetal = rgb(44, 56, 60),
		wall = rgb(40, 66, 74),
		wood = rgb(142, 102, 70),
		planter = rgb(120, 96, 78),
		leaf = rgb(70, 150, 70),
		leafLight = rgb(104, 184, 84),
		bone = rgb(232, 222, 196),
		lamp = rgb(255, 232, 170),
		ring = rgb(96, 112, 120),
		glass = rgb(170, 214, 224),
	},

	-- The roof reaches from the front (toward the window) to the back wall and a little past the sides.
	roof = {
		height = 26,
		thickness = 1.5,
		frontZ = -38,
		backZ = 70,
		halfWidth = 72,
		-- The middle strip is glass, so the sun and the dome stay visible.
		skylightHalfWidth = 30,
		glassTransparency = 0.55,
	},
	pillars = {
		{ x = -64, z = -34 },
		{ x = 64, z = -34 },
		{ x = -64, z = 20 },
		{ x = 64, z = 20 },
		{ x = -64, z = 64 },
		{ x = 64, z = 64 },
	},
	pillarSize = 2.4,
	pillarRadius = 2.5,

	-- The wall behind the leaderboards with the sign, and the low walls at the sides.
	backWall = { height = 30, thickness = 1.5, signSeconds = 0 },
	sideWallHeight = 3,

	-- Lamps hang from the roof (a few lights only, they cost frame time on phones).
	lamps = { { x = -36, z = -8 }, { x = 36, z = -8 }, { x = -36, z = 44 }, { x = 36, z = 44 } },
	lampDrop = 5,
	lampRange = 34,
	lampBrightness = 1.3,

	-- Benches for watching the arena through the window; they face the window (north).
	benches = { { x = -30, z = -30 }, { x = 0, z = -30 }, { x = 30, z = -30 } },
	benchRadius = 5,

	-- Planters with bushes.
	planters = {
		{ x = -62, z = -30 },
		{ x = 62, z = -30 },
		{ x = -62, z = 22 },
		{ x = 62, z = 22 },
		{ x = -22, z = 58 },
		{ x = 22, z = 58 },
	},
	planterRadius = 3.2,

	-- The fossil skeleton on its pedestal (lying along x).
	skeleton = { x = -44, z = 48, radius = 20 },

	-- The ring around the play circle (extra radius beyond the circle).
	ringExtra = 3,

	-- Gap kept free between decoration and the circles, and to the edges of the platform (studs).
	zoneGap = 4,
	edgeGap = 1,
}
