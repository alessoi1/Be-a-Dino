--!strict
-- Colors, font and base sizes of the interface. All interface parts use these, so the
-- look stays the same. Text sizes are base sizes at layout scale 1; the layout scale
-- (see UiLayout) never goes below the limit that keeps them readable.

return {
	font = Font.fromEnum(Enum.Font.FredokaOne),
	text = Color3.fromRGB(255, 255, 255),
	panel = Color3.fromRGB(30, 30, 30),
	panelTransparency = 0.35,
	accent = Color3.fromRGB(255, 170, 40),
	good = Color3.fromRGB(110, 200, 90),
	own = Color3.fromRGB(255, 225, 120),
	-- Base text sizes in pixels (at least UiLayout.minBaseTextSize).
	titleSize = 20,
	bodySize = 18,
	-- Distance to the screen edge in pixels.
	margin = 8,
}
