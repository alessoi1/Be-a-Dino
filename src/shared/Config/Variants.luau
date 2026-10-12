--!strict
-- The variants of a dino: the same dino in glowing, gold, shadow or rainbow looks. They only
-- change how a dino looks, never its size, speed or eating. Every dino has all of them, plus its
-- normal look (the one it always has). They are found in eggs (see Config/Eggs). The names are in
-- Strings.variants by id. Placeholder values, to be changed.
--
-- How a variant changes the parts of a look (roles come from Config/DinoLooks):
--   material   the Roblox material of every part
--   lighten    0 to 1: the color moves this far toward white
--   darken     0 to 1: the color moves this far toward black
--   body       replaces the color of the parts with the role "body"
--   accent     replaces the color of the parts with the role "accent"
--   animated   the colors change all the time (rainbow); the client does that near the camera

export type Color = { r: number, g: number, b: number }

export type Variant = {
	id: string,
	material: string,
	lighten: number?,
	darken: number?,
	body: Color?,
	accent: Color?,
	animated: boolean?,
}

local variants: { Variant } = {
	{ id = "glowing", material = "Neon", lighten = 0.35 },
	{ id = "gold", material = "Metal", body = { r = 255, g = 200, b = 60 }, accent = { r = 255, g = 235, b = 150 } },
	{ id = "shadow", material = "SmoothPlastic", darken = 0.8, accent = { r = 150, g = 70, b = 230 } },
	{ id = "rainbow", material = "Neon", animated = true },
}

return {
	variants = variants,
	-- The id of the normal look (no variant).
	normalId = "normal",
	-- Rainbow: color saturation and brightness (0 to 1), and how many full color cycles per second.
	rainbowSaturation = 0.75,
	rainbowValue = 1,
	rainbowCyclesPerSecond = 0.25,
	-- Rainbow is animated only for this many dinos nearest to the camera, and only within this
	-- distance (studs), so many rainbow dinos do not slow down a phone.
	rainbowMaxModels = 8,
	rainbowMaxDistance = 150,
}
