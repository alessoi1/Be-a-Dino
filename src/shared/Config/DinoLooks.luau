--!strict
-- Placeholder looks for the dinos, built from simple parts until real models
-- (assets/models/<stage id>.rbxm) exist. Real models replace these automatically.
-- Sizes and offsets are in studs for scale 1, relative to the center of the figure
-- (the HumanoidRootPart, about 3 studs above the floor). The front is -Z.
-- The offsets are estimates and are checked by eye in Studio.

export type PartSpec = {
	name: string,
	shape: "Block" | "Ball",
	size: { x: number, y: number, z: number },
	offset: { x: number, y: number, z: number },
	color: { r: number, g: number, b: number },
	-- Which skin color replaces the color of this part: the main color or the second one.
	role: "body" | "accent",
}

export type Look = { parts: { PartSpec } }

export type Color = { r: number, g: number, b: number }

-- A short description of a look that DinoBody turns into parts (see src/shared/DinoBody.luau).
export type Plan = {
	template: string,
	length: number,
	height: number,
	feature: number,
	body: Color,
	accent: Color,
}

local function block(
	name: string,
	size: { number },
	offset: { number },
	color: { number },
	role: ("body" | "accent")?
): PartSpec
	return {
		role = role or "body",
		name = name,
		shape = "Block",
		size = { x = size[1], y = size[2], z = size[3] },
		offset = { x = offset[1], y = offset[2], z = offset[3] },
		color = { r = color[1], g = color[2], b = color[3] },
	}
end

local compyColor = { 110, 200, 90 }
local raptorColor = { 235, 140, 50 }
local stegoColor = { 110, 130, 160 }
local stegoPlate = { 90, 160, 120 }
local trexColor = { 150, 50, 45 }

local looks: { [string]: Look } = {
	compy = {
		parts = {
			block("Body", { 2, 1.6, 3.2 }, { 0, -1.4, 0 }, compyColor),
			block("Head", { 1.4, 1.2, 1.6 }, { 0, -0.5, -2 }, compyColor),
			block("Tail", { 0.8, 0.8, 2.6 }, { 0, -1.4, 2.8 }, compyColor),
			block("LegLeft", { 0.5, 1, 0.5 }, { -0.6, -2.5, 0.2 }, compyColor, "accent"),
			block("LegRight", { 0.5, 1, 0.5 }, { 0.6, -2.5, 0.2 }, compyColor, "accent"),
		},
	},
	raptor = {
		parts = {
			block("Body", { 1.6, 1.5, 3.4 }, { 0, -1.2, 0 }, raptorColor),
			block("Head", { 1.2, 1.1, 2 }, { 0, -0.2, -2.2 }, raptorColor),
			block("Tail", { 0.6, 0.6, 3.4 }, { 0, -1.2, 3.4 }, raptorColor),
			block("LegLeft", { 0.5, 1.4, 0.7 }, { -0.6, -2.3, 0.3 }, raptorColor),
			block("LegRight", { 0.5, 1.4, 0.7 }, { 0.6, -2.3, 0.3 }, raptorColor),
			block("ClawLeft", { 0.3, 0.3, 0.6 }, { -0.6, -2.85, -0.5 }, { 245, 235, 215 }, "accent"),
			block("ClawRight", { 0.3, 0.3, 0.6 }, { 0.6, -2.85, -0.5 }, { 245, 235, 215 }, "accent"),
		},
	},
	stego = {
		parts = {
			block("Body", { 3.4, 2.4, 4.4 }, { 0, -0.9, 0 }, stegoColor),
			block("Head", { 1.1, 1, 1.4 }, { 0, -1.6, -3 }, stegoColor),
			block("Tail", { 1.2, 1.2, 2.6 }, { 0, -1, 3.4 }, stegoColor),
			block("LegFrontLeft", { 0.9, 1.2, 0.9 }, { -1.1, -2.4, -1.4 }, stegoColor),
			block("LegFrontRight", { 0.9, 1.2, 0.9 }, { 1.1, -2.4, -1.4 }, stegoColor),
			block("LegBackLeft", { 0.9, 1.2, 0.9 }, { -1.1, -2.4, 1.4 }, stegoColor),
			block("LegBackRight", { 0.9, 1.2, 0.9 }, { 1.1, -2.4, 1.4 }, stegoColor),
			block("Plate1", { 0.3, 1.4, 1 }, { 0, 1, -1.5 }, stegoPlate, "accent"),
			block("Plate2", { 0.3, 1.4, 1 }, { 0, 1, -0.5 }, stegoPlate, "accent"),
			block("Plate3", { 0.3, 1.4, 1 }, { 0, 1, 0.5 }, stegoPlate, "accent"),
			block("Plate4", { 0.3, 1.4, 1 }, { 0, 1, 1.5 }, stegoPlate, "accent"),
		},
	},
	trex = {
		parts = {
			block("Body", { 2.2, 2.6, 3.6 }, { 0, -0.9, 0.2 }, trexColor),
			block("Head", { 1.8, 1.6, 2.4 }, { 0, 0.3, -2.6 }, trexColor),
			block("Jaw", { 1.5, 0.5, 2 }, { 0, -0.7, -2.4 }, trexColor, "accent"),
			block("Tail", { 1, 1, 3.6 }, { 0, -0.6, 3.4 }, trexColor),
			block("LegLeft", { 0.9, 1.8, 1.2 }, { -0.8, -2.1, 0.4 }, trexColor),
			block("LegRight", { 0.9, 1.8, 1.2 }, { 0.8, -2.1, 0.4 }, trexColor),
			block("ArmLeft", { 0.3, 0.3, 0.8 }, { -0.8, -0.6, -1.7 }, trexColor, "accent"),
			block("ArmRight", { 0.3, 0.3, 0.8 }, { 0.8, -0.6, -1.7 }, trexColor, "accent"),
		},
	},
}

