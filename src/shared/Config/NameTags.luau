--!strict
-- The name tags above the dinos (name and size), to be tuned by eye in Studio. Sizes are in studs
-- at dino scale 1 (the tag is a billboard with a size in studs, so it also shrinks with distance
-- like everything else in the world).

export type RGB = { r: number, g: number, b: number }

local function rgb(r: number, g: number, b: number): RGB
	return { r = r, g = g, b = b }
end

return {
	-- Seconds between two refreshes of the tags on the client.
	updateInterval = 0.2,
	-- Width and height of the tag at scale 1. A bigger dino gets a bigger tag, but not as much
	-- bigger as its body (width * scale ^ sizeExponent).
	baseWidth = 10,
	baseHeight = 3,
	sizeExponent = 0.7,
	-- Height of the middle of the tag above the middle of the dino (root part) while its real height is
	-- not known: base + perScale * scale.
	baseOffset = 2,
	offsetPerScale = 1.6,
	-- With a known dino height the tag floats right above the head: this gap per unit of scale (studs).
	tagGap = 0.15,
	-- A tag is seen up to this far: base + perScale * scale (studs), so a giant is readable from afar.
	maxDistanceBase = 120,
	maxDistancePerScale = 40,
	-- Share of the range after which the tag fades out (0.7 = the last 30 % fade).
	fadeStart = 0.7,
	-- Share of the tag height for the name; the rest is the size.
	nameShare = 0.58,
	-- Colors: the own tag, the tags of the others and the stroke around the letters.
	selfColor = rgb(255, 226, 120),
	otherColor = rgb(255, 255, 255),
	sizeColor = rgb(190, 235, 255),
	strokeTransparency = 0.35,
	-- Tags of players who are in the lobby are not shown (only in the arena).
	hideInLobby = true,
}
