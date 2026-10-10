--!strict
-- The dino stages in order. A player turns into the next dino when the size (growth points)
-- reaches `minPoints`. Placeholder values, to be balanced; for now the four dinos are spread
-- 0 / 1K / 1M / 1B, the real list of about 50 dinos comes with the next step.
--
-- `foodUnit` is what one unit of food value is worth on this stage, so every stage needs about
-- the same number of food pieces (see Config/Progress for the allowed range). A small piece is
-- worth 1 unit, a medium one 3 and a large one 10 (Config/Food). The last stage has no next
-- stage; its unit follows the stage before.

export type DinoStage = {
	id: string,
	minPoints: number,
	scale: number,
	speed: number,
	foodUnit: number,
}

local stages: { DinoStage } = {
	{ id = "compy", minPoints = 0, scale = 1, speed = 20, foodUnit = 17 },
	{ id = "raptor", minPoints = 1000, scale = 1.8, speed = 22, foodUnit = 16540 },
	{ id = "stego", minPoints = 1000000, scale = 3, speed = 18, foodUnit = 16539735 },
	{ id = "trex", minPoints = 1000000000, scale = 5, speed = 20, foodUnit = 16556291 },
}

return stages
