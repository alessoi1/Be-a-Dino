--!strict
-- The eating combo: pieces of food eaten within `windowSeconds` of each other build a combo that
-- the client shows as a flame with the count from `minShown` on. It only shows the streak; it gives
-- no extra points or coins.

return {
	-- Seconds after the last piece until the combo is over.
	windowSeconds = 3,
	-- The combo is shown from this count on.
	minShown = 3,
	-- Every this many pieces the display does a bigger pop.
	milestoneEvery = 10,
}
