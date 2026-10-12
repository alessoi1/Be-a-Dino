--!strict
-- The window that opens after a player was eaten.

return {
	-- Seconds the player can choose (back to lobby, later also revive and bounty).
	offerSeconds = 15,
	-- A revive waits at most this many seconds for the new character, then it is not possible and
	-- the saved revive stays. After the character is there it waits a moment for the lobby spawn.
	reviveWaitSeconds = 8,
	reviveSettleSeconds = 0.5,
}
