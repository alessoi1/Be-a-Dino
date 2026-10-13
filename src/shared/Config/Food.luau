--!strict
-- Food values, to be balanced. Points are growth points; sizes are in studs.

export type RGB = { r: number, g: number, b: number }
export type Vec = { x: number, y: number, z: number }

-- One look of a piece of food (all looks of a kind are worth the same). Until a mesh is uploaded
-- (`meshId`, 0 = not yet), `shape` draws a simple stand-in: "ball", "block", "cylinder" or "wedge".
export type FoodVariant = {
	id: string,
	shape: string,
	meshId: number,
	-- Only with a meshId: the mesh is drawn as big as the piece times this factor. 1 fits the meshes of
	-- tools/blender/food.py (about 1 stud long); change it when a mesh looks too big or too small.
	meshScale: Vec,
	-- Stretches the piece; multiplied by the size of the kind.
	scale: Vec,
	color: RGB,
	-- Relative chance among the looks of the kind.
	weight: number,
}

export type FoodKind = {
	id: string,
	value: number,
	-- Relative chance when a piece is placed.
	weight: number,
	size: number,
	-- Base color of the kind (effects and fallbacks); the looks have their own colors.
	color: RGB,
	variants: { FoodVariant },
}

local function rgb(r: number, g: number, b: number): RGB
	return { r = r, g = g, b = b }
end

local function vec(x: number, y: number, z: number): Vec
	return { x = x, y = y, z = z }
end

local function look(id: string, shape: string, color: RGB, scale: Vec, weight: number, meshId: number): FoodVariant
	return {
		id = id,
		shape = shape,
		meshId = meshId,
		meshScale = vec(1, 1, 1),
		scale = scale,
		color = color,
		weight = weight,
	}
end

-- The mesh of a look is the piece `food_<Id>` of assets/blender/food.fbx (berry = food_Berry, leaf =
-- food_Leaf, and so on; see docs/MODELLE.md). The ids come from the Studio import of that file; with `meshId = 0` the stand-in form is drawn.
--
-- Small pieces are berries and leaves, medium ones fruit and mushrooms, big ones meat, fish and
-- eggs. The looks are stand-ins from simple forms; real models replace them one by one by setting
-- `meshId` (see docs/MODELLE.md).
local kinds: { FoodKind } = {
	{
		id = "small",
		value = 1,
		weight = 85,
		size = 1,
		color = rgb(120, 220, 90),
		variants = {
			look("berry", "ball", rgb(206, 64, 112), vec(1, 1, 1), 40, 122433072184492),
			look("leaf", "wedge", rgb(110, 214, 84), vec(1.3, 0.5, 1.5), 35, 115143048934229),
			look("seed", "ball", rgb(226, 190, 96), vec(0.8, 0.8, 1.2), 25, 113653160260378),
		},
	},
	{
		id = "medium",
		value = 3,
		weight = 12,
		size = 1.6,
		color = rgb(255, 200, 60),
		variants = {
			look("fruit", "ball", rgb(255, 160, 40), vec(1, 1, 1), 40, 123324093222242),
			look("melon", "ball", rgb(120, 196, 70), vec(1.15, 0.95, 1.15), 30, 80821517762627),
			look("mushroom", "cylinder", rgb(236, 226, 206), vec(0.7, 1.1, 1.1), 30, 115113768657633),
		},
	},
	{
		id = "large",
		value = 10,
		weight = 3,
		size = 2.4,
		color = rgb(255, 100, 100),
		variants = {
			look("meat", "cylinder", rgb(204, 78, 70), vec(0.9, 1.4, 1.1), 40, 75342146736680),
			look("fish", "wedge", rgb(92, 160, 222), vec(1.6, 0.6, 0.9), 35, 115329182352529),
			look("egg", "ball", rgb(244, 236, 210), vec(0.9, 1.25, 0.9), 25, 97539013336945),
		},
	},
}

export type Zone = {
	radius: number,
	count: number,
	spawnClearance: number,
	weights: { [string]: number },
}

-- Round zones around the arena center. A zone has its own pieces (`count` of the total) that
-- always grow back inside it, with their own weights per kind (more good food than outside).
local zones: { [string]: Zone } = {
	-- The oasis: where the players meet. Nobody spawns within radius + spawnClearance.
	center = {
		radius = 60,
		count = 80,
		spawnClearance = 20,
		weights = { small = 40, medium = 40, large = 20 },
	},
}

return {
	kinds = kinds,
	zones = zones,
	-- How many pieces exist at most (the round arena is about 13 % larger than the old 500 x 500
	-- square, so the density stays the same).
	count = 510,
	-- Seconds until an eaten piece comes back.
	respawnSeconds = 8,
	-- Pickup radius in studs: base plus this much per unit of the dino scale.
	pickupBase = 2,
	pickupPerScale = 1.5,
	-- Distance to the walls in which no food is placed (studs).
	margin = 4,
	-- Seconds between two server pickup checks.
	checkInterval = 0.1,
}
