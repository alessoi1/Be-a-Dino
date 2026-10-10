--!strict
-- Movement and sprint values, to be balanced. Speeds per dino are in Config/Dinos.

return {
	-- Sprint multiplies the dino speed.
	sprintFactor = 1.5,
	-- Stamina: maximum, drain while sprinting and regrowth per second,
	-- seconds without sprinting before regrowth starts, minimum needed to start a sprint.
	staminaMax = 100,
	staminaDrainPerSecond = 25,
	staminaRegenPerSecond = 15,
	staminaRegenDelay = 1,
	staminaMinToStart = 10,
	-- Server check: accepted distance = speed * seconds * speedTolerance + moveSlack (studs).
	speedTolerance = 1.5,
	moveSlack = 2,
	-- Seconds between two server movement ticks.
	checkInterval = 0.1,
	-- Minimum seconds between two accepted Sprint remote calls per player.
	sprintRemoteMinInterval = 0.1,
	-- A rejected remote reason is logged at most once per this many seconds and player.
	rejectLogIntervalSeconds = 5,
}
