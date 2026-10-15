--!strict
-- The dino stages in order, from small to big. A player turns into the next dino when the size
-- (growth points) reaches `minPoints`. Placeholder values, to be balanced.
--
-- The rows are generated: `lune run tools/GenerateStages` (parameters at the top of that file).
-- 35 dinos, from Compy to T-Rex (more follow in later updates). Thresholds grow evenly from 1K
-- (second dino) to 1T (T-Rex, the last one), the figure grows from 1 to 8, the speed falls from
-- 22 to 18.
--
-- `foodUnit` is what one unit of food value is worth on this stage, so every stage needs about
-- the same number of food pieces (60 outside the oasis; see Config/Progress for the allowed
-- range). A small piece is worth 1 unit, a medium one 3 and a large one 10 (Config/Food). The
-- last stage has no next stage; its unit follows the stage before.
--
-- Every id needs a name in Strings.dinos and a look in Config/DinoLooks.

export type DinoStage = {
	id: string,
	minPoints: number,
	scale: number,
	speed: number,
	foodUnit: number,
}

local stages: { DinoStage } = {
	{ id = "compy", minPoints = 0, scale = 1, speed = 22, foodUnit = 11 },
	{ id = "dromaeo", minPoints = 1000, scale = 1.063, speed = 21.9, foodUnit = 10 },
	{ id = "raptor", minPoints = 1870, scale = 1.13, speed = 21.8, foodUnit = 18 },
	{ id = "troodon", minPoints = 3510, scale = 1.201, speed = 21.6, foodUnit = 34 },
	{ id = "oviraptor", minPoints = 6580, scale = 1.277, speed = 21.5, foodUnit = 63 },
	{ id = "coelo", minPoints = 12300, scale = 1.358, speed = 21.4, foodUnit = 119 },
	{ id = "deino", minPoints = 23100, scale = 1.443, speed = 21.3, foodUnit = 223 },
	{ id = "gallimimus", minPoints = 43300, scale = 1.534, speed = 21.2, foodUnit = 417 },
	{ id = "pachy", minPoints = 81100, scale = 1.631, speed = 21.1, foodUnit = 783 },
	{ id = "dilopho", minPoints = 152000, scale = 1.734, speed = 20.9, foodUnit = 1468 },
	{ id = "iguano", minPoints = 285000, scale = 1.843, speed = 20.8, foodUnit = 2748 },
	{ id = "para", minPoints = 534000, scale = 1.96, speed = 20.7, foodUnit = 5143 },
	{ id = "proto", minPoints = 1000000, scale = 2.083, speed = 20.6, foodUnit = 9603 },
	{ id = "ankylo", minPoints = 1870000, scale = 2.215, speed = 20.5, foodUnit = 18102 },
	{ id = "stego", minPoints = 3510000, scale = 2.354, speed = 20.4, foodUnit = 33885 },
	{ id = "allo", minPoints = 6580000, scale = 2.503, speed = 20.2, foodUnit = 63135 },
	{ id = "cerato", minPoints = 12300000, scale = 2.661, speed = 20.1, foodUnit = 119205 },
	{ id = "carno", minPoints = 23100000, scale = 2.828, speed = 20, foodUnit = 222958 },
	{ id = "trike", minPoints = 43300000, scale = 3.007, speed = 19.9, foodUnit = 417219 },
	{ id = "edmonto", minPoints = 81100000, scale = 3.196, speed = 19.8, foodUnit = 782561 },
	{ id = "theri", minPoints = 152000000, scale = 3.398, speed = 19.6, foodUnit = 1467991 },
	{ id = "baryonyx", minPoints = 285000000, scale = 3.612, speed = 19.5, foodUnit = 2748344 },
	{ id = "utah", minPoints = 534000000, scale = 3.84, speed = 19.4, foodUnit = 5143488 },
	{ id = "alberto", minPoints = 1000000000, scale = 4.082, speed = 19.3, foodUnit = 9602649 },
	{ id = "styraco", minPoints = 1870000000, scale = 4.34, speed = 19.2, foodUnit = 18101545 },
	{ id = "kentro", minPoints = 3510000000, scale = 4.614, speed = 19.1, foodUnit = 33885210 },
	{ id = "euoplo", minPoints = 6580000000, scale = 4.905, speed = 18.9, foodUnit = 63134658 },
	{ id = "maia", minPoints = 12300000000, scale = 5.214, speed = 18.8, foodUnit = 119205298 },
	{ id = "lambeo", minPoints = 23100000000, scale = 5.543, speed = 18.7, foodUnit = 222958057 },
	{ id = "diplo", minPoints = 43300000000, scale = 5.892, speed = 18.6, foodUnit = 417218543 },
	{ id = "camara", minPoints = 81100000000, scale = 6.264, speed = 18.5, foodUnit = 782560706 },
	{ id = "apato", minPoints = 152000000000, scale = 6.659, speed = 18.4, foodUnit = 1467991170 },
	{ id = "brachio", minPoints = 285000000000, scale = 7.079, speed = 18.2, foodUnit = 2748344371 },
	{ id = "mamenchi", minPoints = 534000000000, scale = 7.525, speed = 18.1, foodUnit = 5143487859 },
	{ id = "trex", minPoints = 1000000000000, scale = 8, speed = 18, foodUnit = 9637957164 },
}

return stages
