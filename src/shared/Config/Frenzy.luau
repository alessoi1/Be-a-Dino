--!strict
-- The food frenzy: a short event for the whole server that repeats. While it runs, the points from
-- food are multiplied. Only the points from food change (not eating players, not coins). To be
-- balanced with real players.

return {
	-- Seconds of calm between two frenzies, and how long a frenzy lasts.
	calmSeconds = 240,
	durationSeconds = 45,
	-- Seconds after the server start until the first calm period is over.
	firstCalmSeconds = 90,
	-- Points from food are multiplied by this while the frenzy runs.
	pointsFactor = 2,
}
