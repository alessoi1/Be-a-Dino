--!strict
-- The lobby beside the glass dome: a platform with glowing circles. Standing in the play circle
-- joins the arena, the other circles open the shop, the dinodex and the boosters.
-- Starting values, to be balanced. Sizes and positions are in studs. The platform stands south
-- (+Z) of the dome and looks into the arena through the window in the wall. The zone
-- coordinates are relative to the middle of the platform.

export type ZoneConfig = {
	id: string,
	-- "play" joins the arena, "window" opens a window while the player stands in it.
	kind: "play" | "window",
	x: number,
	z: number,
	radius: number,
	-- Seconds a player has to stand in the circle before it triggers (0 = at once).
	dwell: number,
	color: { r: number, g: number, b: number },
}

local zones: { ZoneConfig } = {
	{ id = "play", kind = "play", x = 0, z = 0, radius = 12, dwell = 2, color = { r = 90, g = 220, b = 120 } },
	{ id = "shop", kind = "window", x = -45, z = 0, radius = 7, dwell = 0, color = { r = 255, g = 190, b = 60 } },
	{ id = "dex", kind = "window", x = 0, z = 45, radius = 7, dwell = 0, color = { r = 90, g = 170, b = 255 } },
	{ id = "boost", kind = "window", x = 45, z = 0, radius = 7, dwell = 0, color = { r = 200, g = 110, b = 255 } },
}

return {
	-- Side length of the square lobby platform.
	size = 140,
	-- Middle of the platform in the world. The north part (`northInset` studs) of the floor lies
	-- hidden under the arena wall, so no hole is left between the round wall and the straight
	-- platform edge. centerZ = arena radius + wall thickness - northInset + size / 2 (a test checks it).
	centerX = 0,
	centerZ = 350,
	northInset = 24,
	-- Height of the lobby floor (its top). A hair below the arena floor, so the two never flicker
	-- where they overlap.
	height = -0.05,
	floorThickness = 2,
	railingHeight = 8,
	railingThickness = 1,
	-- Distance to the platform edge and to the circles in which new arrivals are placed.
	spawnMargin = 8,
	spawnClearance = 6,
	-- Most players in the arena at the same time; more wait in the lobby.
	maxPlaying = 24,
	-- Seconds the "back to lobby" button takes, so nobody escapes a fight at once.
	leaveSeconds = 5,
	-- Seconds between two server checks of the circles.
	checkInterval = 0.1,
	-- A lobby player this far below the floor is put back on the platform.
	fallTolerance = 10,
	zones = zones,
}
