--!strict
-- How the dinos move their limbs while they walk (see DinoAnim). Placeholder values, to be
-- balanced by eye. Angles are in radians, distances in studs at dino scale 1.

return {
	-- Distance a dino travels during one full step cycle (both legs). Larger means slower steps.
	strideLength = 4.5,
	-- At this speed (studs per second) the limbs swing as far as they go; slower swings less.
	fullSpeed = 22,
	-- Below this speed the dino counts as standing still.
	standSpeed = 0.5,
	-- How far a leg swings forward and back.
	legSwing = 0.75,
	-- How far the tail sways left and right while walking, and while standing.
	tailSwing = 0.3,
	tailIdleSwing = 0.12,
	-- Seconds per sway of the tail while standing.
	tailIdleSeconds = 2.4,
	-- The limbs of dinos that are further away from the camera than this are not animated (studs).
	maxDistance = 140,
	-- Seconds between two updates of the limbs, and between two searches for new dinos.
	updateInterval = 1 / 30,
	searchInterval = 0.5,
}
