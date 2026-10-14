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

-- Colorful emoji: they keep their own colors (the tint does not change them), so kids can read
-- the interface by looking. Real images replace them one by one through `assetId`.
return {
	-- The size (points) of a dino.
	size = icon("\u{1F4AA}", 255, 255, 255),
	-- Coins.
	coin = icon("\u{1F4B0}", 255, 255, 255),
	-- The sprint button and the stamina bar.
	sprint = icon("\u{1F4A8}", 255, 255, 255),
	stamina = icon("\u{26A1}", 255, 255, 255),
	-- The autofarm button.
	autofarm = icon("\u{1F916}", 255, 255, 255),
	-- The leaderboard title.
	leaderboard = icon("\u{1F3C6}", 255, 255, 255),
	-- The death window: revive, bounty, and the face of the headline.
	revive = icon("\u{2764}\u{FE0F}", 255, 255, 255),
	bounty = icon("\u{1F3AF}", 255, 255, 255),
	eaten = icon("\u{1F635}", 255, 255, 255),
	-- The button back to the lobby.
	lobby = icon("\u{1F3E0}", 255, 255, 255),
	-- The menu bar in the lobby: shop, dinodex and boosters.
	shop = icon("\u{1F95A}", 255, 255, 255),
	dex = icon("\u{1F4D6}", 255, 255, 255),
	boost = icon("\u{1F9EA}", 255, 255, 255),
	-- Food: the points still missing to the next dino.
	food = icon("\u{1F356}", 255, 255, 255),
	-- Next dino, and "a saved one is used".
	next = icon("\u{27A1}\u{FE0F}", 255, 255, 255),
	offer = icon("\u{1F6D2}", 255, 255, 255),
	locked = icon("\u{1F512}", 255, 255, 255),
	-- Messages.
	ate = icon("\u{1F60B}", 255, 255, 255),
	party = icon("\u{1F389}", 255, 255, 255),
	timer = icon("\u{23F3}", 255, 255, 255),
	on = icon("\u{2705}", 255, 255, 255),
	step = icon("\u{1F463}", 255, 255, 255),
	-- Potions (by potion id, see Config/Offers).
	gift = icon("\u{1F381}", 255, 255, 255),
	potion_growth = icon("\u{1F331}", 255, 255, 255),
	potion_coin = icon("\u{1F4B0}", 255, 255, 255),
	potion_speed = icon("\u{1F4A8}", 255, 255, 255),
	potion_shield = icon("\u{1F6E1}\u{FE0F}", 255, 255, 255),
}
