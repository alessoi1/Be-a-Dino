--!strict
-- The global leaderboards on the boards in the lobby. Each list lives in its own sorted
-- DataStore (OrderedDataStore); the profile stays the source of the numbers. Starting values.

export type Category = {
	-- Short id, also used in GlobalBoard.valueFor ("kills", "size", "time").
	id: string,
	-- Name of the OrderedDataStore.
	storeName: string,
}

local categories: { Category } = {
	{ id = "kills", storeName = "BeDinoBoardKills" },
	{ id = "size", storeName = "BeDinoBoardSize" },
	{ id = "time", storeName = "BeDinoBoardTime" },
}

return {
	categories = categories,
	-- Entries shown on each board.
	rows = 10,
	-- Seconds between two writes of a player (and between two reads of a list).
	writeSeconds = 120,
	readSeconds = 120,
	-- Seconds between the writes of two players, so they do not all hit the DataStore at once.
	writeSpacingSeconds = 0.2,
	-- In Studio this is added to the store names, so tests do not write into the real lists.
	studioSuffix = "_Studio",
	-- The statistics (kills, seconds in the arena) are counted once per tick; a longer step of the
	-- server counts as at most this many seconds.
	statsTickSeconds = 1,
	statsMaxStepSeconds = 5,
	-- Largest number written (kills, size, seconds).
	maxValue = 1000000000000000,
	-- The boards at the south edge of the lobby, facing the window (studs). `centers` are the x positions.
	board = {
		width = 28,
		height = 18,
		centers = { -35, 0, 35 },
		-- Distance from the platform edge, and height of the middle above the lobby floor.
		inset = 4,
		middleHeight = 11,
	},
}
