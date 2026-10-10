--!strict
-- Values for the interface, to be balanced on real devices.

return {
	-- Rows in the leaderboard (the own row is added below when it is not among them).
	leaderboardSize = 5,
	-- Seconds between two refreshes of the leaderboard.
	leaderboardRefreshSeconds = 0.5,
	-- Seconds a message stays on the screen.
	noticeSeconds = 3,
	-- Layout scale = shorter screen side / referenceShortSide, kept between scaleMin and scaleMax.
	referenceShortSide = 390,
	scaleMin = 0.8,
	scaleMax = 1.4,
	-- Touch button size = shorter screen side * buttonFraction, kept between buttonMin and buttonMax (pixels).
	buttonFraction = 0.2,
	buttonMin = 72,
	buttonMax = 120,
	-- Small round menu button: shorter screen side * smallButtonFraction, kept between the limits (pixels).
	smallButtonFraction = 0.14,
	smallButtonMin = 52,
	smallButtonMax = 84,
	-- No text may end up smaller than this (pixels, after scaling).
	minTextSize = 14,
}
