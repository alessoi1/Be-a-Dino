--!strict
-- Food values, to be balanced. Points are growth points; sizes are in studs.

export type FoodKind = {
	id: string,
	value: number,
	-- Relative chance when a piece is placed.
	weight: number,
	size: number,
	color: { r: number, g: number, b: number },
}

local kinds: { FoodKind } = {
	{ id = "small", value = 1, weight = 85, size = 1, color = { r = 120, g = 220, b = 90 } },
	{ id = "medium", value = 3, weight = 12, size = 1.6, color = { r = 255, g = 200, b = 60 } },
	{ id = "large", value = 10, weight = 3, size = 2.4, color = { r = 255, g = 100, b = 100 } },
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
	-- How many pieces exist at most.
	count = 450,
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
