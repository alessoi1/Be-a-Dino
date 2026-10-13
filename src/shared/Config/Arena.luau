--!strict
-- Starting values for the arena, to be balanced. All game values live in Config/;
-- no magic numbers in the code. Sizes are in studs.

return {
	-- Radius of the round arena floor under the glass dome (600 studs across).
	radius = 300,
	-- The wall is a ring of this many straight pieces (the more, the rounder).
	wallSegments = 64,
	-- The viewing window towards the lobby: this many wall pieces in a row are glass (an even
	-- number), centered on this direction (0 = +X, 90 = +Z, where the lobby stands).
	windowSegments = 4,
	windowAngleDegrees = 90,
	-- How see-through the window glass is (0 = clear, 1 = invisible).
	windowTransparency = 0.45,
	-- Walls around the arena (studs).
	wallHeight = 20,
	wallThickness = 4,
	-- Distance to the walls in which nobody spawns (studs).
	spawnMargin = 10,
	-- Eating another player needs this much more size than the victim (1.2 = 20 % more).
	eatRatio = 1.2,
	-- Eating needs the bodies to touch: the distance between the two middles may be at most the sum
	-- of the two scales times this (studs). A dino is about 9 studs long at scale 1, so two dinos of
	-- scale 1 reach each other from 4.4 studs; the old 1.5 times the eater's scale (1.5 studs) meant a
	-- dino could run right through another one without eating it.
	eatReachFactor = 2.2,
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
