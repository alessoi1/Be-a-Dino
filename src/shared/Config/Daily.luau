--!strict
-- The daily reward: one gift per day, with a streak. Coins for day 1 to 7 of the streak; after
-- day 7 the streak starts again at day 1 (the streak itself keeps counting). Missing a whole
-- day sets the streak back to day 1. Coins are earned by playing, never bought with Robux.

return {
	-- Coins for streak day 1 to 7 (the last day is the big one).
	rewards = { 50, 75, 100, 150, 200, 300, 600 },
	-- Seconds in a day. Days are counted in UTC from the server time (os.time).
	secondsPerDay = 86400,
}
