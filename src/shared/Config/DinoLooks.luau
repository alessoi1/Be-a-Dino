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
}

export type Look = { parts: { PartSpec } }

local function block(name: string, size: { number }, offset: { number }, color: { number }): PartSpec
	return {
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
			block("LegLeft", { 0.5, 1, 0.5 }, { -0.6, -2.5, 0.2 }, compyColor),
			block("LegRight", { 0.5, 1, 0.5 }, { 0.6, -2.5, 0.2 }, compyColor),
		},
	},
	raptor = {
		parts = {
			block("Body", { 1.6, 1.5, 3.4 }, { 0, -1.2, 0 }, raptorColor),
			block("Head", { 1.2, 1.1, 2 }, { 0, -0.2, -2.2 }, raptorColor),
			block("Tail", { 0.6, 0.6, 3.4 }, { 0, -1.2, 3.4 }, raptorColor),
			block("LegLeft", { 0.5, 1.4, 0.7 }, { -0.6, -2.3, 0.3 }, raptorColor),
			block("LegRight", { 0.5, 1.4, 0.7 }, { 0.6, -2.3, 0.3 }, raptorColor),
			block("ClawLeft", { 0.3, 0.3, 0.6 }, { -0.6, -2.85, -0.5 }, { 245, 235, 215 }),
			block("ClawRight", { 0.3, 0.3, 0.6 }, { 0.6, -2.85, -0.5 }, { 245, 235, 215 }),
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
			block("Plate1", { 0.3, 1.4, 1 }, { 0, 1, -1.5 }, stegoPlate),
			block("Plate2", { 0.3, 1.4, 1 }, { 0, 1, -0.5 }, stegoPlate),
			block("Plate3", { 0.3, 1.4, 1 }, { 0, 1, 0.5 }, stegoPlate),
			block("Plate4", { 0.3, 1.4, 1 }, { 0, 1, 1.5 }, stegoPlate),
		},
	},
	trex = {
		parts = {
			block("Body", { 2.2, 2.6, 3.6 }, { 0, -0.9, 0.2 }, trexColor),
			block("Head", { 1.8, 1.6, 2.4 }, { 0, 0.3, -2.6 }, trexColor),
			block("Jaw", { 1.5, 0.5, 2 }, { 0, -0.7, -2.4 }, trexColor),
			block("Tail", { 1, 1, 3.6 }, { 0, -0.6, 3.4 }, trexColor),
			block("LegLeft", { 0.9, 1.8, 1.2 }, { -0.8, -2.1, 0.4 }, trexColor),
			block("LegRight", { 0.9, 1.8, 1.2 }, { 0.8, -2.1, 0.4 }, trexColor),
			block("ArmLeft", { 0.3, 0.3, 0.8 }, { -0.8, -0.6, -1.7 }, trexColor),
			block("ArmRight", { 0.3, 0.3, 0.8 }, { 0.8, -0.6, -1.7 }, trexColor),
		},
	},
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
}
