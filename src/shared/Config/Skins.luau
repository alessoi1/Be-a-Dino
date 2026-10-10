--!strict
-- Skins: other colors for a dino. They never change values (size, speed, eating).
-- Every dino has exactly one default skin (`free`). The names are in Strings.skins by id.
-- Unlock kinds:
--   free     always available
--   reach    available once the dino `stageId` was reached
--   best     available once the best round has `points`
--   product  bought (Developer Product); productId 0 means "not for sale yet" and hides the skin
-- `colors` replaces the colors of the placeholder parts by role (body, accent); a skin without
-- colors keeps the original ones. Placeholder values, to be changed.

export type Color = { r: number, g: number, b: number }

export type Skin = {
	id: string,
	dinoId: string,
	unlock: { kind: string, stageId: string?, points: number?, productId: number? },
	colors: { body: Color, accent: Color }?,
}

local function color(r: number, g: number, b: number): Color
	return { r = r, g = g, b = b }
end

local skins: { Skin } = {
	{ id = "compy_default", dinoId = "compy", unlock = { kind = "free" } },
	{
		id = "compy_mint",
		dinoId = "compy",
		unlock = { kind = "reach", stageId = "raptor" },
		colors = { body = color(150, 230, 200), accent = color(70, 170, 140) },
	},
	{
		id = "compy_berry",
		dinoId = "compy",
		unlock = { kind = "product", productId = 0 },
		colors = { body = color(200, 60, 90), accent = color(255, 160, 190) },
	},

	{ id = "raptor_default", dinoId = "raptor", unlock = { kind = "free" } },
	{
		id = "raptor_sunset",
		dinoId = "raptor",
		unlock = { kind = "reach", stageId = "stego" },
		colors = { body = color(240, 110, 70), accent = color(255, 210, 90) },
	},
	{
		id = "raptor_midnight",
		dinoId = "raptor",
		unlock = { kind = "product", productId = 0 },
		colors = { body = color(60, 70, 140), accent = color(170, 180, 255) },
	},

	{ id = "stego_default", dinoId = "stego", unlock = { kind = "free" } },
	{
		id = "stego_moss",
		dinoId = "stego",
		unlock = { kind = "reach", stageId = "trex" },
		colors = { body = color(90, 140, 80), accent = color(200, 220, 120) },
	},
	{
		id = "stego_volcano",
		dinoId = "stego",
		unlock = { kind = "product", productId = 0 },
		colors = { body = color(110, 60, 50), accent = color(255, 120, 40) },
	},

	{ id = "trex_default", dinoId = "trex", unlock = { kind = "free" } },
	{
		id = "trex_gold",
		dinoId = "trex",
		unlock = { kind = "best", points = 5000000000 },
		colors = { body = color(220, 180, 50), accent = color(255, 240, 150) },
	},
	{
		id = "trex_frost",
		dinoId = "trex",
		unlock = { kind = "product", productId = 0 },
		colors = { body = color(150, 200, 230), accent = color(240, 250, 255) },
	},
}

return {
	-- Longest skin id the server accepts from a client.
	maxIdLength = 32,
	-- Minimum seconds between two accepted equip requests per player.
	equipMinInterval = 0.3,
	skins = skins,
}
