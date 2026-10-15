--!strict
-- How the dinos move their limbs while they walk (see DinoAnim). Placeholder values, to be
-- balanced by eye. Angles are in radians, distances in studs at dino scale 1.

return {
	-- Distance a dino travels during one full step cycle (both legs). Larger means slower steps.
	strideLength = 8,
	-- Most step cycles per second. Faster running (sprint) takes longer strides instead of quicker
	-- steps; limbs that swing faster than this look blurred and doubled on screen.
	maxCyclesPerSecond = 3.2,
	-- At this speed (studs per second) the limbs swing as far as they go; slower swings less.
	fullSpeed = 22,
	-- Below this speed the dino counts as standing still.
	standSpeed = 0.5,
	-- How far a leg swings forward and back (two-legged dinos), and for the four-legged ones.
	legSwing = 0.75,
	quadLegSwing = 0.5,
	-- How far the tail sways left and right while walking, and while standing.
	tailSwing = 0.3,
	tailIdleSwing = 0.12,
	-- Seconds per sway of the tail while standing.
	tailIdleSeconds = 2.4,
	-- Whole-body motion (the "body" joint at the middle of the figure). Lifts are in studs at scale 1,
	-- angles in radians. Standing: the body could rise and fall with the breath (same clock as the tail);
	-- 0 keeps it still, so a dino never sinks into the floor while it stands.
	breathLift = 0,
	-- Walking: the body bobs up and down twice per step cycle, and leans a little forward.
	bobLift = 0.08,
	walkLean = 0.03,
	-- Eating (the "munch"): the dino nods down and dips, over `eatSeconds`. Only a piece eaten within
	-- `eatReach` studs per unit of scale of the dino starts it.
	eatPitch = 0.35,
	eatDip = 0.15,
	eatSeconds = 0.35,
	eatReach = 6,
	-- The limbs of dinos that are further away from the camera than this are not animated (studs).
	maxDistance = 140,
	-- Dinos closer than this are updated in every frame (smooth), the ones between this and
	-- maxDistance every updateInterval seconds (cheaper).
	nearDistance = 70,
	updateInterval = 1 / 20,
	-- Seconds between two searches for new dinos.
	searchInterval = 0.5,
}