-- Colors for the planned dinos: the main color and the second color (claws, crests, plates ...).
local palette: { { body: Color, accent: Color } } = {
	{ body = { r = 100, g = 170, b = 90 }, accent = { r = 235, g = 215, b = 100 } },
	{ body = { r = 225, g = 140, b = 60 }, accent = { r = 250, g = 230, b = 190 } },
	{ body = { r = 110, g = 125, b = 150 }, accent = { r = 80, g = 190, b = 170 } },
	{ body = { r = 140, g = 100, b = 70 }, accent = { r = 220, g = 190, b = 140 } },
	{ body = { r = 190, g = 70, b = 60 }, accent = { r = 60, g = 50, b = 50 } },
	{ body = { r = 120, g = 140, b = 70 }, accent = { r = 240, g = 160, b = 60 } },
	{ body = { r = 130, g = 90, b = 170 }, accent = { r = 240, g = 160, b = 210 } },
	{ body = { r = 80, g = 130, b = 200 }, accent = { r = 235, g = 240, b = 250 } },
	{ body = { r = 210, g = 180, b = 120 }, accent = { r = 130, g = 90, b = 60 } },
	{ body = { r = 60, g = 150, b = 150 }, accent = { r = 190, g = 230, b = 90 } },
	{ body = { r = 150, g = 150, b = 155 }, accent = { r = 200, g = 70, b = 70 } },
	{ body = { r = 60, g = 110, b = 80 }, accent = { r = 170, g = 230, b = 190 } },
}

local function plan(template: string, paletteIndex: number, length: number, height: number, feature: number): Plan
	local colors = palette[paletteIndex]
	return {
		template = template,
		length = length,
		height = height,
		feature = feature,
		body = colors.body,
		accent = colors.accent,
	}
end

