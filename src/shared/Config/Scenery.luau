--!strict
-- Look of the arena (light, ground, walls, waterhole, props), to be tuned by eye in Studio.
-- Colors are 0 to 255. Sizes are in studs. No Roblox types, so the pure placement logic stays testable.

export type RGB = { r: number, g: number, b: number }

-- The invisible solid shape of a prop. A "cylinder" is upright with `radius`; a "box" is
-- `width` (along the prop) by `depth`, turned like the prop. Both are `height` tall.
export type Collider = {
	shape: "cylinder" | "box",
	radius: number,
	width: number,
	depth: number,
	height: number,
}

export type PropKind = {
	id: string,
	count: number,
	-- Free space around the prop (studs): nothing else is placed inside it and nobody spawns in it.
	radius: number,
	-- Roblox asset id of the imported mesh (from props.fbx). 0 = not imported yet, a simple
	-- stand-in from parts is built instead.
	meshId: number,
	-- Stand-in shape until the mesh is there: "tree", "bush", "rock" or "log".
	fallback: string,
	-- Stand-in size (studs, the tallest side) and mesh scale factor.
	fallbackSize: number,
	scale: number,
	-- Color of the stand-in.
	color: RGB,
	-- What blocks dinos. nil = they walk through it (bushes and ferns are cover, not walls).
	collider: Collider?,
}

local function rgb(r: number, g: number, b: number): RGB
	return { r = r, g = g, b = b }
end

local function cylinder(radius: number, height: number): Collider
	return { shape = "cylinder", radius = radius, width = 0, depth = 0, height = height }
end

local function box(width: number, depth: number, height: number): Collider
	return { shape = "box", radius = 0, width = width, depth = depth, height = height }
end

local props: { PropKind } = {
	{
		id = "Tree",
		count = 26,
		radius = 5,
		meshId = 140099709831502,
		fallback = "tree",
		fallbackSize = 13,
		scale = 1,
		color = rgb(60, 118, 52),
		collider = cylinder(1.3, 40),
	},
	{
		id = "Palm",
		count = 14,
		radius = 4.5,
		meshId = 122342786093663,
		fallback = "tree",
		fallbackSize = 10,
		scale = 1,
		color = rgb(80, 146, 58),
		collider = cylinder(1.1, 40),
	},
	{
		id = "RockBig",
		count = 10,
		radius = 5,
		meshId = 117270752612238,
		fallback = "rock",
		fallbackSize = 6,
		scale = 1,
		color = rgb(108, 102, 94),
		collider = cylinder(4, 14),
	},
	{
		id = "Rock",
		count = 22,
		radius = 2.2,
		meshId = 137894705922291,
		fallback = "rock",
		fallbackSize = 2.6,
		scale = 1,
		color = rgb(126, 121, 112),
		collider = cylinder(1.8, 6),
	},
	{
		id = "Bush",
		count = 10,
		radius = 2.5,
		meshId = 80769098035445,
		fallback = "bush",
		fallbackSize = 3,
		scale = 1,
		color = rgb(62, 108, 54),
	},
	{
		id = "Fern",
		count = 12,
		radius = 2,
		meshId = 113917993373751,
		fallback = "bush",
		fallbackSize = 2.4,
		scale = 1,
		color = rgb(84, 156, 64),
	},
	{
		id = "Log",
		count = 8,
		radius = 4,
		meshId = 118824048668773,
		fallback = "log",
		fallbackSize = 7.5,
		scale = 1,
		color = rgb(100, 72, 50),
		collider = box(7, 1.8, 4),
	},
}

