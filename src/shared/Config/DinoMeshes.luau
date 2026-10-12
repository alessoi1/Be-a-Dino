--!strict
-- The real dino shapes (meshes made in Blender, see docs/MODELLE.md). A template is one shape;
-- every dino that uses it gets its own colors, so one shape serves many dinos. Dinos whose shape
-- has no template yet keep their placeholder look from Config/DinoLooks.
--
-- A template has a few mesh parts. Their sizes and offsets are those of the imported model at
-- scale 1: the offset is the center of the part relative to the figure center, the front is -Z and
-- the feet stand 3 studs below the center. The skin pattern (stripes, lighter belly) is inside the
-- mesh as vertex colors; the color of the part tints it.

export type Color = { r: number, g: number, b: number }

-- "body" and "accent" take the colors of the dino (and the variants); "eyes" and "dark" always
-- have the fixed colors below.
export type Role = "body" | "accent" | "eyes" | "dark"

export type MeshSpec = {
	name: string,
	-- The asset id of the uploaded mesh.
	meshId: number,
	role: Role,
	size: { x: number, y: number, z: number },
	offset: { x: number, y: number, z: number },
}

export type Template = { parts: { MeshSpec } }

-- A dino with a hand-written look that uses a template: its own colors.
export type Entry = { template: string, body: Color, accent: Color }

local templates: { [string]: Template } = {
	runner = {
		parts = {
			{
				name = "Body",
				meshId = 129551064444340,
				role = "body",
				size = { x = 2.42, y = 3.5879, z = 9.4654 },
				offset = { x = 0, y = -1.1975, z = 0.769 },
			},
			{
				name = "Accent",
				meshId = 78367756158135,
				role = "accent",
				size = { x = 1.9046, y = 2.9005, z = 2.8437 },
				offset = { x = 0, y = -1.6253, z = -2.2181 },
			},
			{
				name = "Eyes",
				meshId = 115515115980455,
				role = "eyes",
				size = { x = 1.0522, y = 0.34, z = 0.3315 },
				offset = { x = 0, y = 0.3, z = -2.55 },
			},
			{
				name = "Dark",
				meshId = 84654792256588,
				role = "dark",
				size = { x = 1.0461, y = 0.646, z = 1.425 },
				offset = { x = 0, y = 0.113, z = -3.1575 },
			},
		},
	},
}

-- Dinos with a hand-written look in Config/DinoLooks that already have a real shape. The dinos
-- with a plan use the colors of their plan.
local dinos: { [string]: Entry } = {
	compy = {
		template = "runner",
		body = { r = 138, g = 150, b = 84 },
		accent = { r = 232, g = 222, b = 190 },
	},
	raptor = {
		template = "runner",
		body = { r = 178, g = 134, b = 84 },
		accent = { r = 235, g = 225, b = 195 },
	},
}

return {
	templates = templates,
	dinos = dinos,
	-- Colors that never change (also not in a variant).
	fixed = {
		eyes = { r = 242, g = 158, b = 20 },
		dark = { r = 5, g = 5, b = 5 },
	},
	-- Seconds a dino waits for the meshes to load before the placeholder is used.
	loadWaitSeconds = 10,
}
