--!strict
-- The bounty: a player who was eaten can put a bounty on the one who ate them (paid with Robux,
-- added in the paid step). Whoever then eats the marked player gets `multiplier` times the usual
-- coins for eating. A target has at most one bounty; placing it again renews the time.

return {
	-- Coins for eating a marked player are multiplied by this.
	multiplier = 3,
	-- Seconds a bounty lasts.
	durationSeconds = 120,
}
