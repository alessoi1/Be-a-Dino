--!strict
-- Colors, font and base sizes of the interface. All interface parts use these, so the
-- look stays the same. Text sizes are base sizes at layout scale 1; the layout scale
-- (see UiLayout) never goes below the limit that keeps them readable.

return {
	font = Font.fromEnum(Enum.Font.FredokaOne),
	text = Color3.fromRGB(255, 255, 255),
	-- Panels: deep blue and see-through, with a light edge.
	panel = Color3.fromRGB(18, 38, 74),
	panelTransparency = 0.25,
	panelEdge = Color3.fromRGB(150, 190, 255),
	panelEdgeTransparency = 0.55,
	-- The dark outline of the bright buttons and of the text on them.
	outline = Color3.fromRGB(12, 18, 36),
	accent = Color3.fromRGB(255, 170, 40),
	good = Color3.fromRGB(110, 200, 90),
	own = Color3.fromRGB(255, 225, 120),
	-- Bright buttons (the fill; the outline is dark).
	sprintButton = Color3.fromRGB(255, 150, 30),
	autoOff = Color3.fromRGB(226, 70, 70),
	autoOn = Color3.fromRGB(70, 190, 90),
	lobbyButton = Color3.fromRGB(64, 140, 235),
	-- Base text sizes in pixels (at least UiLayout.minBaseTextSize).
	titleSize = 20,
	bodySize = 18,
	-- Distance to the screen edge in pixels.
	margin = 8,
	-- Height of the status panel at the top left (base size).
	statusPanelHeight = 76,
	-- Height and width of the "Lobby" button under the status panel (base size).
	lobbyButtonHeight = 36,
	lobbyButtonWidth = 210,
	-- Colors for dinos that are not reached yet.
	lockedCard = Color3.fromRGB(70, 70, 70),
	lockedText = Color3.fromRGB(190, 190, 190),
}
