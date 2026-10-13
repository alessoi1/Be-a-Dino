--!strict
-- Values for walking around obstacles (trees, rocks, logs). Starting values, to be balanced in
-- Studio. Sizes are in studs.

return {
	-- Half the width of a dino per unit of its scale: the room its body needs beside an obstacle.
	bodyRadiusPerScale = 1.5,
	-- Extra room kept beside an obstacle, so a dino does not scrape along it.
	margin = 1.5,
	-- How far ahead bots and the autofarm look for obstacles on their way.
	lookAhead = 36,
	-- How many obstacles in a row one steering step may walk around.
	maxDetours = 3,
	-- Shows the invisible collision shapes (Studio only, to check them by eye).
	showColliders = false,
}
