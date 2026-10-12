--!strict
-- The autofarm: a free button that makes the dino collect food by itself. The server decides
-- whether it is on; the client walks. Starting values, to be balanced (studs and seconds).

return {
	-- Seconds between two choices of the target.
	tickSeconds = 0.2,
	-- A bigger player that could eat the dino is a danger inside its eating reach plus this much.
	dangerMargin = 25,
	-- How far the dino runs away from a danger.
	fleeDistance = 40,
	-- A piece of food scores value / (distance + valueBias): big pieces are worth a detour.
	valueBias = 10,
	-- Distance to the walls that the dino stays away from when it flees.
	arenaMargin = 6,
	-- Seconds the autofarm runs after it was switched on; then the player has to tap again.
	maxSessionSeconds = 600,
	-- The player takes over when the move input is stronger than this (0 to 1).
	manualInputThreshold = 0.2,
}
