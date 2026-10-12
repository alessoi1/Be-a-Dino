--!strict
-- The real dino shapes (meshes made in Blender, see docs/MODELLE.md). A template is one shape;
-- every dino that uses it gets its own colors, so one shape serves many dinos. Dinos whose shape
-- has no template yet keep their placeholder look from Config/DinoLooks.
--
-- A template has a few mesh parts. Their sizes and offsets are those of the imported model at
-- scale 1: the offset is the center of the part relative to the figure center, the front is -Z and
-- the feet stand 3 studs below the center. The skin pattern (stripes, lighter belly) is inside the
-- mesh as vertex colors; the color of the part tints it.
--
-- Moving parts (legs, tail) have a `limb` and a `joint`: the point where the part turns, relative
-- to the figure center. They hang on the `root` part with a Motor6D, and the client turns them
-- while the dino walks (see DinoAnim). All other parts are fixed to the root.

export type Color = { r: number, g: number, b: number }

-- "body" and "accent" take the colors of the dino (and the variants); "eyes" and "dark" always
-- have the fixed colors below.
export type Role = "body" | "accent" | "eyes" | "dark"

export type Limb = "legLeft" | "legRight" | "tail"

export type MeshSpec = {
	name: string,
	-- The asset id of the uploaded mesh.
	meshId: number,
	role: Role,
	size: { x: number, y: number, z: number },
	offset: { x: number, y: number, z: number },
	-- Set for a moving part: which limb it is and where it turns.
	limb: Limb?,
	joint: { x: number, y: number, z: number }?,
}

export type Template = {
	-- The name of the part the moving parts hang on (the fixed body).
	root: string,
	parts: { MeshSpec },
}

-- A dino with a hand-written look that uses a template: its own colors.
export type Entry = { template: string, body: Color, accent: Color }

local templates: { [string]: Template } = {
	runner = {
		root = "Body",
		parts = {
			{
				name = "Body",
				meshId = 123925490386633,
				role = "body",
				size = { x = 1.9524, y = 2.3249, z = 5.7855 },
				offset = { x = 0.0133, y = -0.6139, z = -1.0649 },
			},
			{
				name = "Tail",
				meshId = 84757090943199,
				role = "body",
				size = { x = 1.1, y = 1.002, z = 3.9372 },
				offset = { x = 0, y = -1.1, z = 3.5328 },
				limb = "tail",
				joint = { x = 0, y = -1.1, z = 1.6 },
			},
			{
				name = "LegLeft",
				meshId = 86995604553438,
				role = "body",
				size = { x = 1.1, y = 2.2326, z = 2.5563 },
				offset = { x = -0.66, y = -1.9592, z = -0.0068 },
				limb = "legLeft",
				joint = { x = -0.66, y = -1.1, z = 0.8 },
			},
			{
				name = "LegRight",
				meshId = 89153016392730,
				role = "body",
				size = { x = 1.1, y = 2.2326, z = 2.5563 },
				offset = { x = 0.66, y = -1.9592, z = -0.0068 },
				limb = "legRight",
				joint = { x = 0.66, y = -1.1, z = 0.8 },
			},
			{
				name = "Accent",
				meshId = 95715589319009,
				role = "accent",
				size = { x = 1.7779, y = 1.9219, z = 5.505 },
				offset = { x = 0, y = -0.604, z = -0.8225 },
			},
			{
				name = "Eyes",
				meshId = 113978924112501,
				role = "eyes",
				size = { x = 1.0633, y = 0.38, z = 0.38 },
				offset = { x = 0, y = 0.3, z = -2.55 },
			},
			{
				name = "Dark",
				meshId = 129209504376245,
				role = "dark",
				size = { x = 1.0751, y = 0.6594, z = 1.4155 },
				offset = { x = 0, y = 0.1223, z = -3.1529 },
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
