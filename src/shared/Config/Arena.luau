--!strict
-- Starting values for the arena, to be balanced. All game values live in Config/;
-- no magic numbers in the code. Sizes are in studs.

return {
	-- Side length of the square arena floor.
	size = 400,
	-- Walls around the arena (studs).
	wallHeight = 20,
	wallThickness = 4,
	-- Distance to the walls in which nobody spawns (studs).
	spawnMargin = 10,
	-- Eating another player needs this much more size than the victim (1.2 = 20 % more).
	eatRatio = 1.2,
	-- Maximum eating distance in studs per unit of the eater's scale.
	eatDistanceFactor = 1.5,
	-- Share of the victim's points the eater receives (0.5 = half).
	eatPointsShare = 0.5,
	-- Seconds after a respawn in which a player cannot be eaten.
	spawnProtectionSeconds = 4,
	-- Seconds between being eaten and the respawn.
	respawnSeconds = 3,
	-- Random spots tried at a spawn; the one farthest from other players is used.
	spawnCandidates = 8,
	-- Seconds between two server checks for eating.
	eatCheckInterval = 0.1,
}
