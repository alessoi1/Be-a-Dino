--!strict
-- The icons of the interface. `assetId` is the Roblox image (0 = not uploaded yet): until then a
-- symbol character (`glyph`) is shown instead, so the interface works without any image. The
-- images are white shapes on a transparent ground; `color` tints them (and the glyph). See
-- docs/ICONS.md for the list and the way to add them.

export type Icon = {
	-- Roblox image asset id, 0 = not there yet.
	assetId: number,
	-- Shown in place of the image.
	glyph: string,
	color: { r: number, g: number, b: number },
}

local function icon(glyph: string, r: number, g: number, b: number): Icon
	return { assetId = 0, glyph = glyph, color = { r = r, g = g, b = b } }
end

return {
	-- The size (points) of a dino.
	size = icon("\u{2B06}", 190, 235, 255),
	-- Coins.
	coin = icon("\u{25CF}", 255, 214, 80),
	-- The sprint button.
	sprint = icon("\u{26A1}", 255, 255, 255),
	-- The stamina bar.
	stamina = icon("\u{26A1}", 255, 190, 60),
	-- The autofarm button.
	autofarm = icon("\u{21BB}", 255, 255, 255),
	-- The leaderboard title.
	leaderboard = icon("\u{2605}", 255, 214, 80),
	-- The button back to the lobby.
	lobby = icon("\u{2302}", 255, 255, 255),
	-- The menu bar in the lobby: shop, dinodex and boosters.
	shop = icon("\u{1F6D2}", 255, 214, 80),
	dex = icon("\u{1F4D6}", 130, 190, 255),
	boost = icon("\u{2697}", 214, 150, 255),
}
