--!strict
-- Prints the rows of src/shared/Config/Dinos.luau (thresholds, sizes, speeds, food units) from a
-- few parameters, so the balance can be redone without calculating the rows by hand.
-- Run: lune run tools/GenerateStages
-- Then paste the rows into the `stages` list of Config/Dinos.luau. The test suite checks the
-- result (tests/specs/Dinos.spec.luau, Progression.spec.luau).

-- The dino ids from small to big. Changing the order or the ids also needs Strings.dinos and
-- the looks (Config/DinoLooks).
local IDS = {
	"compy",
	"dromaeo",
	"raptor",
	"troodon",
	"oviraptor",
	"coelo",
	"deino",
	"gallimimus",
	"pachy",
	"dilopho",
	"iguano",
	"para",
	"proto",
	"ankylo",
	"stego",
	"allo",
	"cerato",
	"carno",
	"trike",
	"edmonto",
	"theri",
	"baryonyx",
	"utah",
	"alberto",
	"styraco",
	"kentro",
	"euoplo",
	"maia",
	"lambeo",
	"diplo",
	"camara",
	"apato",
	"brachio",
	"mamenchi",
	"trex",
}

-- Parameters.
local SECOND_THRESHOLD = 1000 -- the second dino starts here (the first one starts at 0)
local LAST_THRESHOLD = 1e12 -- the last dino starts here
local PIECES_PER_STAGE = 180 -- food pieces a stage takes outside the oasis
local AVERAGE_FOOD_VALUE = 1.51 -- average value of a piece outside the oasis (Config/Food)
local SCALE_FIRST = 1
local SCALE_LAST = 8
local SPEED_FIRST = 22
local SPEED_LAST = 18

local count = #IDS

-- Keeps three significant digits so the thresholds are easy to read.
local function roundThree(value: number): number
	if value < 1000 then
		return math.floor(value + 0.5)
	end
	local magnitude = 10 ^ (math.floor(math.log10(value)) - 2)
	return math.floor(value / magnitude + 0.5) * magnitude
end

local function round(value: number, decimals: number): number
	local factor = 10 ^ decimals
	return math.floor(value * factor + 0.5) / factor
end

-- Thresholds grow by the same factor from the second to the last dino.
local factor = (LAST_THRESHOLD / SECOND_THRESHOLD) ^ (1 / (count - 2))
local thresholds: { number } = { 0 }
for index = 2, count do
	table.insert(thresholds, roundThree(SECOND_THRESHOLD * factor ^ (index - 2)))
end

local lines: { string } = {}
local previousUnit = 0
for index = 1, count do
	local scale = round(SCALE_FIRST * (SCALE_LAST / SCALE_FIRST) ^ ((index - 1) / (count - 1)), 3)
	local speed = round(SPEED_FIRST + (SPEED_LAST - SPEED_FIRST) * (index - 1) / (count - 1), 1)
	local unit: number
	if index < count then
		local span = thresholds[index + 1] - thresholds[index]
		unit = math.floor(span / (PIECES_PER_STAGE * AVERAGE_FOOD_VALUE) + 0.5)
	else
		-- The last dino has no next one; its unit continues the growth of the stage before.
		unit = math.floor(previousUnit * factor + 0.5)
	end
	previousUnit = unit
	table.insert(
		lines,
		string.format(
			'\t{ id = "%s", minPoints = %d, scale = %s, speed = %s, foodUnit = %d },',
			IDS[index],
			thresholds[index],
			tostring(scale),
			tostring(speed),
			unit
		)
	)
end

print(table.concat(lines, "\n"))