-- Dinos without a hand-written look above get one from their plan. The ids are the stages of
-- Config/Dinos; each dino has exactly one of the two (a test checks it).
local plans: { [string]: Plan } = {
	dromaeo = plan("runner", 1, 0.9, 1.0, 0.3),
	troodon = plan("runner", 4, 1.0, 1.2, 0.6),
	oviraptor = plan("biped", 2, 0.8, 0.9, 0.8),
	coelo = plan("runner", 3, 1.2, 1.0, 0.1),
	deino = plan("biped", 5, 0.8, 1.0, 0.4),
	gallimimus = plan("runner", 9, 1.5, 1.5, 0.2),
	pachy = plan("biped", 6, 0.8, 0.9, 0.9),
	dilopho = plan("biped", 8, 1.0, 1.0, 0.9),
	iguano = plan("duckbill", 12, 1.0, 1.0, 0.2),
	para = plan("duckbill", 10, 1.2, 1.1, 1.0),
	proto = plan("horned", 9, 0.8, 0.8, 0.2),
	ankylo = plan("armored", 4, 1.0, 0.9, 0.8),
	allo = plan("biped", 11, 1.1, 1.1, 0.3),
	cerato = plan("biped", 7, 1.0, 1.0, 0.7),
	carno = plan("biped", 5, 1.0, 1.1, 0.8),
	trike = plan("horned", 6, 1.2, 1.2, 0.9),
	edmonto = plan("duckbill", 1, 1.4, 1.3, 0.4),
	theri = plan("biped", 12, 0.9, 1.4, 0.5),
	baryonyx = plan("biped", 3, 1.2, 1.0, 0.4),
	utah = plan("biped", 2, 1.0, 1.0, 0.6),
	alberto = plan("biped", 4, 1.2, 1.2, 0.1),
	styraco = plan("horned", 2, 1.0, 1.0, 1.0),
	kentro = plan("armored", 8, 1.1, 1.0, 1.0),
	euoplo = plan("armored", 11, 1.2, 1.0, 0.5),
	maia = plan("duckbill", 6, 1.0, 1.0, 0.5),
	lambeo = plan("duckbill", 7, 1.2, 1.1, 0.9),
	diplo = plan("longneck", 1, 1.2, 1.0, 0.6),
	camara = plan("longneck", 10, 1.0, 1.0, 0.4),
	apato = plan("longneck", 4, 1.3, 1.1, 0.5),
	brachio = plan("longneck", 8, 1.0, 1.3, 1.0),
	mamenchi = plan("longneck", 3, 1.0, 1.0, 1.0),
	spino = plan("biped", 10, 1.3, 1.1, 1.0),
	giganoto = plan("biped", 11, 1.2, 1.2, 0.4),
	carcharo = plan("biped", 5, 1.2, 1.3, 0.6),
	mapu = plan("biped", 9, 1.2, 1.2, 0.2),
	acro = plan("biped", 6, 1.1, 1.1, 0.8),
	toro = plan("horned", 4, 1.3, 1.3, 0.8),
	sauropelta = plan("armored", 12, 1.2, 1.0, 0.9),
	shantungo = plan("duckbill", 3, 1.5, 1.4, 0.6),
	super = plan("longneck", 9, 1.4, 1.2, 0.6),
	sauropo = plan("longneck", 7, 1.2, 1.2, 1.0),
	dreadnought = plan("longneck", 11, 1.4, 1.3, 0.5),
	argentino = plan("longneck", 1, 1.5, 1.4, 0.7),
	patagotitan = plan("longneck", 2, 1.5, 1.5, 0.8),
	puerta = plan("longneck", 12, 1.6, 1.4, 0.4),
	titanosaur = plan("longneck", 5, 1.6, 1.6, 1.0),
}

return {
	-- Most parts a dino look (placeholder or real model) may have.
	maxParts = 12,
	-- Cloud effect when a player turns into the next dino.
	effect = {
		particleCount = 30,
		seconds = 1.5,
	},
	looks = looks,
	plans = plans,
}
