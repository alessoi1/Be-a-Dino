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

export type Limb = "legLeft" | "legRight" | "legFrontLeft" | "legFrontRight" | "legBackLeft" | "legBackRight" | "tail"

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
	biped = {
		root = "Body",
		parts = {
			{
				name = "Body",
				meshId = 78375384920139,
				role = "body",
				size = { x = 2.2, y = 2.7117, z = 7.0488 },
				offset = { x = 0, y = -0.3324, z = -1.0877 },
			},
			{
				name = "Tail",
				meshId = 132829402213269,
				role = "body",
				size = { x = 1.6, y = 1.4632, z = 5.2867 },
				offset = { x = 0, y = -0.8, z = 4.762 },
				limb = "tail",
				joint = { x = 0, y = -0.8, z = 2.2 },
			},
			{
				name = "LegLeft",
				meshId = 109240851419506,
				role = "body",
				size = { x = 1.4, y = 2.3637, z = 2.6265 },
				offset = { x = -0.8, y = -1.8381, z = 0.6883 },
				limb = "legLeft",
				joint = { x = -0.8, y = -1, z = 1.4 },
			},
			{
				name = "LegRight",
				meshId = 103585892879310,
				role = "body",
				size = { x = 1.4, y = 2.3637, z = 2.6265 },
				offset = { x = 0.8, y = -1.8381, z = 0.6883 },
				limb = "legRight",
				joint = { x = 0.8, y = -1, z = 1.4 },
			},
			{
				name = "Accent",
				meshId = 73555085424839,
				role = "accent",
				size = { x = 2.0693, y = 2.34, z = 5.57 },
				offset = { x = 0, y = -0.52, z = -1.245 },
			},
			{
				name = "Eyes",
				meshId = 84467537167984,
				role = "eyes",
				size = { x = 1.4371, y = 0.4, z = 0.4 },
				offset = { x = 0, y = 0.62, z = -3 },
			},
			{
				name = "Dark",
				meshId = 86273980139126,
				role = "dark",
				size = { x = 1.4496, y = 1.0817, z = 2.0939 },
				offset = { x = 0, y = 0.2391, z = -3.6423 },
			},
		},
	},
	duckbill = {
		root = "Body",
		parts = {
			{
				name = "Body",
				meshId = 102016296699443,
				role = "body",
				size = { x = 2, y = 2.2601, z = 5.8429 },
				offset = { x = 0, y = -0.4419, z = -1.0872 },
			},
			{
				name = "Tail",
				meshId = 97392567461469,
				role = "body",
				size = { x = 1.8, y = 1.6383, z = 4.6783 },
				offset = { x = 0, y = -0.75, z = 3.8624 },
				limb = "tail",
				joint = { x = 0, y = -0.75, z = 1.6 },
			},
			{
				name = "LegFrontLeft",
				meshId = 94006083412009,
				role = "body",
				size = { x = 1, y = 2.0772, z = 1.4205 },
				offset = { x = -0.8, y = -1.9614, z = -0.8347 },
				limb = "legFrontLeft",
				joint = { x = -0.8, y = -0.95, z = -0.6 },
			},
			{
				name = "LegFrontRight",
				meshId = 71860335330891,
				role = "body",
				size = { x = 1, y = 2.0772, z = 1.4205 },
				offset = { x = 0.8, y = -1.9614, z = -0.8347 },
				limb = "legFrontRight",
				joint = { x = 0.8, y = -0.95, z = -0.6 },
			},
			{
				name = "LegBackLeft",
				meshId = 104067608840970,
				role = "body",
				size = { x = 1, y = 2.0772, z = 1.4205 },
				offset = { x = -0.8, y = -1.9614, z = 0.9653 },
				limb = "legBackLeft",
				joint = { x = -0.8, y = -0.95, z = 1.2 },
			},
			{
				name = "LegBackRight",
				meshId = 81980060161770,
				role = "body",
				size = { x = 1, y = 2.0772, z = 1.4205 },
				offset = { x = 0.8, y = -1.9614, z = 0.9653 },
				limb = "legBackRight",
				joint = { x = 0.8, y = -0.95, z = 1.2 },
			},
			{
				name = "Accent",
				meshId = 136904934465591,
				role = "accent",
				size = { x = 0.2, y = 1.0219, z = 4.032 },
				offset = { x = 0, y = 0.6881, z = -0.916 },
			},
			{
				name = "Eyes",
				meshId = 81758659791640,
				role = "eyes",
				size = { x = 1.0356, y = 0.34, z = 0.34 },
				offset = { x = 0, y = 0.35, z = -2.7 },
			},
			{
				name = "Dark",
				meshId = 110145482059790,
				role = "dark",
				size = { x = 1.0461, y = 0.7077, z = 1.5754 },
				offset = { x = 0, y = 0.1322, z = -3.2816 },
			},
		},
	},
	armored = {
		root = "Body",
		parts = {
			{
				name = "Body",
				meshId = 119264271225351,
				role = "body",
				size = { x = 3.2, y = 1.9943, z = 6.3307 },
				offset = { x = 0, y = -0.8519, z = -0.2497 },
			},
			{
				name = "Tail",
				meshId = 112606187469537,
				role = "body",
				size = { x = 2, y = 1.7345, z = 4.507 },
				offset = { x = 0, y = -1.2327, z = 4.7465 },
				limb = "tail",
				joint = { x = 0, y = -1.05, z = 2.6 },
			},
			{
				name = "LegFrontLeft",
				meshId = 123444164704127,
				role = "body",
				size = { x = 1, y = 1.5396, z = 1.4197 },
				offset = { x = -1.1, y = -2.2302, z = -1.0352 },
				limb = "legFrontLeft",
				joint = { x = -1.1, y = -1.5, z = -0.8 },
			},
			{
				name = "LegFrontRight",
				meshId = 88018386505009,
				role = "body",
				size = { x = 1, y = 1.5396, z = 1.4197 },
				offset = { x = 1.1, y = -2.2302, z = -1.0352 },
				limb = "legFrontRight",
				joint = { x = 1.1, y = -1.5, z = -0.8 },
			},
			{
				name = "LegBackLeft",
				meshId = 140035713524055,
				role = "body",
				size = { x = 1, y = 1.5396, z = 1.4197 },
				offset = { x = -1.1, y = -2.2302, z = 1.5648 },
				limb = "legBackLeft",
				joint = { x = -1.1, y = -1.5, z = 1.8 },
			},
			{
				name = "LegBackRight",
				meshId = 79049270397203,
				role = "body",
				size = { x = 1, y = 1.5396, z = 1.4197 },
				offset = { x = 1.1, y = -2.2302, z = 1.5648 },
				limb = "legBackRight",
				joint = { x = 1.1, y = -1.5, z = 1.8 },
			},
			{
				name = "Accent",
				meshId = 115017868335872,
				role = "accent",
				size = { x = 3.8, y = 1.6519, z = 4.3023 },
				offset = { x = 0, y = -0.274, z = 0.8511 },
			},
			{
				name = "Eyes",
				meshId = 78036039937156,
				role = "eyes",
				size = { x = 1.194, y = 0.28, z = 0.28 },
				offset = { x = 0, y = -1, z = -2.7 },
			},
			{
				name = "Dark",
				meshId = 118435729618288,
				role = "dark",
				size = { x = 1.2027, y = 0.434, z = 1.077 },
				offset = { x = 0, y = -1.105, z = -2.9308 },
			},
		},
	},
	horned = {
		root = "Body",
		parts = {
			{
				name = "Body",
				meshId = 102764561317366,
				role = "body",
				size = { x = 3.0434, y = 3.2362, z = 6.836 },
				offset = { x = 0, y = -0.2681, z = -0.916 },
			},
			{
				name = "Tail",
				meshId = 75755833981469,
				role = "body",
				size = { x = 1.8, y = 1.4413, z = 2.4597 },
				offset = { x = 0, y = -1, z = 3.2797 },
				limb = "tail",
				joint = { x = 0, y = -1, z = 2.2 },
			},
			{
				name = "LegFrontLeft",
				meshId = 113561686436497,
				role = "body",
				size = { x = 1.1, y = 1.737, z = 1.4633 },
				offset = { x = -1, y = -2.1315, z = -0.6133 },
				limb = "legFrontLeft",
				joint = { x = -1, y = -1.3, z = -0.4 },
			},
			{
				name = "LegFrontRight",
				meshId = 89076935074582,
				role = "body",
				size = { x = 1.1, y = 1.737, z = 1.4633 },
				offset = { x = 1, y = -2.1315, z = -0.6133 },
				limb = "legFrontRight",
				joint = { x = 1, y = -1.3, z = -0.4 },
			},
			{
				name = "LegBackLeft",
				meshId = 116670849540919,
				role = "body",
				size = { x = 1.1, y = 1.737, z = 1.4633 },
				offset = { x = -1, y = -2.1315, z = 1.3867 },
				limb = "legBackLeft",
				joint = { x = -1, y = -1.3, z = 1.6 },
			},
			{
				name = "LegBackRight",
				meshId = 134973005737519,
				role = "body",
				size = { x = 1.1, y = 1.737, z = 1.4633 },
				offset = { x = 1, y = -2.1315, z = 1.3867 },
				limb = "legBackRight",
				joint = { x = 1, y = -1.3, z = 1.6 },
			},
			{
				name = "Accent",
				meshId = 83378510883742,
				role = "accent",
				size = { x = 3.2889, y = 2.4306, z = 2.5887 },
				offset = { x = 0, y = 0.2847, z = -3.0544 },
			},
			{
				name = "Eyes",
				meshId = 99375535218379,
				role = "eyes",
				size = { x = 1.294, y = 0.28, z = 0.28 },
				offset = { x = 0, y = 0, z = -3 },
			},
			{
				name = "Dark",
				meshId = 125248455091927,
				role = "dark",
				size = { x = 1.3027, y = 1.1337, z = 1.4759 },
				offset = { x = 0, y = -0.4549, z = -3.6313 },
			},
		},
	},
	longneck = {
		root = "Body",
		parts = {
			{
				name = "Body",
				meshId = 83988789439661,
				role = "body",
				size = { x = 2.5, y = 5.0205, z = 6.8129 },
				offset = { x = 0, y = 0.6746, z = -1.4064 },
			},
			{
				name = "Tail",
				meshId = 128663993614103,
				role = "body",
				size = { x = 2, y = 1.6354, z = 6.294 },
				offset = { x = 0, y = -0.8, z = 4.8561 },
				limb = "tail",
				joint = { x = 0, y = -0.8, z = 1.8 },
			},
			{
				name = "LegFrontLeft",
				meshId = 103721512648428,
				role = "body",
				size = { x = 1.1, y = 1.8346, z = 1.4635 },
				offset = { x = -0.9, y = -2.0827, z = -0.8133 },
				limb = "legFrontLeft",
				joint = { x = -0.9, y = -1.2, z = -0.6 },
			},
			{
				name = "LegFrontRight",
				meshId = 104865326753626,
				role = "body",
				size = { x = 1.1, y = 1.8346, z = 1.4635 },
				offset = { x = 0.9, y = -2.0827, z = -0.8133 },
				limb = "legFrontRight",
				joint = { x = 0.9, y = -1.2, z = -0.6 },
			},
			{
				name = "LegBackLeft",
				meshId = 80240826127623,
				role = "body",
				size = { x = 1.1, y = 1.8346, z = 1.4635 },
				offset = { x = -0.9, y = -2.0827, z = 1.3867 },
				limb = "legBackLeft",
				joint = { x = -0.9, y = -1.2, z = 1.6 },
			},
			{
				name = "LegBackRight",
				meshId = 119297795929258,
				role = "body",
				size = { x = 1.1, y = 1.8346, z = 1.4635 },
				offset = { x = 0.9, y = -2.0827, z = 1.3867 },
				limb = "legBackRight",
				joint = { x = 0.9, y = -1.2, z = 1.6 },
			},
			{
				name = "Accent",
				meshId = 135167918776853,
				role = "accent",
				size = { x = 0.28, y = 2.8333, z = 5.64 },
				offset = { x = 0, y = 1.6733, z = -0.48 },
			},
			{
				name = "Eyes",
				meshId = 125662908175055,
				role = "eyes",
				size = { x = 0.5663, y = 0.24, z = 0.24 },
				offset = { x = 0, y = 3.12, z = -4.15 },
			},
			{
				name = "Dark",
				meshId = 107955564712372,
				role = "dark",
				size = { x = 0.5737, y = 0.3577, z = 1.0944 },
				offset = { x = 0, y = 3.0371, z = -4.3421 },
			},
		},
	},
	-- The Compy shape (from Tripo, reduced to 771 triangles, assets/blender/compy.fbx; the face
	-- is assets/blender/compy_face.fbx). It has no accent part: crest and claws are part of the
	-- body and the legs.
	compy = {
		root = "Body",
		parts = {
			{
				name = "Body",
				meshId = 80325755941431,
				role = "body",
				size = { x = 1.9824, y = 4.2693, z = 5.3166 },
				offset = { x = -0.0004, y = 0.4631, z = -1.2507 },
			},
			{
				name = "Tail",
				meshId = 77760662277846,
				role = "body",
				size = { x = 0.9393, y = 1.0114, z = 4.7669 },
				offset = { x = -0.0008, y = -0.0044, z = 3.1442 },
				limb = "tail",
				joint = { x = 0, y = 0, z = 0.8 },
			},
			{
				name = "LegLeft",
				meshId = 83585372268398,
				role = "body",
				size = { x = 0.8205, y = 2.2191, z = 1.5684 },
				offset = { x = -0.7275, y = -1.8923, z = -0.4992 },
				limb = "legLeft",
				joint = { x = -0.7275, y = -0.9, z = -0.5 },
			},
			{
				name = "LegRight",
				meshId = 85506662811459,
				role = "body",
				size = { x = 0.8231, y = 2.22, z = 1.5681 },
				offset = { x = 0.7294, y = -1.8905, z = -0.4993 },
				limb = "legRight",
				joint = { x = 0.7294, y = -0.9, z = -0.5 },
			},
			{
				name = "Eyes",
				meshId = 105803586345665,
				role = "eyes",
				size = { x = 0.8332, y = 0.34, z = 0.34 },
				offset = { x = 0, y = 2.08, z = -3 },
			},
			{
				name = "Dark",
				meshId = 108033772431949,
				role = "dark",
				size = { x = 0.8979, y = 0.575, z = 1.17 },
				offset = { x = 0, y = 1.8825, z = -3.335 },
			},
		},
	},
}

-- Dinos with a hand-written look in Config/DinoLooks that already have a real shape. The dinos
-- with a plan use the colors of their plan.
local dinos: { [string]: Entry } = {
	compy = {
		template = "compy",
		body = { r = 153, g = 143, b = 87 },
		accent = { r = 232, g = 222, b = 190 },
	},
	trex = {
		template = "biped",
		body = { r = 158, g = 77, b = 61 },
		accent = { r = 232, g = 222, b = 190 },
	},
	stego = {
		template = "armored",
		body = { r = 150, g = 135, b = 115 },
		accent = { r = 232, g = 222, b = 190 },
	},
	raptor = {
		template = "runner",
		body = { r = 178, g = 150, b = 100 },
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
