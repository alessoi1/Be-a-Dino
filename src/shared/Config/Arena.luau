--!strict
-- Starting values for the arena, to be balanced. All game values live in Config/;
-- no magic numbers in the code. Sizes are in studs.

return {
	-- Side length of the square arena floor.
	size = 400,
	-- Food: how many pieces exist at most, how much one piece is worth (growth points),
	-- seconds until an eaten piece comes back.
	foodCount = 300,
	foodValue = 1,
	foodRespawnSeconds = 8,
	-- Eating another player needs this much more size than the victim (1.2 = 20 % more).
	eatRatio = 1.2,
	-- Maximum eating distance in studs per unit of the eater's scale.
	eatDistanceFactor = 1.5,
	-- Share of the victim's points the eater receives (0.5 = half).
	eatPointsShare = 0.5,
	-- Seconds after a respawn in which a player cannot be eaten.
	spawnProtectionSeconds = 4,
}
