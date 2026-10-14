--!strict
-- The daily quests: every day three quests from this pool are active (the same for all players,
-- chosen by the day number). Each gives coins when its goal is reached and claimed. `kind` says
-- what counts: "food" pieces eaten, "kill" players eaten, "grow" dino stages gained, "combo" the
-- best eating combo of the day, "play" seconds in the arena. Coins are earned by playing, never
-- bought with Robux. Values to be balanced with real players.

export type Quest = { id: string, kind: string, target: number, coins: number }

local pool: { Quest } = {
	{ id = "food_60", kind = "food", target = 60, coins = 60 },
	{ id = "kill_3", kind = "kill", target = 3, coins = 120 },
	{ id = "grow_2", kind = "grow", target = 2, coins = 90 },
	{ id = "combo_10", kind = "combo", target = 10, coins = 80 },
	{ id = "play_600", kind = "play", target = 600, coins = 100 },
	{ id = "food_200", kind = "food", target = 200, coins = 150 },
	{ id = "kill_1", kind = "kill", target = 1, coins = 50 },
	{ id = "combo_25", kind = "combo", target = 25, coins = 160 },
	{ id = "grow_4", kind = "grow", target = 4, coins = 200 },
}

return {
	pool = pool,
	-- How many quests are active per day.
	perDay = 3,
	-- Seconds in a day. Days are counted in UTC from the server time (os.time), like the daily gift.
	secondsPerDay = 86400,
}
