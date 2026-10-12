--!strict
-- Bot values, to be balanced. Bots fill the arena while few real players are in it and leave
-- one by one as players enter. Sizes are in studs.

return {
	-- The arena is filled up to this many dinos (bots plus players in the arena). Every player who
	-- enters takes the place of one bot.
	fillTo = 8,
	-- Bots start as one of the first dinos (up to this stage) and never grow past `maxStageIndex`.
	startStageMax = 3,
	maxStageIndex = 6,
	-- Bots walk slower than a player of the same stage, so a player can run away from them.
	speedFactor = 0.85,
	-- Seconds between two thoughts of a bot (new goal, food pickup).
	thinkInterval = 0.25,
	-- Seconds between two checks of the number of bots.
	reconcileInterval = 1,
	-- Seconds between being eaten and coming back, and the protection after coming back.
	respawnSeconds = 5,
	protectionSeconds = 4,
	-- A bot runs from a dino that can eat it within `fleeRange`, hunts one it can eat within
	-- `huntRange` and looks for food within `foodRange` (studs).
	fleeRange = 45,
	huntRange = 35,
	foodRange = 60,
	-- How far one step of fleeing or wandering goes (studs).
	fleeStep = 40,
	wanderStep = 80,
	-- A food piece is worth value / (distance + foodDistanceBias) to a bot.
	foodDistanceBias = 5,
	-- Distance to the walls that bots keep (studs).
	wallMargin = 12,
	-- Seconds a wander goal is kept before a new one is chosen.
	wanderSeconds = 4,
	-- Height of the bot root above the floor when it spawns (it drops to the floor).
	hipHeight = 2,
}
