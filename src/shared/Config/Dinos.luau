--!strict
-- The dino stages in order, from small to big. A player turns into the next dino when the size
-- (growth points) reaches `minPoints`. Placeholder values, to be balanced.
--
-- The rows are generated: `lune run tools/GenerateStages` (parameters at the top of that file).
-- Thresholds grow evenly from 1K (second dino) to 1T (last dino), the figure grows from 1 to 8,
-- the speed falls from 22 to 18.
--
-- `foodUnit` is what one unit of food value is worth on this stage, so every stage needs about
-- the same number of food pieces (see Config/Progress for the allowed range). A small piece is
-- worth 1 unit, a medium one 3 and a large one 10 (Config/Food). The last stage has no next
-- stage; its unit follows the stage before.
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
	{ id = "compy", minPoints = 0, scale = 1, speed = 22, foodUnit = 17 },
	{ id = "dromaeo", minPoints = 1000, scale = 1.043, speed = 21.9, foodUnit = 9 },
	{ id = "raptor", minPoints = 1540, scale = 1.089, speed = 21.8, foodUnit = 14 },
	{ id = "troodon", minPoints = 2370, scale = 1.136, speed = 21.8, foodUnit = 21 },
	{ id = "oviraptor", minPoints = 3650, scale = 1.185, speed = 21.7, foodUnit = 33 },
	{ id = "coelo", minPoints = 5620, scale = 1.236, speed = 21.6, foodUnit = 50 },
	{ id = "deino", minPoints = 8660, scale = 1.29, speed = 21.5, foodUnit = 77 },
	{ id = "gallimimus", minPoints = 13300, scale = 1.346, speed = 21.4, foodUnit = 119 },
	{ id = "pachy", minPoints = 20500, scale = 1.404, speed = 21.3, foodUnit = 184 },
	{ id = "dilopho", minPoints = 31600, scale = 1.465, speed = 21.3, foodUnit = 283 },
	{ id = "iguano", minPoints = 48700, scale = 1.529, speed = 21.2, foodUnit = 435 },
	{ id = "para", minPoints = 75000, scale = 1.595, speed = 21.1, foodUnit = 662 },
	{ id = "proto", minPoints = 115000, scale = 1.664, speed = 21, foodUnit = 1043 },
	{ id = "ankylo", minPoints = 178000, scale = 1.736, speed = 20.9, foodUnit = 1589 },
	{ id = "stego", minPoints = 274000, scale = 1.811, speed = 20.9, foodUnit = 2450 },
	{ id = "allo", minPoints = 422000, scale = 1.89, speed = 20.8, foodUnit = 3758 },
	{ id = "cerato", minPoints = 649000, scale = 1.972, speed = 20.7, foodUnit = 5811 },
	{ id = "carno", minPoints = 1000000, scale = 2.057, speed = 20.6, foodUnit = 8940 },
	{ id = "trike", minPoints = 1540000, scale = 2.147, speed = 20.5, foodUnit = 13742 },
	{ id = "edmonto", minPoints = 2370000, scale = 2.24, speed = 20.4, foodUnit = 21192 },
	{ id = "theri", minPoints = 3650000, scale = 2.337, speed = 20.4, foodUnit = 32616 },
	{ id = "baryonyx", minPoints = 5620000, scale = 2.438, speed = 20.3, foodUnit = 50331 },
	{ id = "utah", minPoints = 8660000, scale = 2.544, speed = 20.2, foodUnit = 76821 },
	{ id = "alberto", minPoints = 13300000, scale = 2.654, speed = 20.1, foodUnit = 119205 },
	{ id = "styraco", minPoints = 20500000, scale = 2.769, speed = 20, foodUnit = 183775 },
	{ id = "kentro", minPoints = 31600000, scale = 2.889, speed = 20, foodUnit = 283113 },
	{ id = "euoplo", minPoints = 48700000, scale = 3.014, speed = 19.9, foodUnit = 435430 },
	{ id = "maia", minPoints = 75000000, scale = 3.145, speed = 19.8, foodUnit = 662252 },
	{ id = "lambeo", minPoints = 115000000, scale = 3.281, speed = 19.7, foodUnit = 1043046 },
	{ id = "diplo", minPoints = 178000000, scale = 3.424, speed = 19.6, foodUnit = 1589404 },
	{ id = "camara", minPoints = 274000000, scale = 3.572, speed = 19.6, foodUnit = 2450331 },
	{ id = "apato", minPoints = 422000000, scale = 3.727, speed = 19.5, foodUnit = 3758278 },
	{ id = "brachio", minPoints = 649000000, scale = 3.888, speed = 19.4, foodUnit = 5811258 },
	{ id = "mamenchi", minPoints = 1000000000, scale = 4.057, speed = 19.3, foodUnit = 8940397 },
	{ id = "trex", minPoints = 1540000000, scale = 4.233, speed = 19.2, foodUnit = 13741722 },
	{ id = "spino", minPoints = 2370000000, scale = 4.416, speed = 19.1, foodUnit = 21192053 },
	{ id = "giganoto", minPoints = 3650000000, scale = 4.608, speed = 19.1, foodUnit = 32615894 },
	{ id = "carcharo", minPoints = 5620000000, scale = 4.808, speed = 19, foodUnit = 50331126 },
	{ id = "mapu", minPoints = 8660000000, scale = 5.016, speed = 18.9, foodUnit = 76821192 },
	{ id = "acro", minPoints = 13300000000, scale = 5.233, speed = 18.8, foodUnit = 119205298 },
	{ id = "toro", minPoints = 20500000000, scale = 5.46, speed = 18.7, foodUnit = 183774834 },
	{ id = "sauropelta", minPoints = 31600000000, scale = 5.697, speed = 18.7, foodUnit = 283112583 },
	{ id = "shantungo", minPoints = 48700000000, scale = 5.944, speed = 18.6, foodUnit = 435430464 },
	{ id = "super", minPoints = 75000000000, scale = 6.202, speed = 18.5, foodUnit = 662251656 },
	{ id = "sauropo", minPoints = 115000000000, scale = 6.471, speed = 18.4, foodUnit = 1043046358 },
	{ id = "dreadnought", minPoints = 178000000000, scale = 6.751, speed = 18.3, foodUnit = 1589403974 },
	{ id = "argentino", minPoints = 274000000000, scale = 7.044, speed = 18.2, foodUnit = 2450331126 },
	{ id = "patagotitan", minPoints = 422000000000, scale = 7.349, speed = 18.2, foodUnit = 3758278146 },
	{ id = "puerta", minPoints = 649000000000, scale = 7.668, speed = 18.1, foodUnit = 5811258278 },
	{ id = "titanosaur", minPoints = 1000000000000, scale = 8, speed = 18, foodUnit = 8948910772 },
}

return stages
