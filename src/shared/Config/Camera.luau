--!strict
-- Camera values, to be balanced. The camera distance grows with the dino scale.

return {
	-- Studs of camera distance per unit of dino scale, never below minDistance.
	distancePerScale = 12,
	minDistance = 10,
	-- How fast the distance follows its target (per second).
	smoothing = 5,
}
