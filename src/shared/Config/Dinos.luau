--!strict
-- The dino stages in order. A player turns into the next dino when the growth
-- points reach `minPoints`. Placeholder values, to be balanced.

export type DinoStage = {
	id: string,
	minPoints: number,
	scale: number,
	speed: number,
}

local stages: { DinoStage } = {
	{ id = "compy", minPoints = 0, scale = 1, speed = 20 },
	{ id = "raptor", minPoints = 50, scale = 1.8, speed = 22 },
	{ id = "stego", minPoints = 200, scale = 3, speed = 18 },
	{ id = "trex", minPoints = 600, scale = 5, speed = 20 },
}

return stages
