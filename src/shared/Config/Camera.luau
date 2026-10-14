--!strict
-- Camera values, to be balanced. The camera distance grows with the dino scale.

return {
	-- Studs of camera distance per unit of dino scale, never below minDistance.
	distancePerScale = 12,
	minDistance = 10,
	-- How fast the distance follows its target (per second).
	smoothing = 5,
	-- The view over the arena while the player waits in the death window: the camera hovers
	-- `deathHeight` studs above the middle of the arena, `deathRadius` studs to the side, looks at
	-- the middle of the floor and circles slowly (`deathTurnSpeed` radians per second).
	deathHeight = 230,
	deathRadius = 110,
	deathTurnSpeed = 0.08,
	-- Seconds the camera takes to fly from the dino to the view (and back after the window).
	deathBlendSeconds = 1.2,
}