return {
	-- Same seed, same arena on every server (easier to debug).
	seed = 20261012,

	-- Warm light in the late afternoon.
	lighting = {
		clockTime = 16.9,
		brightness = 2.4,
		ambient = rgb(92, 86, 76),
		outdoorAmbient = rgb(128, 122, 108),
		colorShiftTop = rgb(255, 214, 160),
		exposureCompensation = 0,
	},
	-- Light haze over the arena.
	atmosphere = {
		density = 0.3,
		offset = 0.25,
		color = rgb(214, 192, 162),
		decay = rgb(220, 168, 120),
		glare = 0.25,
		haze = 1.6,
	},
	colorCorrection = {
		brightness = 0.02,
		contrast = 0.08,
		saturation = 0.14,
		tint = rgb(255, 244, 228),
	},

	ground = {
		base = rgb(96, 142, 70),
		-- Lighter and darker patches on the floor (flat discs, no collision).
		patchCount = 80,
		patchMinRadius = 6,
		patchMaxRadius = 22,
		patchColors = { rgb(124, 170, 86), rgb(80, 122, 62), rgb(142, 152, 86) },
		-- Heights of the stacked layers above the floor (studs), so overlapping discs do not flicker.
		patchLevels = 3,
		patchThickness = 0.04,
		patchLevelStep = 0.03,
		-- Dirt paths from the waterhole to the walls.
		pathCount = 5,
		pathWidth = 7,
		pathStep = 18,
		-- Largest turn per step in radians.
		pathWobble = 0.22,
		pathColor = rgb(152, 122, 86),
		pathHeight = 0.12,
		pathThickness = 0.04,
		-- Distance from the wall where a path ends.
		pathWallInset = 10,
		-- Distance from the wall where no patch center lies.
		patchMargin = 4,
	},

	walls = {
		-- The wall part itself (solid): dark rock.
		color = rgb(84, 76, 68),
		material = "Slate",
		-- Rock blocks in front of the wall (looks only, no collision).
		rockSpacing = 16,
		rockMinWidth = 9,
		rockMaxWidth = 16,
		rockMinHeight = 14,
		rockMaxHeight = 30,
		rockMinDepth = 5,
		rockMaxDepth = 9,
		-- Random shift of a rock along the wall (share of the spacing).
		rockJitter = 0.35,
		-- Largest turn of a rock around the upright axis in radians.
		rockYaw = 0.35,
		rockColors = { rgb(104, 98, 90), rgb(122, 112, 98), rgb(88, 82, 76), rgb(112, 108, 84) },
		rockMaterial = "Slate",
	},

	-- The waterhole in the middle (its size is the center zone in Config/Food).
	waterhole = {
		waterColor = rgb(64, 138, 196),
		waterTransparency = 0.25,
		waterMaterial = "Glass",
		-- Height of the shore above the floor; the water lies on top of it. Above the paths.
		baseHeight = 0.18,
		shoreThickness = 0.06,
		waterThickness = 0.3,
		-- Sandy shore between water and stone ring.
		shoreWidth = 5,
		shoreColor = rgb(196, 176, 126),
		-- Stone ring at the edge.
		ringStones = 36,
		ringStoneMin = 4,
		ringStoneMax = 8,
		ringStoneHeight = 2.6,
		ringColors = { rgb(120, 114, 104), rgb(104, 98, 90), rgb(134, 126, 112) },
	},

	placement = {
		-- Random spots tried for each prop; the one with the most free space wins.
		candidates = 12,
		-- No prop closer to the walls than this (studs, plus its own radius).
		wallMargin = 16,
		-- Free space around the waterhole outside its stone ring (studs).
		waterholeClearance = 14,
		-- Nobody spawns closer to a prop than its radius plus this.
		spawnGap = 3,
		-- Random size change of a prop (0.1 = plus or minus 10 %) and brightness change.
		sizeJitter = 0.12,
		brightnessJitter = 0.07,
	},

	-- Shallow ponds (walkable, looks only). Props keep `clearance` studs away from them.
	ponds = {
		count = 4,
		minRadius = 14,
		maxRadius = 24,
		clearance = 6,
		shoreWidth = 3,
		shoreColor = rgb(196, 176, 126),
		waterColor = rgb(70, 146, 190),
		waterTransparency = 0.3,
		waterMaterial = "Glass",
		-- Heights above the floor (studs): above the dirt paths.
		baseHeight = 0.18,
		shoreThickness = 0.05,
		waterThickness = 0.12,
	},
	-- Chokepoints: two big rocks with a gap. Dinos of a body width up to about a third of the gap
	-- fit through (small ones slip in, big ones are shut out). `rockId` is a prop with a collider.
	gates = {
		count = 8,
		rockId = "RockBig",
		gaps = { 7, 12, 20 },
		-- Free space around a gate in addition to its reach (studs).
		clearance = 4,
	},
	-- Cover: groups of bushes and ferns, walkable, so dinos can hide in them. Only the look hides.
	clusters = {
		count = 6,
		minMembers = 5,
		maxMembers = 8,
		-- Members lie within this distance of the middle (studs).
		spread = 9,
		ids = { "Bush", "Fern" },
	},
	-- Vines hanging from the lowest ring of the dome.
	vines = {
		count = 30,
		minLength = 14,
		maxLength = 34,
		maxTilt = 0.08,
		thickness = 0.5,
		-- Leaf ball at the end (studs) and how far the vine hangs inside the dome (share of the radius).
		leafSize = 3.2,
		inset = 0.985,
		stemColor = rgb(52, 92, 44),
		leafColor = rgb(76, 150, 62),
	},

	props = props,
}
